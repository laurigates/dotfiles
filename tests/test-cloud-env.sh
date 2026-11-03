#!/usr/bin/env bash
# Regression test for dot_local/bin/executable_cloud-env.
#
# What is being protected
# ------------------------
# cloud-env is what makes a claude.ai cloud container fail LOUDLY when it does
# not match these dotfiles. Its predecessor failure mode exited 0 having done
# nothing (a setup script ran `chezmoi init` with an empty repo argument). So
# the contract pinned here is mostly about exit codes:
#   1. `check` exits 0 only when every item is OK.
#   2. Each gap exits 1 and names itself: missing command, empty chezmoi source,
#      wrong chezmoi origin, missing settings, missing marketplace, an enabled
#      plugin not installed, an enabled plugin installed only at project scope.
#   3. `bootstrap` adds the marketplace when absent, installs exactly the
#      enabled-but-missing plugins at user scope, and is idempotent.
#   4. A failed install makes `bootstrap` exit 1.
#
# `claude` and `chezmoi` are stubs backed by fixture files; git is real.
# CLOUD_ENV_BASH picks the interpreter, so the bash-3.2 path can be exercised
# (CLOUD_ENV_BASH=/path/to/bash-3.2 tests/test-cloud-env.sh).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SUT="$REPO_DIR/dot_local/bin/executable_cloud-env"
SH="${CLOUD_ENV_BASH:-bash}"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
pass_count=0; fail_count=0

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
[ -f "$SUT" ] || { echo "FAIL: script not found: $SUT"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

pass() { echo "${GREEN}PASS${NC} $1"; pass_count=$((pass_count + 1)); }
fail() {
  echo "${RED}FAIL${NC} $1"
  if [ -n "${2:-}" ]; then while IFS= read -r l; do echo "      $l"; done <<<"$2"; fi
  fail_count=$((fail_count + 1))
}

# --- fixture world ------------------------------------------------------------
# setup <case>: fresh HOME with a valid chezmoi source, settings enabling
# alpha+beta, the marketplace added, and both plugins installed at user scope.
setup() {
  T="$WORK/$1"
  mkdir -p "$T/home/.claude" "$T/bin" "$T/fix"
  export HOME="$T/home" FIX="$T/fix"

  git init -q "$FIX/src"
  git -C "$FIX/src" remote add origin https://github.com/laurigates/dotfiles.git
  git -C "$FIX/src" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

  cat >"$HOME/.claude/settings.json" <<'JSON'
{
  "extraKnownMarketplaces": {"laurigates-claude-plugins": {"source": {"source": "github", "repo": "laurigates/claude-plugins"}}},
  "enabledPlugins": {
    "alpha-plugin@laurigates-claude-plugins": true,
    "beta-plugin@laurigates-claude-plugins": true,
    "off-plugin@laurigates-claude-plugins": false,
    "pyright-lsp@claude-plugins-official": true
  }
}
JSON
  echo '[{"name":"claude-plugins-official"},{"name":"laurigates-claude-plugins"}]' >"$FIX/marketplaces.json"
  echo '[{"id":"alpha-plugin@laurigates-claude-plugins","scope":"user"},{"id":"beta-plugin@laurigates-claude-plugins","scope":"user"}]' >"$FIX/plugins.json"
  : >"$FIX/calls.log"

  cat >"$T/bin/chezmoi" <<'SH'
#!/bin/sh
[ "$1" = source-path ] && { echo "$FIX/src"; exit 0; }
exit 1
SH
  cat >"$T/bin/claude" <<'SH'
#!/bin/sh
echo "$*" >>"$FIX/calls.log"
case "$*" in
  "plugin list --json") cat "$FIX/plugins.json" ;;
  "plugin marketplace list --json") cat "$FIX/marketplaces.json" ;;
  "plugin marketplace add laurigates/claude-plugins")
    jq '. + [{"name":"laurigates-claude-plugins"}]' "$FIX/marketplaces.json" >"$FIX/m.tmp" && mv "$FIX/m.tmp" "$FIX/marketplaces.json" ;;
  "plugin marketplace update laurigates-claude-plugins") : ;;
  "plugin install "*" --scope user")
    id="$3"
    grep -qx "${id%@*}" "$FIX/fail_install" 2>/dev/null && { echo "install failed: $id" >&2; exit 1; }
    jq --arg id "$id" '. + [{"id":$id,"scope":"user"}]' "$FIX/plugins.json" >"$FIX/p.tmp" && mv "$FIX/p.tmp" "$FIX/plugins.json" ;;
  *) echo "unexpected: $*" >&2; exit 1 ;;
esac
SH
  chmod +x "$T/bin/chezmoi" "$T/bin/claude"
}

# run <subcommand>: OUT/RC from the script under test, with only fixture
# commands required so no installer touches the network.
run() {
  OUT="$(PATH="$T/bin:$PATH" CLOUD_ENV_REQUIRED_COMMANDS="${REQ:-jq}" "$SH" "$SUT" "$1" 2>&1)"
  RC=$?
}

expect() { # expect <case> <rc> [grep-pattern]
  if [ "$RC" -ne "$2" ]; then fail "$1 (exit $RC, want $2)" "$OUT"
  elif [ -n "${3:-}" ] && ! grep -qE "$3" <<<"$OUT"; then fail "$1 (output lacks /$3/)" "$OUT"
  else pass "$1"; fi
}

# lint:shell only covers tracked *.sh files; the script under test has no
# extension, so lint it here.
if command -v shellcheck >/dev/null 2>&1; then
  if sc_out="$(shellcheck "$SUT" 2>&1)"; then pass "shellcheck: cloud-env"; else fail "shellcheck: cloud-env" "$sc_out"; fi
fi

# --- check --------------------------------------------------------------------
setup ok; run check
expect "check: everything present exits 0" 0 "all checks passed"

setup cmd; REQ="jq no-such-command-xyz" run check; REQ=
expect "check: missing required command fails" 1 "FAIL  command no-such-command-xyz"

setup empty-src; rm -rf "$FIX/src"; git init -q "$FIX/src"; run check
expect "check: chezmoi source without commits fails (the original silent no-op)" 1 "FAIL  chezmoi source: no commits"

setup origin; git -C "$FIX/src" remote set-url origin https://github.com/someone/else.git; run check
expect "check: wrong chezmoi origin fails" 1 "FAIL  chezmoi source: origin"

setup settings; rm "$HOME/.claude/settings.json"; run check
expect "check: missing settings.json fails" 1 "FAIL  .*settings.json: missing"

setup mkt; echo '[{"name":"claude-plugins-official"}]' >"$FIX/marketplaces.json"; run check
expect "check: missing marketplace fails" 1 "FAIL  marketplace laurigates-claude-plugins"

setup plug; echo '[{"id":"alpha-plugin@laurigates-claude-plugins","scope":"user"}]' >"$FIX/plugins.json"; run check
expect "check: enabled plugin not installed fails and is named" 1 "FAIL  plugin beta-plugin@"
if grep -q "off-plugin\|pyright" <<<"$OUT"; then
  fail "check: disabled / other-marketplace plugins must not be required" "$OUT"
else
  pass "check: disabled and other-marketplace plugins are not required"
fi

setup scope
echo '[{"id":"alpha-plugin@laurigates-claude-plugins","scope":"user"},{"id":"beta-plugin@laurigates-claude-plugins","scope":"project"}]' >"$FIX/plugins.json"
run check
expect "check: project-scope-only install counts as missing" 1 "FAIL  plugin beta-plugin@"

# --- bootstrap ----------------------------------------------------------------
setup boot
echo '[{"name":"claude-plugins-official"}]' >"$FIX/marketplaces.json"
echo '[{"id":"alpha-plugin@laurigates-claude-plugins","scope":"user"}]' >"$FIX/plugins.json"
run bootstrap
expect "bootstrap: adds marketplace, installs missing plugin, check passes" 0 "all checks passed"
if grep -qx "plugin marketplace add laurigates/claude-plugins" "$FIX/calls.log" \
   && [ "$(grep -c '^plugin install ' "$FIX/calls.log")" -eq 1 ] \
   && grep -qx "plugin install beta-plugin@laurigates-claude-plugins --scope user" "$FIX/calls.log"; then
  pass "bootstrap: installs exactly the enabled-but-missing plugin, at user scope"
else
  fail "bootstrap: unexpected CLI calls" "$(cat "$FIX/calls.log")"
fi

: >"$FIX/calls.log"; run bootstrap
if [ "$RC" -eq 0 ] && ! grep -q '^plugin install \|^plugin marketplace add' "$FIX/calls.log" \
   && grep -qx "plugin marketplace update laurigates-claude-plugins" "$FIX/calls.log"; then
  pass "bootstrap: second run installs nothing (idempotent)"
else
  fail "bootstrap: second run was not a no-op (exit $RC)" "$(cat "$FIX/calls.log")"
fi

setup bootfail
echo '[]' >"$FIX/plugins.json"; echo beta-plugin >"$FIX/fail_install"
run bootstrap
expect "bootstrap: a failed install exits 1 and names the plugin" 1 "FAIL  plugin beta-plugin@"
if grep -q "plugin install alpha-plugin" "$FIX/calls.log"; then
  pass "bootstrap: keeps installing after one failure"
else
  fail "bootstrap: stopped at the first failure" "$(cat "$FIX/calls.log")"
fi

echo
# shellcheck disable=SC2016  # $BASH_VERSION is meant for the child shell
echo "cloud-env: $pass_count passed, $fail_count failed (interpreter: $("$SH" -c 'echo $BASH_VERSION'))"
[ "$fail_count" -eq 0 ]
