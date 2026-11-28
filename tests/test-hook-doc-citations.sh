#!/usr/bin/env bash
# Regression test: a Claude hook that cites a doc section names a file and a
# heading that both exist in this repo (#595).
#
# What is being protected
# ------------------------
# The chezmoi guard hooks tell the reader where the rationale lives, as
#   <path>.md ("<heading>")
# with <path> repo-relative, optionally prefixed by ~/.local/share/chezmoi/.
# When a rule was split into .claude/rules/ + docs/, three hooks kept citing
# .claude/rules/chezmoi-conventions.md for headings that had moved to
# docs/chezmoi-apply-hazards.md, so a blocked user searched a file that did not
# contain the section.
#
# How
# ---
# For every file in exact_dot_claude/hooks/, strip comment markers, join the
# lines, and find each `<path>.md ... ("<heading>")` citation (up to 40
# characters of prose may sit between the path and the parenthesis). The path
# must exist in the repo, and some Markdown heading in it must start with the
# cited text (backticks ignored).
#
# Controls: the hooks listed in MUST_CITE must each carry at least one
# citation, so a reworded hook cannot silently drop out of the check; and a
# scratch hooks dir citing a missing heading and a missing file must fail.
#
# Usage: tests/test-hook-doc-citations.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'

MUST_CITE="executable_chezmoi-exact-guard.sh executable_chezmoi-drift-guard.sh executable_chezmoi-target-guard.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

cat >"$WORK/check.py" <<'PY'
import re
import sys
from pathlib import Path

repo, hooks_dir, must_cite = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3].split()
CITE = re.compile(r'(?P<path>[\w./~-]+\.md)[^"()]{0,40}\("(?P<heading>[^"]+)"\)')
PREFIX = "~/.local/share/chezmoi/"


def norm(text):
    return " ".join(text.replace("`", "").split())


def headings(path):
    return [norm(line.lstrip("#")) for line in path.read_text().splitlines()
            if re.match(r"#{1,6} ", line)]


failures, count, cited_by = [], 0, set()
for hook in sorted(p for p in hooks_dir.iterdir() if p.is_file()):
    lines = [re.sub(r"^\s*#+\s?", "", l) for l in hook.read_text().splitlines()]
    for m in CITE.finditer(" ".join(" ".join(lines).split())):
        count += 1
        cited_by.add(hook.name)
        rel = m["path"].removeprefix(PREFIX)
        target = repo / rel
        want = norm(m["heading"])
        if not target.is_file():
            failures.append(f"{hook.name}: cites {rel}, which is not a file in the repo")
        elif not any(h.startswith(want) for h in headings(target)):
            failures.append(f'{hook.name}: {rel} has no heading starting "{want}"')
        else:
            print(f'ok   {hook.name}: {rel} ("{want}")')

for name in must_cite:
    if name not in cited_by:
        failures.append(f"{name}: carries no <path>.md (\"<heading>\") citation")

for f in failures:
    print(f"FAIL {f}")
print(f"CITATIONS={count}")
sys.exit(1 if failures else 0)
PY

pass=0; fail=0
ok()  { echo "${GREEN}PASS${NC} $1"; pass=$((pass + 1)); }
bad() { echo "${RED}FAIL${NC} $1"; fail=$((fail + 1)); }

# 1. The live hooks.
if out="$(python3 "$WORK/check.py" "$REPO_DIR" "$REPO_DIR/exact_dot_claude/hooks" "$MUST_CITE")"; then
    echo "$out"; ok "every hook doc citation resolves to an existing file and heading"
else
    echo "$out"; bad "a hook cites a file or heading that does not exist"
fi

# 2. Control: planted bad citations must be reported, by file and by heading.
mkdir -p "$WORK/repo/docs" "$WORK/hooks"
printf '# Doc\n\n## Real Heading\n' >"$WORK/repo/docs/x.md"
cat >"$WORK/hooks/executable_planted.sh" <<'SH'
#!/usr/bin/env bash
# See ~/.local/share/chezmoi/docs/x.md ("Real Heading") for the good one,
# docs/x.md ("Gone Heading") for a moved section, and
# docs/missing.md ("Real Heading") for a moved file.
SH
if out="$(python3 "$WORK/check.py" "$WORK/repo" "$WORK/hooks" "executable_planted.sh")"; then
    echo "$out"; bad "control: planted bad citations passed"
elif grep -q 'no heading starting "Gone Heading"' <<<"$out" \
    && grep -q 'cites docs/missing.md, which is not a file' <<<"$out" \
    && grep -q '^ok   executable_planted.sh: docs/x.md ("Real Heading")' <<<"$out"; then
    ok "control: a missing heading and a missing file are reported, a valid citation is not"
else
    echo "$out"; bad "control: checker output did not name the planted citations"
fi

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
