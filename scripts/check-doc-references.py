#!/usr/bin/env python3
"""Check documentation for dangling repo-relative references.

Catches the mechanical, reproducible slice of "doc drift": a doc that names a
file / path / internal link which no longer exists in the repo. It does NOT
judge prose ("is this model still current?") — that semantic tail is left to a
periodic LLM sweep. See .claude/rules and docs/adrs for the split.

Precision-first by design: a gate that cries wolf gets bypassed, so v1 flags
only two high-confidence shapes and deliberately under-reaches:

1. Relative markdown links `[text](path)` whose target does not resolve from the
   linking file's directory (skips http(s)/mailto, in-page #anchors, and
   template/placeholder targets).
2. Inline-code path tokens `` `like/this.sh` `` that are **anchored to a real
   top-level repo entry** (first path segment is an actual tracked top-level
   file/dir) and do not resolve from the repo root.

Deliberately OUT of v1 scope (handled by the periodic LLM sweep instead):
- bare filenames with no slash (`update-ai-tools.sh`) — too many prose examples;
- chezmoi *rendered* target names (`./cleanup-mcp-servers.sh` <- executable_…tmpl);
- slash commands (`/configure:mcp`), domains, `~/` runtime paths, placeholders.

Fenced code blocks (``` / ~~~) are skipped entirely: they hold examples.

Structured KEY=VALUE / STATUS= output. Exit code:
- default (advisory): always 0 — the STATUS line is the signal.
- `--strict`: exit 1 when any dangling reference is found (CI / mise task).

Allowlist: `.doc-reference-allow` at the repo root, one glob per line
(`#` comments ok). Matching docs are skipped — for immutable records (ADRs)
that intentionally reference now-dead paths.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from fnmatch import fnmatch
from pathlib import Path

# chezmoi source-name attribute prefixes / suffix. A doc that references a
# managed file by its *rendered* name (e.g. hooks/foo.sh) must still resolve
# against its source form (hooks/executable_foo.sh, dot_foo -> .foo, …).
CHEZMOI_PREFIXES = (
    "encrypted_", "private_", "readonly_", "empty_", "executable_", "exact_",
    "literal_", "symlink_", "run_once_", "run_onchange_", "run_", "create_",
    "modify_", "before_", "after_", "once_", "onchange_",
)

MD_LINK = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
INLINE_CODE = re.compile(r"`([^`]+)`")
PATH_TOKEN = re.compile(r"^[\w./~-]+$")               # no spaces / shell metachars
PLACEHOLDER = re.compile(r"\.\.\.|NNNN|xxx|<|>|\{|\bfoo\b|\bbar\b|\bbaz\b|example")
SKIP_PREFIXES = ("http://", "https://", "mailto:", "#", "www.")
DOMAIN_HINTS = (".com/", ".org/", ".io/", ".dev/", ".net/", ".fi/", ".xyz/")


def _git(root: Path, *args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=root, capture_output=True, text=True, check=True,
    ).stdout


def repo_root() -> Path:
    return Path(_git(Path.cwd(), "rev-parse", "--show-toplevel").strip())


def load_allowlist(root: Path) -> list[str]:
    f = root / ".doc-reference-allow"
    if not f.exists():
        return []
    return [
        ln.strip() for ln in f.read_text().splitlines()
        if ln.strip() and not ln.strip().startswith("#")
    ]


def _rendered_name(src_name: str) -> str:
    """Map a chezmoi source basename to its rendered target basename."""
    name = src_name[:-5] if src_name.endswith(".tmpl") else src_name
    changed = True
    while changed:
        changed = False
        for p in CHEZMOI_PREFIXES:
            if name.startswith(p):
                name, changed = name[len(p):], True
        if name.startswith("dot_"):
            name, changed = "." + name[4:], True
    return name


def managed_exists(root: Path, rel: str) -> bool:
    """True if `rel` exists literally, or as a chezmoi source of that target."""
    p = root / rel
    if p.exists():
        return True
    parent, base = p.parent, p.name
    if not parent.is_dir():
        return False
    return any(_rendered_name(entry.name) == base for entry in parent.iterdir())


def strip_fenced_blocks(text: str) -> list[tuple[int, str]]:
    """(1-indexed lineno, line) for lines OUTSIDE fenced code blocks."""
    kept, fence = [], None
    for i, line in enumerate(text.splitlines(), start=1):
        stripped = line.lstrip()
        marker = "```" if stripped.startswith("```") else "~~~" if stripped.startswith("~~~") else None
        if marker:
            fence = None if fence == marker else (fence or marker)
            continue
        if fence is None:
            kept.append((i, line))
    return kept


def clean_link_target(target: str) -> str | None:
    target = target.strip()
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1]
    target = target.split()[0] if target else target       # drop link title
    if not target or target.lower().startswith(SKIP_PREFIXES):
        return None
    if "{{" in target or "$" in target:                    # templating
        return None
    target = target.split("#", 1)[0].split("?", 1)[0]      # drop anchor/query
    return target or None


def link_resolves(target: str, doc_path: Path, root: Path) -> bool:
    base = root if target.startswith("/") else doc_path.parent
    candidate = base / target.lstrip("/") if target.startswith("/") else base / target
    try:
        rel = candidate.resolve().relative_to(root)
    except (OSError, RuntimeError, ValueError):
        return candidate.exists()
    return managed_exists(root, str(rel))


def token_is_candidate(tok: str) -> bool:
    if not PATH_TOKEN.match(tok) or tok.startswith(("/", "~/")):
        return False
    if tok.lower().startswith(SKIP_PREFIXES) or PLACEHOLDER.search(tok):
        return False
    if any(d in tok for d in DOMAIN_HINTS):
        return False
    return "/" in tok                                       # a path (incl. ./name)


def token_resolves(tok: str, root: Path, top_level: set[str]) -> bool:
    had_dot = tok.startswith("./")
    t = tok[2:] if had_dot else tok
    if "/" not in t:
        # single segment: only an explicit `./name` invocation names a repo-root
        # file; a bare filename without `./` is out of v1 scope (prose examples).
        return managed_exists(root, t) if had_dot else True
    if t.split("/", 1)[0] not in top_level:   # not anchored to a real repo entry
        return True
    return managed_exists(root, t.rstrip("/"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--strict", action="store_true",
                    help="exit 1 when dangling references are found")
    ap.add_argument("files", nargs="*",
                    help="markdown files to check (default: all tracked *.md)")
    args = ap.parse_args()

    root = repo_root()
    allow = load_allowlist(root)
    tracked = [ln for ln in _git(root, "ls-files").splitlines() if ln]
    top_level = {p.split("/", 1)[0] for p in tracked}

    if args.files:
        md_files = [os.path.relpath(os.path.abspath(f), root)
                    for f in args.files if f.endswith(".md")]
    else:
        md_files = [f for f in tracked if f.endswith(".md")]

    findings: list[tuple[str, int, str, str]] = []
    checked = 0
    for rel in sorted(md_files):
        if any(fnmatch(rel, pat) for pat in allow):
            continue
        doc = root / rel
        if not doc.exists():
            continue
        checked += 1
        for lineno, line in strip_fenced_blocks(
            doc.read_text(encoding="utf-8", errors="replace")
        ):
            for m in MD_LINK.finditer(line):
                target = clean_link_target(m.group(1))
                if not target or target.lower().startswith(SKIP_PREFIXES):
                    continue
                if "/" not in target and "." not in target:   # not a filesystem path
                    continue
                if PLACEHOLDER.search(target):
                    continue
                if not link_resolves(target, doc, root):
                    findings.append((rel, lineno, "link", target))
            for m in INLINE_CODE.finditer(line):
                tok = m.group(1)
                if token_is_candidate(tok) and not token_resolves(tok, root, top_level):
                    findings.append((rel, lineno, "ref", tok))

    print("=== DOC REFERENCE CHECK ===")
    print(f"DOCS_CHECKED={checked}")
    print(f"ALLOWLISTED_PATTERNS={len(allow)}")
    print(f"DANGLING_COUNT={len(findings)}")
    print(f"STATUS={'FAIL' if findings else 'OK'}")
    for rel, lineno, kind, tok in findings:
        print(f"DANGLING {rel}:{lineno} [{kind}] {tok}")
    print("=== END DOC REFERENCE CHECK ===")

    return 1 if (findings and args.strict) else 0


if __name__ == "__main__":
    sys.exit(main())
