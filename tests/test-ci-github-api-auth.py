#!/usr/bin/env python3
"""Regression check: CI jobs that call the GitHub REST API carry a credential
the calling tool actually reads.

Root cause (#434): StyLua's `stylua-github` pre-commit hook is built by
release-gitter, which lists GitHub releases with a bare `requests.get` and
reads no token variable. The only credential it can pick up is requests' own
netrc lookup ($NETRC, else ~/.netrc). Without one, every hook install is an
anonymous call against the runner IP's 60/h limit, and hosted runners share
IPs. Exporting GITHUB_TOKEN does nothing for it.

The class pinned here: a workflow job runs a tool that calls api.github.com,
and nothing earlier in the job hands that tool a credential it reads. Each tool
reads a different one, so each rule names its own:

  R1  pre-commit (`pre-commit run|install|install-hooks|try-repo|autoupdate`,
      `uses: pre-commit/action`, or installing pre-commit with pip, pipx, uv or
      brew) needs NETRC, set in workflow/job/step env or exported to
      $GITHUB_ENV by an earlier step. Installing counts because an installed
      pre-commit is there to be run, sometimes by an agent step whose commands
      are not in the YAML (claude.yml).
  R2  mise needs an earlier jdx/mise-action step (it exports MISE_GITHUB_TOKEN)
      or MISE_GITHUB_TOKEN / GITHUB_API_TOKEN / GITHUB_TOKEN in env.
  R3  curl or wget against api.github.com needs auth on the same command:
      -u/--user, -n/--netrc/--netrc-file, or an Authorization header.

Run steps are scanned together with any repo shell script they invoke, so a
helper such as .github/scripts/github-api-netrc.sh counts as the auth step.

Not covered: jobs that call a reusable workflow (`jobs.<id>.uses`, whose steps
live in another repo), tools that fetch through urllib or read a token variable
of their own, and brew. The api.github.com calls in brew's auto-update
(Library/Homebrew/cmd/update.sh) run `--silent --max-time 3` and fall through
on failure, they read HOMEBREW_GITHUB_API_TOKEN, and setup-homebrew exports
that on the Linux jobs.

A self-test over inline fixture workflows runs before every scan, so a parser
that silently matches nothing cannot report PASS.

Usage:
  tests/test-ci-github-api-auth.py              # self-test, then scan the repo
  tests/test-ci-github-api-auth.py --self-test  # self-test only
  tests/test-ci-github-api-auth.py --root DIR   # scan another checkout
Output: FAIL/PASS lines, then STATUS=PASS|FAIL. Exit 1 on any failure.
"""

from __future__ import annotations

import argparse
import re
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

import yaml

# A word in command position: line start, after a shell operator, or after a
# keyword that introduces a command. Keeps `echo "### mise Doctor"` and
# `# pre-commit run` from matching.
CMD = r"(?:^|[;&|(`!]|\b(?:then|do|else|elif|if|while|until|exec|sudo|time|xargs|command)\b)[ \t]*"

PRE_COMMIT_RUN = re.compile(
    CMD + r"(?:pre-commit|python3?\s+-m\s+pre_commit)\s+"
    r"(?:run|install|install-hooks|try-repo|autoupdate)\b",
    re.M,
)
PRE_COMMIT_INSTALL = re.compile(
    CMD + r"(?:(?:python3?\s+-m\s+)?pip3?|pipx|uv\s+(?:tool|pip)|brew)\s+install\b"
    r"[^\n;&|]*?(?<![\w.-])pre-commit(?![\w-])",
    re.M,
)
MISE = re.compile(CMD + r"mise\s+[a-z]", re.M)
CURL_OR_WGET = re.compile(CMD + r"(?:curl|wget)\b")
HTTP_AUTH = re.compile(
    r"(?<![\w-])(?:--user|--netrc(?:-file|-optional)?|--http-user|--oauth2-bearer)\b"
    r"|(?<![\w-])-[A-Za-z]*[nu][A-Za-z]*(?![\w-])"
    r"|(?i:authorization)"
)
EXPORT = re.compile(r"\b([A-Z_][A-Z0-9_]*)=[^\n]*\bGITHUB_ENV\b")
SCRIPT_REF = re.compile(r"(?<![\w./$-])(?:\./)?((?:[\w.-]+/)*[\w.-]+\.(?:sh|bash))\b")

MISE_TOKENS = {"MISE_GITHUB_TOKEN", "GITHUB_API_TOKEN", "GITHUB_TOKEN"}
NETRC_HINT = "add an earlier step running .github/scripts/github-api-netrc.sh (see #434)"


@dataclass(frozen=True)
class Finding:
    rule: str
    where: str
    message: str


def env_names(env: object) -> set[str]:
    """Names of env entries with a non-empty value."""
    if not isinstance(env, dict):
        return set()
    return {str(k) for k, v in env.items() if v not in (None, "")}


def normalise(text: str) -> str:
    """Join backslash continuations and drop shell comments."""
    text = re.sub(r"\\\n[ \t]*", " ", text)
    lines = []
    for line in text.splitlines():
        if line.lstrip().startswith("#"):
            continue
        lines.append(re.sub(r"(?<=\s)#.*$", "", line))
    return "\n".join(lines)


def expand(run: str, root: Path) -> str:
    """A run step's text plus the text of repo shell scripts it invokes."""
    parts = [run]
    for ref in SCRIPT_REF.findall(run):
        path = (root / ref).resolve()
        if path.is_file() and path.is_relative_to(root.resolve()):
            parts.append(path.read_text(encoding="utf-8", errors="replace"))
    return normalise("\n".join(parts))


def action_name(uses: str) -> str:
    return uses.split("@", 1)[0].lower()


def provided_by_action(uses: str, with_: object) -> set[str]:
    """Env names an action exports to later steps via $GITHUB_ENV."""
    if action_name(uses) == "jdx/mise-action":
        token = with_.get("github_token") if isinstance(with_, dict) else None
        return set() if token == "" else {"MISE_GITHUB_TOKEN"}
    return set()


def check_job(label: str, wf_env: object, job: dict, root: Path) -> tuple[list[Finding], int]:
    """Findings for one job, plus how many GitHub-API consumers it contains."""
    findings: list[Finding] = []
    consumers = 0
    if "uses" in job:  # reusable workflow call: its steps are not in this repo
        return findings, consumers
    base = env_names(wf_env) | env_names(job.get("env"))
    exported: set[str] = set()
    for index, step in enumerate(job.get("steps") or [], start=1):
        if not isinstance(step, dict):
            continue
        where = f"{label} step {index} `{step.get('name') or step.get('uses') or 'run'}`"
        env = base | exported | env_names(step.get("env"))
        uses = str(step.get("uses") or "")
        text = expand(str(step["run"]), root) if "run" in step else ""

        if action_name(uses) == "pre-commit/action" or PRE_COMMIT_RUN.search(text) or PRE_COMMIT_INSTALL.search(text):
            consumers += 1
            if "NETRC" not in env:
                findings.append(Finding(
                    "R1", where,
                    "runs or installs pre-commit without NETRC; release-gitter "
                    "(StyLua stylua-github) reads only $NETRC or ~/.netrc, so hook "
                    f"installs call api.github.com anonymously. Fix: {NETRC_HINT}",
                ))
        if MISE.search(text):
            consumers += 1
            if not env & MISE_TOKENS:
                findings.append(Finding(
                    "R2", where,
                    "runs mise without a GitHub token; add jdx/mise-action@v4 earlier "
                    "in the job (it exports MISE_GITHUB_TOKEN) or set MISE_GITHUB_TOKEN",
                ))
        for line in text.splitlines():
            if CURL_OR_WGET.search(line) and "api.github.com" in line:
                consumers += 1
                if not HTTP_AUTH.search(line):
                    findings.append(Finding(
                        "R3", where,
                        "calls api.github.com with curl/wget and no credential; pass "
                        "--netrc-file \"$NETRC\" or an Authorization header",
                    ))

        exported |= set(EXPORT.findall(text)) | provided_by_action(uses, step.get("with"))
    return findings, consumers


def check_workflow(path: Path, root: Path) -> tuple[list[Finding], int, int]:
    doc = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    jobs = doc.get("jobs") or {}
    findings: list[Finding] = []
    consumers = 0
    for job_id, job in jobs.items():
        if not isinstance(job, dict):
            continue
        rel = path.relative_to(root) if path.is_relative_to(root) else path
        found, count = check_job(f"{rel} job `{job_id}`", doc.get("env"), job, root)
        findings += found
        consumers += count
    return findings, len(jobs), consumers


# --- self-test ---------------------------------------------------------------

NETRC_STEP = """\
      - run: |
          printf 'machine api.github.com login x-access-token password %s\\n' "$T" > "$RUNNER_TEMP/netrc"
          echo "NETRC=$RUNNER_TEMP/netrc" >> "$GITHUB_ENV"
"""

FIXTURES: list[tuple[str, str, list[str]]] = [
    ("pre-commit run, no NETRC", """
jobs:
  lint:
    steps:
      - run: pre-commit run --all-files
""", ["R1"]),
    ("pip install pre-commit, no NETRC", """
jobs:
  lint:
    steps:
      - run: |
          brew install chezmoi
          pip install pre-commit
""", ["R1"]),
    ("pre-commit/action, no NETRC", """
jobs:
  lint:
    steps:
      - uses: pre-commit/action@v3.0.1
""", ["R1"]),
    ("NETRC exported by an earlier step", """
jobs:
  lint:
    steps:
""" + NETRC_STEP + """
      - run: pip install pre-commit
      - run: pre-commit run --all-files
""", []),
    ("NETRC exported only after pre-commit runs", """
jobs:
  lint:
    steps:
      - run: pre-commit run --all-files
""" + NETRC_STEP, ["R1"]),
    ("NETRC in job env", """
jobs:
  lint:
    env:
      NETRC: /tmp/netrc
    steps:
      - run: pre-commit run --all-files
""", []),
    ("NETRC set to empty in step env", """
jobs:
  lint:
    steps:
      - run: pre-commit run --all-files
        env:
          NETRC: ''
""", ["R1"]),
    ("NETRC exported by an invoked repo script", """
jobs:
  lint:
    steps:
      - run: .github/scripts/netrc.sh
      - run: pre-commit run --all-files
""", []),
    ("unrelated script invoked", """
jobs:
  lint:
    steps:
      - run: .github/scripts/other.sh
      - run: pre-commit run --all-files
""", ["R1"]),
    ("pre-commit named only in a comment and an echo", """
jobs:
  lint:
    steps:
      - run: |
          # pre-commit run --all-files
          echo "then run pre-commit-hooks later"
          pip install pre-commit-hooks
""", []),
    ("mise install without mise-action", """
jobs:
  build:
    steps:
      - run: mise install
""", ["R2"]),
    ("mise after mise-action, echo mentions mise", """
jobs:
  build:
    steps:
      - uses: jdx/mise-action@v4
      - run: |
          echo "### mise Doctor"
          if mise doctor 2>&1 | tee mise.log; then echo ok; fi
""", []),
    ("mise-action with github_token emptied", """
jobs:
  build:
    steps:
      - uses: jdx/mise-action@v4
        with:
          github_token: ''
      - run: mise install
""", ["R2"]),
    ("anonymous curl to api.github.com", """
jobs:
  probe:
    steps:
      - run: curl -sSf https://api.github.com/repos/o/r/releases | jq .
""", ["R3"]),
    ("authenticated curl forms", """
jobs:
  probe:
    steps:
      - run: |
          curl -sSf --netrc-file "$NETRC" https://api.github.com/rate_limit
          curl -sSf -H "Authorization: Bearer $T" \\
            https://api.github.com/rate_limit
          curl -fsSLn https://api.github.com/rate_limit
""", []),
    ("reusable workflow call is skipped", """
jobs:
  fix:
    uses: o/r/.github/workflows/reusable.yml@main
""", []),
]


def self_test() -> list[str]:
    """Run every fixture; return a failure line per fixture that misbehaves."""
    failures: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        scripts = root / ".github" / "scripts"
        scripts.mkdir(parents=True)
        (scripts / "netrc.sh").write_text('#!/bin/sh\necho "NETRC=$RUNNER_TEMP/netrc" >> "$GITHUB_ENV"\n')
        (scripts / "other.sh").write_text('#!/bin/sh\necho "OTHER=1" >> "$GITHUB_ENV"\n')
        for name, text, expected in FIXTURES:
            path = root / "fixture.yml"
            path.write_text(text)
            findings, _, _ = check_workflow(path, root)
            got = sorted(f.rule for f in findings)
            if got != sorted(expected):
                failures.append(f"self-test `{name}`: expected {sorted(expected)}, got {got}")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--self-test", action="store_true", help="run only the fixture self-test")
    args = parser.parse_args()

    failures = self_test()
    for line in failures:
        print(f"FAIL {line}")
    if failures:
        print("STATUS=FAIL")
        return 1
    print(f"PASS self-test: {len(FIXTURES)} fixtures")
    if args.self_test:
        print("STATUS=PASS")
        return 0

    root = args.root.resolve()
    workflows = sorted((root / ".github" / "workflows").glob("*.y*ml"))
    findings: list[Finding] = []
    jobs = consumers = 0
    for path in workflows:
        found, job_count, consumer_count = check_workflow(path, root)
        findings += found
        jobs += job_count
        consumers += consumer_count
    print(f"WORKFLOWS={len(workflows)} JOBS={jobs} CONSUMERS={consumers}")
    if not workflows or not jobs:
        print(f"FAIL no workflow jobs parsed under {root}/.github/workflows")
        print("STATUS=FAIL")
        return 1
    for f in findings:
        print(f"FAIL {f.rule} {f.where}: {f.message}")
    if findings:
        print("STATUS=FAIL")
        return 1
    print("PASS every GitHub-API consumer in CI carries a credential its tool reads")
    print("STATUS=PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
