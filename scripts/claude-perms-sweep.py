#!/usr/bin/env python3
"""Sweep permission allow-rules into every repo's committed .claude/settings.json.

Committed project settings are the ONLY place permission rules reach Claude Code
web/remote sessions -- ~/.claude is unreachable there (see the global rules
claude-code-auto-mode.md and claude-plugins-freshness.md). Keeping a rule in the
chezmoi overlay alone therefore covers local sessions and nothing else.

Everything goes through the GitHub API rather than local checkouts: a portfolio
sweep routinely meets dirty working trees and repos parked on feature branches,
and the API both leaves those untouched and reads the *true* remote state
instead of a possibly-drifted local file.

  claude-perms-sweep.py <scope> --rules A,B,C [--apply] [--pr]

  scope        laurigates | fvh | all  (or an explicit owner/name list)
  --rules      comma-separated bare tool names or rule strings to ensure present
  --apply      actually write; default is a dry-run plan
  --pr         also open a PR per repo (implies --apply)

Repos with no committed .claude/settings.json are reported and skipped -- this
never creates the file, because an absent project config is a deliberate state
(the repo may not use Claude Code at all).
"""

import argparse
import base64
import json
import re
import subprocess
import sys

ORGS = {"laurigates": "laurigates", "fvh": "ForumViriumHelsinki"}
PATH = ".claude/settings.json"
BRANCH = "chore/claude-perms-sweep"


def gh(*args, check=True):
    p = subprocess.run(("gh",) + args, capture_output=True, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(p.stderr.strip()[:300] or "gh failed")
    return p.stdout.strip()


def repos_for(scope):
    owners = list(ORGS.values()) if scope == "all" else [ORGS[scope]]
    out = []
    for o in owners:
        raw = gh(
            "repo",
            "list",
            o,
            "--limit",
            "300",
            "--no-archived",
            "--json",
            "nameWithOwner",
            "--jq",
            ".[].nameWithOwner",
        )
        out += [r for r in raw.splitlines() if r]
    return sorted(out)


def fetch(slug, ref):
    p = subprocess.run(
        ("gh", "api", f"repos/{slug}/contents/{PATH}?ref={ref}"),
        capture_output=True,
        text=True,
    )
    if p.returncode != 0:
        return None, None
    d = json.loads(p.stdout)
    return base64.b64decode(d["content"]).decode(), d["sha"]


def transform(text, rules):
    """Insert any missing rules. Returns (new_text, mode); new_text None if a no-op.

    Surgical string insertion, NOT a json.load/dump round-trip: a reformat would
    bury the real change in a whole-file diff and fight whatever style the repo
    already uses.
    """
    missing = [r for r in rules if not re.search(r'"%s"' % re.escape(r), text)]
    if not missing:
        return None, "already-present"

    m = re.search(r'("allow"\s*:\s*\[)(\s*\n)?', text)
    if m:
        first = text[m.end() :].split("\n")[0] if m.group(2) else ""
        im = re.match(r"[ \t]*", first)
        indent = im.group(0) if (m.group(2) and im.group(0)) else "      "
        block = "".join(f'\n{indent}"{r}",' for r in missing)
        # Insert right after '[' so the closing bracket and the existing last
        # element's trailing-comma state are never touched.
        return text[: m.end(1)] + block + text[m.end(1) :], "append-to-allow"

    # settings.json exists but has no permissions.allow: add the block after the
    # opening brace, or after a leading "$schema" so the pointer stays first.
    m = re.match(r'(\s*\{\s*\n[ \t]*"\$schema"[^\n]*\n)', text) or re.match(
        r"(\s*\{\s*\n)", text
    )
    if not m:
        raise RuntimeError("unrecognised JSON shape")
    entries = ",\n".join(f'      "{r}"' for r in rules)
    block = f'  "permissions": {{\n    "allow": [\n{entries}\n    ]\n  }},\n'
    return text[: m.end(1)] + block + text[m.end(1) :], "create-permissions"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("scope")
    ap.add_argument("--rules", required=True)
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--pr", action="store_true")
    ap.add_argument(
        "--title", default="chore(claude): sweep Claude Code permission allow-rules"
    )
    ap.add_argument("--body-file")
    a = ap.parse_args()

    rules = [r.strip() for r in a.rules.split(",") if r.strip()]
    write = a.apply or a.pr
    slugs = (
        repos_for(a.scope)
        if a.scope in ORGS or a.scope == "all"
        else [s.strip() for s in a.scope.split(",")]
    )

    changed = skipped = failed = 0
    for slug in slugs:
        name = slug.split("/")[-1]
        try:
            default = gh("api", f"repos/{slug}", "--jq", ".default_branch")
            text, sha = fetch(slug, default)
            if text is None:
                print(f"{name:34} skip        no committed {PATH}")
                skipped += 1
                continue
            new, how = transform(text, rules)
            if new is None:
                print(f"{name:34} skip        all rules already present")
                skipped += 1
                continue
            json.loads(new)  # hard gate: never write invalid JSON
            if not write:
                print(f"{name:34} {how:20} would patch on {default}")
                changed += 1
                continue

            head = gh(
                "api", f"repos/{slug}/git/ref/heads/{default}", "--jq", ".object.sha"
            )
            subprocess.run(
                (
                    "gh",
                    "api",
                    "-X",
                    "POST",
                    f"repos/{slug}/git/refs",
                    "-f",
                    f"ref=refs/heads/{BRANCH}",
                    "-f",
                    f"sha={head}",
                ),
                capture_output=True,
                text=True,
            )
            gh(
                "api",
                "-X",
                "PUT",
                f"repos/{slug}/contents/{PATH}",
                "-f",
                f"message={a.title}",
                "-f",
                f"content={base64.b64encode(new.encode()).decode()}",
                "-f",
                f"sha={sha}",
                "-f",
                f"branch={BRANCH}",
            )
            note = f"committed to {BRANCH}"
            if a.pr:
                cmd = [
                    "pr",
                    "create",
                    "--repo",
                    slug,
                    "--head",
                    BRANCH,
                    "--title",
                    a.title,
                ]
                cmd += (
                    ["--body-file", a.body_file] if a.body_file else ["--body", a.title]
                )
                note = gh(*cmd).splitlines()[-1]
            print(f"{name:34} {how:20} {note}")
            changed += 1
        except Exception as e:
            print(f"{name:34} ERROR       {e}")
            failed += 1

    print(
        f"\nCHANGED={changed} SKIPPED={skipped} FAILED={failed} "
        f"MODE={'apply' if write else 'dry-run'}"
    )
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
