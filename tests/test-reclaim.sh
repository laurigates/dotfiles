#!/usr/bin/env bash
# Regression test: scripts/reclaim.sh runs on Linux and macOS and still finds
# stale build artifacts on both.
#
# What is being protected
# ------------------------
# reclaim.sh refused to run anywhere but Darwin, and it read directory mtimes
# with BSD `stat -f %m`. GNU stat reads -f as "filesystem status", so lifting
# the guard alone would have made every mtime lookup fail on Linux. The loop
# skips a dir whose mtime it cannot read, so the sweep would report nothing
# stale and exit 0, which looks like a clean tree. The cache section also
# hard-coded the macOS Homebrew path and ran `brew cleanup -s`, which left
# 2.5 GB of downloads on a Linux machine; `--prune=all` removes them.
#
# How
# ---
# A scratch root holds two >10 MB target/ dirs: one with a 2020 mtime, one
# fresh. A dry run (never --apply) with a scratch $HOME and PATH limited to
# /usr/bin:/bin, so no real cache tool is reached, must list the old one as
# stale with an age in years and must not list the fresh one. Reading the old
# dir's age proves the mtime lookup works on this platform, so a clean result
# is not vacuous. The brew and npx lines are checked in the source.
#
# Usage: tests/test-reclaim.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
RECLAIM="$REPO_DIR/scripts/executable_reclaim.sh"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
failures=0
pass() { echo "${GREEN}✓${NC} $1"; }
fail() { echo "${RED}✗${NC} $1"; failures=$((failures + 1)); }

[ -f "$RECLAIM" ] || { fail "reclaim.sh not found at $RECLAIM"; exit 1; }

fx=$(mktemp -d) || { echo 'mktemp failed' >&2; exit 1; }
if [ -z "$fx" ] || [ ! -d "$fx" ]; then echo 'bad sandbox dir' >&2; exit 1; fi
trap 'rm -rf "$fx"' EXIT

mkdir -p "$fx/home" "$fx/repos/old/target" "$fx/repos/new/target"
dd if=/dev/zero of="$fx/repos/old/target/blob" bs=1024 count=11264 2>/dev/null
dd if=/dev/zero of="$fx/repos/new/target/blob" bs=1024 count=11264 2>/dev/null
touch -t 202001010000 "$fx/repos/old/target"

out="$(env HOME="$fx/home" PATH=/usr/bin:/bin bash "$RECLAIM" --root "$fx/repos" --days 30 2>&1)"
rc=$?

if [ "$rc" -eq 0 ] && ! grep -q 'refusing' <<<"$out"; then
    pass "dry run completes on $(uname -s)"
else
    fail "dry run exited $rc on $(uname -s): $(tail -n 1 <<<"$out")"
fi

old_line="$(grep "^RECLAIM kind=stale .*path=$fx/repos/old/target\$" <<<"$out")"
age="$(sed -n 's/.* age_days=\([0-9]*\) .*/\1/p' <<<"$old_line")"
if [ -n "$old_line" ] && [ "${age:-0}" -gt 1000 ]; then
    pass "2020 target/ listed as stale (age_days=$age), so mtimes are read"
else
    fail "2020 target/ not listed as stale with its real age; mtime lookup broken? got: ${old_line:-nothing}"
fi

if grep -q "^RECLAIM kind=stale .*path=$fx/repos/new/target\$" <<<"$out"; then
    fail "fresh target/ was listed as stale"
else
    pass "fresh target/ not listed as stale"
fi

# The patterns match the script's source text, so $(...) and $HOME stay literal.
# shellcheck disable=SC2016
if grep -q 'purge homebrew *"$(brew --cache)/downloads" *brew cleanup --prune=all -s' "$RECLAIM"; then
    pass "brew uses brew --cache and cleanup --prune=all -s"
else
    fail "brew line must measure \$(brew --cache)/downloads and run brew cleanup --prune=all -s"
fi

# shellcheck disable=SC2016
if grep -q 'purge npx *"$HOME/.npm/_npx"' "$RECLAIM"; then
    pass "npx cache is purged (npm cache clean leaves it)"
else
    fail "npx cache (~/.npm/_npx) purge missing"
fi

if [ "$failures" -eq 0 ]; then
    echo "${GREEN}All reclaim.sh checks passed${NC}"
    exit 0
fi
echo "${RED}$failures reclaim.sh check(s) failed${NC}"
exit 1
