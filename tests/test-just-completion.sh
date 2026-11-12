#!/usr/bin/env bash
# Regression test for `just <module>::<TAB>` completing module recipes.
#
# What is being protected
# -----------------------
# dot_zfunc/_just lists the ROOT justfile's recipes, grouped, at the recipe
# position and hands everything else to just's native (clap) completer. Module
# recipes (`labels::build`) are not in the root `.recipes` of `just --dump`, so
# they can only come from the native completer. The grouped path used to report
# success whenever the justfile had any recipe at all, whether or not one
# matched the typed prefix, so the native completer never ran and
# `just labels::<TAB>` offered nothing, with no error to notice.
#
# Why the run is shaped this way
# ------------------------------
# Completion is a property of a live shell, so the checks drive a real
# interactive zsh over a pty (zsh/zpty) and read back what TAB inserted, in a
# fixture justfile with one root recipe and one module. The CONTROL completes
# the root recipe through the grouped path: if that stops working, the pty
# harness is broken and the module assertions say nothing.

set -uo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; NC=$'\033[0m'
pass_count=0; fail_count=0

log_pass() { echo -e "  ${GREEN}✓${NC} $1"; pass_count=$((pass_count + 1)); }
log_fail() { echo -e "  ${RED}✗${NC} $1"; fail_count=$((fail_count + 1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for tool in just jq zsh; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "${YELLOW}SKIP${NC}: $tool not installed"
        exit 0
    fi
done

# The shipped completer, alone on fpath, so no installed ~/.zfunc/_just is used.
mkdir -p "$WORK/zfunc" "$WORK/proj/tools/labels"
cp "$REPO_ROOT/dot_zfunc/_just" "$WORK/zfunc/_just"

cat > "$WORK/proj/justfile" <<'JUST'
mod labels 'tools/labels'

# Root recipe, completed by the grouped path
[group('dev')]
rootbuild:
    @true
JUST
cat > "$WORK/proj/tools/labels/justfile" <<'JUST'
# Module recipe, completed only by the native completer
stickerprint:
    @true
JUST

cat > "$WORK/rc.zsh" <<RC
PS1='%% '
fpath=("$WORK/zfunc" \$fpath)
autoload -Uz compinit
compinit -u -d "$WORK/zcompdump"
zstyle ':completion:*' menu no
setopt NO_BEEP
RC

cat > "$WORK/pty.zsh" <<'ZSH'
setopt EXTENDED_GLOB
zmodload zsh/zpty
cd $3
zpty -b z zsh -f -i
zpty -w z "source $1"
sleep 2
integer i
for (( i=0; i<20; i++ )); do zpty -rt z junk 2>/dev/null; sleep 0.1; done
zpty -w -n z "$2"$'\t'
local out='' chunk
for (( i=0; i<20; i++ )); do
  if zpty -rt z chunk 2>/dev/null; then out+=$chunk; fi
  sleep 0.25
done
zpty -d z 2>/dev/null
print -r -- "${${out//$'\e'\[[0-9;?]#[a-zA-Z]/}//$'\r'/}"
ZSH

run_pty() {  # run_pty <input-line>  -> prints what the shell showed
    zsh "$WORK/pty.zsh" "$WORK/rc.zsh" "$1" "$WORK/proj" 2>/dev/null
}

expect() {  # expect <typed> <wanted-line> <description>
    local out
    out="$(run_pty "$1")"
    if grep -qF -- "$2" <<<"$out"; then
        log_pass "$3"
    else
        log_fail "$3; got: $(tr '\n' ' ' <<<"$out" | cut -c1-160)"
    fi
}

echo "just completion (pty, fixture justfile with one module)"
expect 'just rootb' 'just rootbuild' \
    "CONTROL: just rootb<TAB> completes the root recipe (grouped path)"
expect 'just labels::stick' 'just labels::stickerprint' \
    "just labels::stick<TAB> completes the module recipe (native fallback)"
expect 'just lab' 'just labels::stickerprint' \
    "just lab<TAB> completes into the module (native fallback)"

echo
echo "Passed: $pass_count  Failed: $fail_count"
[ "$fail_count" -eq 0 ]
