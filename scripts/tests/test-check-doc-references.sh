#!/usr/bin/env bash
# Regression test for scripts/check-doc-references.py.
#
# Pins the precision/recall contract: the gate must FLAG dead repo-relative
# references and broken links, and must NOT flag chezmoi-managed source names,
# slash commands, domains, placeholders, or valid links. Run from anywhere in
# the repo; uses a temp fixture that references REAL repo paths so the
# chezmoi-aware and top-level-anchor logic exercises the live tree.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
CHECK="$ROOT/scripts/check-doc-references.py"
FIX="$(mktemp -d)/fixture.md"
trap 'rm -rf "$(dirname "$FIX")"' EXIT

cat > "$FIX" <<'MD'
# Fixture

Dead root script: `./update-ai-tools.sh`
Dead full path: `exact_dot_claude/commands/CLAUDE.md`
Broken link: [gone](../does/not/exist.md)

Managed root script: `./cleanup-mcp-servers.sh`
Managed hook by rendered name: `exact_dot_claude/hooks/chezmoi-workflow-nudge.sh`
Slash command: `/configure:mcp`
Domain: `github.com/laurigates/dotfiles`
Placeholder: `docs/adrs/NNNN-title.md`
Live path: `scripts/check-doc-references.py`
MD

out="$(python3 "$CHECK" "$FIX")"
echo "$out"

fail=0
assert_flagged() {
  if ! grep -q "\[.*\] $1\$" <<<"$out"; then
    echo "FAIL: expected flagged but was not: $1"; fail=1
  fi
}
assert_clean() {
  if grep -q " $1\$" <<<"$out"; then
    echo "FAIL: expected NOT flagged but was: $1"; fail=1
  fi
}

assert_flagged "./update-ai-tools.sh"
assert_flagged "exact_dot_claude/commands/CLAUDE.md"
assert_flagged "../does/not/exist.md"

assert_clean "./cleanup-mcp-servers.sh"
assert_clean "exact_dot_claude/hooks/chezmoi-workflow-nudge.sh"
assert_clean "/configure:mcp"
assert_clean "github.com/laurigates/dotfiles"
assert_clean "docs/adrs/NNNN-title.md"
assert_clean "scripts/check-doc-references.py"

# And the live tree must be clean (STATUS=OK) — the fixes + allowlist hold.
tree_status="$(python3 "$CHECK" | grep '^STATUS=')"
if [ "$tree_status" != "STATUS=OK" ]; then
  echo "FAIL: live tree not clean: $tree_status"; fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: check-doc-references regression test"
else
  echo "FAILED"; exit 1
fi
