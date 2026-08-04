#!/usr/bin/env bash
# reclaim.sh — deterministic build-artifact & package-cache reclaim sweep.
#
# Two complementary retention mechanisms, split by how stale the artifact is:
#
#   STALE  (dir mtime older than --days): remove the whole target/ node_modules/
#          .venv/ directory. The project hasn't been built in months; keeping a
#          partial artifact set buys nothing.
#   ACTIVE (dir mtime within --days):     run `cargo sweep --time <days>` inside,
#          trimming only the stale artifacts *within* a live target/ so recent
#          builds stay warm. Rust only — no equivalent exists for node/python.
#
# Plus the regenerable package caches (uv, bun, go, brew, pre-commit, docker
# build cache), all of which rebuild on next use.
#
# DRY-RUN BY DEFAULT. Pass --apply to actually delete. Emits the structured
# `KEY=VALUE` / `RECLAIM …` rollup convention so a caller (or the weekly
# launchd job) reads a verdict instead of re-deriving the computation.
#
# On sizing: `du` sums st_blocks, and APFS reports a copy-on-write clone at FULL
# size even though its blocks are shared and cost nothing. uv and bun both clone
# from a global cache into .venv/node_modules, so du over-reports those; cargo
# gives each project its own compiled copy, so du is exact for target/. The
# rollup keeps the two apart rather than summing them into one wrong number, and
# --apply reports a df delta as ground truth. Swapping du for dust would not
# help: every tool reading st_blocks double-counts clones identically.
#
# Companion to home-audit.sh; backs `just -g reclaim-dry` / `just -g reclaim`.
set -euo pipefail

days=30
apply=0
root="$HOME/repos"

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) apply=1; shift ;;
        --days) days="$2"; shift 2 ;;
        --root) root="$2"; shift 2 ;;
        -h|--help)
            echo "usage: reclaim.sh [--apply] [--days N] [--root DIR]"
            exit 0 ;;
        *) echo "reclaim.sh: unknown arg: $1" >&2; exit 2 ;;
    esac
done

test "$(uname -s)" = "Darwin" || { echo "reclaim.sh: not Darwin, refusing" >&2; exit 1; }

now=$(date +%s)
cutoff=$(( now - days * 86400 ))
# `du` sums st_blocks, which APFS reports at FULL size for a copy-on-write
# clone even though the blocks are shared and cost nothing. That makes du exact
# for some artifact kinds and an over-estimate for others — see the rollup.
exact_kb=0      # cargo target/: real per-project copies, du is exact
bounded_kb=0    # node_modules/.venv: uv and bun clone these from a global cache
cache_kb=0
stale_list="$(mktemp)"
active_list="$(mktemp)"
trap 'rm -f "$stale_list" "$active_list"' EXIT

free_kb() { df -k / | awk 'NR==2{print $4}'; }
free_before=$(free_kb)

# ---------------------------------------------------------------- artifacts

echo "=== BUILD ARTIFACTS (root=$root days=$days) ==="

# -prune stops the walk descending INTO a matched dir: a target/ inside
# node_modules/ is already accounted for by its parent.
while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    mtime=$(stat -f %m "$dir" 2>/dev/null) || continue
    size_kb=$(du -sxk "$dir" 2>/dev/null | cut -f1) || continue
    [ "${size_kb:-0}" -lt 10240 ] && continue   # ignore <10 MB, not worth the noise
    if [ "$mtime" -lt "$cutoff" ]; then
        printf '%s\t%s\n' "$size_kb" "$dir" >> "$stale_list"
    elif [ "$(basename "$dir")" = "target" ]; then
        printf '%s\t%s\n' "$size_kb" "$dir" >> "$active_list"
    fi
done < <(find "$root" -maxdepth 5 -type d \
    \( -name target -o -name node_modules -o -name .venv \) -prune 2>/dev/null)

echo "--- stale (whole-dir removal) ---"
while IFS=$'\t' read -r size_kb dir; do
    age_days=$(( (now - $(stat -f %m "$dir")) / 86400 ))
    if [ "$(basename "$dir")" = "target" ]; then
        accuracy=exact
        exact_kb=$(( exact_kb + size_kb ))
    else
        # A cloned .venv/node_modules frees real space only where it holds the
        # LAST reference to those blocks; if the global cache still has them,
        # removing it frees close to nothing.
        accuracy=upper-bound
        bounded_kb=$(( bounded_kb + size_kb ))
    fi
    printf 'RECLAIM kind=stale accuracy=%s size_kb=%s age_days=%s path=%s\n' \
        "$accuracy" "$size_kb" "$age_days" "$dir"
    [ "$apply" -eq 1 ] && rm -rf "$dir"
done < <(sort -rn "$stale_list")

echo "--- active rust targets (cargo sweep --time $days) ---"
if command -v cargo-sweep >/dev/null 2>&1; then
    while IFS=$'\t' read -r size_kb dir; do
        crate_root="$(dirname "$dir")"
        printf 'SWEEP size_kb=%s path=%s\n' "$size_kb" "$crate_root"
        if [ "$apply" -eq 1 ]; then
            cargo sweep --time "$days" "$crate_root" 2>&1 | tail -1 || true
        fi
    done < <(sort -rn "$active_list")
else
    echo "SKIP reason=cargo-sweep-not-installed  (cargo install cargo-sweep)"
fi

# ------------------------------------------------------------------ caches

echo "=== PACKAGE CACHES ==="

# Each entry: label, path to measure, command to purge.
purge() {
    local label="$1" path="$2"; shift 2
    local size_kb=0
    [ -e "$path" ] && size_kb=$(du -sxk "$path" 2>/dev/null | cut -f1)
    printf 'CACHE name=%s size_kb=%s path=%s\n' "$label" "${size_kb:-0}" "$path"
    cache_kb=$(( cache_kb + ${size_kb:-0} ))
    if [ "$apply" -eq 1 ]; then
        if "$@" >/dev/null 2>&1; then
            printf 'CACHE_RESULT name=%s status=ok\n' "$label"
        else
            # uv in particular holds a lock while MCP servers / LSPs run out of
            # its archive dir; a failure here is expected and non-fatal.
            printf 'CACHE_RESULT name=%s status=failed\n' "$label"
        fi
    fi
}

command -v uv          >/dev/null 2>&1 && purge uv         "$HOME/.cache/uv"                  uv cache prune
command -v bun         >/dev/null 2>&1 && purge bun        "$HOME/.bun/install/cache"         bun pm cache rm
command -v go          >/dev/null 2>&1 && purge go-modcache "$HOME/go/pkg/mod"                go clean -modcache
command -v brew        >/dev/null 2>&1 && purge homebrew   "$HOME/Library/Caches/Homebrew/downloads" brew cleanup -s
command -v pre-commit  >/dev/null 2>&1 && purge pre-commit "$HOME/.cache/pre-commit"          pre-commit gc
command -v docker      >/dev/null 2>&1 && purge docker-build "" docker builder prune -af

echo "=== ROLLUP ==="
# Three ESTIMATES, deliberately not summed into one headline number — each has a
# different error mode, and collapsing them hides that:
#
#   exact       cargo target/ — every project compiles its own copy of each
#               dependency (no shared compiled-artifact cache), so du is honest.
#   upper bound node_modules/.venv — uv and bun materialise these from a global
#               cache via APFS clonefile, so du bills shared blocks per copy.
#   upper bound caches — `uv cache prune` and `pre-commit gc` evict only
#               UNREFERENCED entries, typically a small fraction of the total.
#
# In --apply mode ACTUAL_FREED_GB below supersedes all three: a df delta is the
# only clone-aware measurement available on APFS, since every tool that reads
# st_blocks (du, dust, gdu, ncdu) double-counts clones identically.
gb() { awk -v k="$1" 'BEGIN{printf "%.1f", k/1048576}'; }

printf 'ARTIFACT_EXACT_KB=%s\n' "$exact_kb"
printf 'ARTIFACT_EXACT_GB=%s  (cargo target/ — du is accurate here)\n' "$(gb "$exact_kb")"
printf 'ARTIFACT_BOUNDED_KB=%s\n' "$bounded_kb"
printf 'ARTIFACT_BOUNDED_GB=%s  (node_modules/.venv — upper bound, CoW clones)\n' "$(gb "$bounded_kb")"
printf 'CACHE_SIZE_KB=%s\n' "$cache_kb"
printf 'CACHE_SIZE_GB=%s  (upper bound; prune/gc evict only unused entries)\n' "$(gb "$cache_kb")"

if [ "$apply" -eq 1 ]; then
    sync
    free_after=$(free_kb)
    freed_kb=$(( free_after - free_before ))
    [ "$freed_kb" -lt 0 ] && freed_kb=0   # concurrent writes can outpace the sweep
    printf 'ACTUAL_FREED_KB=%s\n' "$freed_kb"
    printf 'ACTUAL_FREED_GB=%s  (df delta — ground truth)\n' "$(gb "$freed_kb")"
    printf 'STATUS=applied\n'
else
    printf 'ACTUAL_FREED_GB=n/a  (--apply measures the real df delta)\n'
    printf 'STATUS=dry-run  (pass --apply to delete)\n'
fi
printf 'DISK_AVAIL=%s\n' "$(df -h / | awk 'NR==2{print $4}')"
