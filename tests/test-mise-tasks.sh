#!/usr/bin/env bash
# Regression test for this repo's mise tasks (#398, #397).
#
# A lint task that cannot fail looks exactly like a clean tree. #398 found
# three ways that happened, each silent or misattributed:
#
#   1. lint:shell carried `\\;` in a TOML *literal* string, which does no
#      escape processing, so find got a stray `\` argument and aborted
#      before running the linter.
#   2. Lint steps that cannot fail: `find -exec X {} \;` discards X's exit
#      status, and the aggregate `lint` turned every linter failure into a
#      warning.
#   3. The tasks lived in the global mise config, whose tasks run with
#      dir=$HOME. Repo-relative linters errored out, `clean` ran
#      `find . -name "*.tmp" -delete` over the whole home directory, and the
#      #397 apply/diff/status/verify tasks resolved the chezmoi source from
#      $HOME, so from a worktree they acted on the main checkout.
#
# The repo tasks now live in the repo-root .mise.toml, whose tasks run in the
# checkout or worktree that holds it. Checked here:
#
#   Static   The global template is rendered (not retyped) and parsed with
#            tomllib. No decoded run string holds `\\` or `-exec ... \;`; the
#            repo tasks are defined in .mise.toml and not globally; no global
#            task reads the repo (the source tree, a path that names a tracked
#            top-level entry, `.` as an input, or a repo linter) or depends on
#            a task that is not global.
#   Dir      `mise tasks ls` from the repo root and from a subdirectory: every
#            .mise.toml task runs in the repo root. This runs first, with fresh
#            mise state and no trust, so it also fails if .mise.toml stops
#            being a config mise reads without `mise trust`.
#   Source   apply/diff/status/verify pass --source <this checkout> (a stub
#            chezmoi records its arguments; apply also gets --dry-run).
#   Clean    `clean` deletes *.tmp/.DS_Store in a fixture checkout, and not in
#            its .git, another worktree, or $HOME (brew and mise are stubs).
#   Lint     lint:shell, lint:lua, lint:actions and lint:docs each: fail and
#            name the tool when it is broken (a stub that exits non-zero);
#            pass a clean fixture; fail a planted-bad fixture AND name the
#            planted file (naming it proves the linter ran rather than erroring
#            early); pass this repo. The aggregate `lint` fails the bad fixture
#            with every available linter's finding in its output, and passes
#            this repo when every linter is available.
#   Just     The justfile lint* recipes (#439). Statically, each recipe's whole
#            body is one `mise run lint[:x]` of an existing task, so there is a
#            single implementation. With `just` installed, each recipe also
#            reaches mise (a stub records the call), fails and names the tool
#            when that tool is not on PATH, and fails the planted-bad fixture.
#
# mise runs with `env -i`, HOME set to an empty directory, isolated config,
# state and cache dirs, the global config replaced by the tasks extracted from
# the rendered template, and MISE_CEILING_PATHS so no parent config leaks in.
# A task that silently ran in $HOME would find nothing there.
#
# A linter that is missing or cannot run SKIPs its fixture and repo checks
# loudly. `--require shellcheck,python3` turns those SKIPs into failures (the
# smoke Linters job does this). luacheck 1.2.0 cannot run on Lua 5.5
# (lunarmodules/luacheck#147); lint:lua prints the fix.
#
# Usage: tests/test-mise-tasks.sh [--require tool[,tool...]]   (tools: shellcheck,
#   luacheck, actionlint, python3, just)
#   MISE_TASKS_REPO=<git checkout>  test another copy of the repo (controls)

set -uo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; NC=$'\033[0m'
pass_count=0; fail_count=0; skip_count=0

log_pass() { echo -e "  ${GREEN}✓${NC} $1"; pass_count=$((pass_count + 1)); }
log_fail() { echo -e "  ${RED}✗${NC} $1"; fail_count=$((fail_count + 1)); }
log_skip() { echo -e "  ${YELLOW}—${NC} SKIP: $1"; skip_count=$((skip_count + 1)); }

REQUIRED_TOOLS=","
while [ $# -gt 0 ]; do
    case "$1" in
        --require) REQUIRED_TOOLS=",${2:-},"; shift 2 ;;
        --require=*) REQUIRED_TOOLS=",${1#--require=},"; shift ;;
        -h | --help) sed -n '2,/^set -uo/p' "$0" | sed '$d'; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

# skip_or_fail <tool> <message>: SKIP, or FAIL when --require names the tool.
skip_or_fail() {
    case "$REQUIRED_TOOLS" in
        *",$1,"*) log_fail "$2 (--require $1)" ;;
        *) log_skip "$2" ;;
    esac
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${MISE_TASKS_REPO:-$SCRIPT_DIR/..}" && pwd -P)"

# Tasks that read the repo and must live in .mise.toml, not the global config.
REPO_TASKS="apply diff status verify check
    test test:setup test:plugin-refs test:context-budget test:shell-precedence
    test:ci-pins test:gh-completion test:chezmoi-exact-guard test:mise-tasks
    lint lint:shell lint:lua lint:actions lint:docs
    docker qa ci clean security:audit security:scan edit"

for tool in git python3 chezmoi mise; do
    command -v "$tool" >/dev/null 2>&1 || { echo "${RED}✗${NC} $tool is required and not on PATH" >&2; exit 1; }
done
python3 -c 'import tomllib' 2>/dev/null || { echo "${RED}✗${NC} python3 >= 3.11 (tomllib) is required" >&2; exit 1; }
MISE_BIN="$(command -v mise)"
JUST_BIN="$(command -v just || true)"
REAL_MISE_DATA="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-mise-tasks.XXXXXX")"
WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT
EMPTY_HOME="$WORK/home"; EMPTY_DATA="$WORK/empty-data"
mkdir -p "$EMPTY_HOME" "$EMPTY_DATA" "$WORK/mise/cfg" "$WORK/mise/cache" "$WORK/chezmoi"

echo "mise tasks in $REPO"

# --- Render the global template; extract its tasks ---------------------------
if ! chezmoi execute-template --source="$REPO" --config="$WORK/chezmoi/chezmoi.toml" \
        --cache="$WORK/chezmoi/cache" --persistent-state="$WORK/chezmoi/state.boltdb" \
        <"$REPO/private_dot_config/mise/config.toml.tmpl" >"$WORK/global-full.toml"; then
    log_fail "chezmoi could not render private_dot_config/mise/config.toml.tmpl"
    exit 1
fi
# Only [tasks.*] tables go to the isolated global config: no [tools] to
# install, no [env] reading ~/.api_tokens. The parse check proves nothing
# was lost.
if ! python3 - "$WORK/global-full.toml" "$WORK/global-tasks.toml" <<'PY'
import re, sys, tomllib
src, dst = sys.argv[1], sys.argv[2]
keep, out = False, []
for line in open(src, encoding="utf-8"):
    m = re.match(r'^\[\[?([A-Za-z_"][^\]]*)\]', line)
    if m:
        keep = m.group(1).startswith(("tasks", "task_config"))
    if keep:
        out.append(line)
open(dst, "w", encoding="utf-8").writelines(out)
full = tomllib.load(open(src, "rb"))
got = tomllib.load(open(dst, "rb"))
assert full.get("tasks", {}) == got.get("tasks", {}), "tasks changed in extraction"
assert full.get("task_config", {}) == got.get("task_config", {}), "task_config changed"
PY
then
    log_fail "could not extract the [tasks] tables from the rendered template"
    exit 1
fi

# --- Static checks ------------------------------------------------------------
echo "Static: run strings and task placement"
git -C "$REPO" ls-files | cut -d/ -f1 | sort -u >"$WORK/toplevel.txt"
python3 - "$WORK/global-tasks.toml" "$REPO/.mise.toml" "$REPO" "$WORK/toplevel.txt" \
    "$REPO_TASKS" >"$WORK/static.out" <<'PY'
import os, re, sys, tomllib

gpath, lpath, repo, toppath, required = sys.argv[1:6]
g = tomllib.load(open(gpath, "rb")).get("tasks", {})
l = tomllib.load(open(lpath, "rb")).get("tasks", {}) if os.path.exists(lpath) else {}
top = [n for n in open(toppath, encoding="utf-8").read().split("\n") if n]
required = required.split()


def say(kind, msg):
    print(f"{kind} {msg}")


def aliases(tasks):
    out = {}
    for n, t in tasks.items():
        a = t.get("alias", [])
        for x in [a] if isinstance(a, str) else a:
            out[x] = n
    return out


def runs(t):
    r = t.get("run", [])
    return [r] if isinstance(r, str) else [x for x in r if isinstance(x, str)]


def deps(t):
    out = []
    for key in ("depends", "depends_post", "wait_for"):
        v = t.get(key, [])
        for d in [v] if isinstance(v, str) else v:
            if isinstance(d, str):
                out.append(d.split()[0])
            elif isinstance(d, list) and d:
                out.append(str(d[0]))
    return out


# 1 + 2: escaping and exit status, in every run string.
bad = 0
for where, tasks in (("global", g), (".mise.toml", l)):
    for name, t in sorted(tasks.items()):
        for r in runs(t):
            if "\\\\" in r:
                line = next(x.strip() for x in r.splitlines() if "\\\\" in x)
                say("FAIL", f"{where} task {name}: decoded run string holds a double backslash (TOML over-escaping): {line}")
                bad += 1
            for m in re.finditer(r"-exec(?:dir)?\s+(\S+)[^;+\n]*?(\\;|\+)", r):
                if m.group(2) == "\\;":
                    say("FAIL", f"{where} task {name}: `-exec {m.group(1)} ... \\;` discards {m.group(1)}'s exit status (use + or xargs)")
                    bad += 1
if not bad:
    say("PASS", f"no over-escaped string or exit-masking find -exec in {len(g) + len(l)} task run strings")

# 3a: the repo tasks live in .mise.toml, not in the global config. An alias
# counts as defining its name.
l_alias = aliases(l)
bad = 0
for name in required:
    if name in g:
        say("FAIL", f"{name} is a global task, so it runs in $HOME; move it to .mise.toml")
        bad += 1
    if name not in l and name not in l_alias:
        say("FAIL", f"{name} is not defined in .mise.toml")
        bad += 1
for name in sorted(set(g) & set(l) - set(required)):
    say("FAIL", f"{name} is defined both globally and in .mise.toml")
    bad += 1
if not bad:
    say("PASS", f"all {len(required)} repo tasks are in .mise.toml and none is global")

# 3c: a task that runs nothing passes without checking anything (#439:
# `[tasks.check] alias = "status"` was one, so `mise run check` and qa's
# dependency on it were inert). Every task needs a run or a dependency, and an
# alias must not reuse the name of a task.
bad = 0
for name, t in sorted(l.items()):
    if not t.get("run") and not t.get("depends"):
        say("FAIL", f".mise.toml task {name} has neither run nor depends, so it does nothing")
        bad += 1
for alias, owner in sorted(l_alias.items()):
    if alias in l:
        say("FAIL", f".mise.toml task {owner} has alias {alias}, which is also a task of its own")
        bad += 1
if not bad:
    say("PASS", f"every one of the {len(l)} .mise.toml tasks runs something, and no alias shadows a task")

# 3b: no global task reads the repo. A global task runs in $HOME, so a
# relative path is a $HOME path: flag one that names a tracked top-level
# entry, `.` as an input, the source tree, or a linter that reads the cwd repo.
top_re = re.compile(
    r"""(?:^|[\s"'=(])(?:\./)?(?:""" + "|".join(re.escape(n) for n in top) + r""")(?=/|[\s"')]|$)"""
)
signals = [
    ("names the chezmoi source tree", lambda s: repo in s or re.search(r"\$\{?DOTFILES_DIR\b", s) or "rev-parse --show-toplevel" in s),
    ("reads `.` (the cwd)", lambda s: re.search(r"\S\s+\.(?=\s|$|;|\))", s)),
    ("names a tracked repo path", lambda s: top and top_re.search(s)),
    ("runs a linter on the cwd repo", lambda s: re.search(r"(?:^|[\s;&|(])(?:actionlint|pre-commit\s+run|gitleaks\s+(?:dir|git|detect))\b", s)),
]
flagged = {}
for name, t in sorted(g.items()):
    for r in runs(t):
        for line in r.splitlines():
            s = line.strip()
            if not s or s.startswith("#") or re.match(r"(?:echo|printf)\b", s):
                continue
            for label, test in signals:
                if test(s) and name not in flagged:
                    flagged[name] = f"{label}: {s}"
for name, t in sorted(g.items()):
    for d in deps(t):
        if d not in g and name not in flagged:
            flagged[name] = f"depends on {d}, which is not a global task"
        elif d in flagged and name not in flagged:
            flagged[name] = f"depends on {d}, which reads the repo"
for name, why in sorted(flagged.items()):
    say("FAIL", f"global task {name} runs in $HOME but {why}")
if not flagged:
    say("PASS", f"none of the {len(g)} global tasks reads the repo")
say("DONE", "")
PY
grep -q '^DONE' "$WORK/static.out" || { log_fail "static checker crashed"; cat "$WORK/static.out"; }
while IFS= read -r l; do
    case "$l" in
        PASS\ *) log_pass "${l#PASS }" ;;
        FAIL\ *) log_fail "${l#FAIL }" ;;
    esac
done <"$WORK/static.out"

# report <file>: PASS/FAIL lines from a checker become results.
report() {
    local l
    while IFS= read -r l; do
        case "$l" in
            PASS\ *) log_pass "${l#PASS }" ;;
            FAIL\ *) log_fail "${l#FAIL }" ;;
        esac
    done <"$1"
}

# --- justfile lint recipes delegate to mise (#439) ------------------------------
# The justfile once carried its own lint recipes: they printed a warning and
# exited 0 when the tool was missing, walked .claude/worktrees/ with find, and
# lint-brew checked a Brewfile the repo does not have. Each lint* recipe is now
# one `mise run lint[:x]`, so one implementation (the mise task, tested below)
# serves both entry points.
echo "Just: lint* recipes are one mise call each"
python3 - "$REPO/justfile" "$REPO/.mise.toml" >"$WORK/just-static.out" <<'PY'
import re, sys, tomllib

jpath, lpath = sys.argv[1:3]
tasks = tomllib.load(open(lpath, "rb")).get("tasks", {})
recipes, cur = {}, None
for line in open(jpath, encoding="utf-8").read().splitlines():
    m = re.match(r"^([A-Za-z_][\w-]*)\b[^:=#]*:(?!=)\s*(.*)$", line)
    if m and not line[0].isspace():
        cur = m.group(1)
        recipes[cur] = {"deps": m.group(2).strip(), "body": []}
    elif line[:1].isspace() and cur and line.strip():
        recipes[cur]["body"].append(line.strip())
    elif line.strip() and not line.startswith("#") and not line[0].isspace():
        cur = None

lint = {n: r for n, r in recipes.items() if n == "lint" or n.startswith("lint-")}
if not lint:
    print("FAIL the justfile has no lint recipe")
bad = 0
for name, r in sorted(lint.items()):
    want = name.replace("-", ":", 1)
    work = [b for b in r["body"] if not re.match(r"@?(echo|printf)\b", b)]
    got = [re.sub(r"^@", "", b) for b in work]
    if r["deps"]:
        print(f"FAIL just {name} depends on `{r['deps']}`; a dependency chain stops at the first failure, delegate with one `mise run {want}`")
        bad += 1
    elif got != [f"mise run {want}"]:
        print(f"FAIL just {name} must be exactly `mise run {want}`, found: {got or 'no command'}")
        bad += 1
    elif want not in tasks:
        print(f"FAIL just {name} runs `mise run {want}`, but .mise.toml has no task {want}")
        bad += 1
if lint and not bad:
    print(f"PASS all {len(lint)} lint recipes ({', '.join(sorted(lint))}) are one `mise run` of an existing task")
PY
report "$WORK/just-static.out"

# --- mise harness -------------------------------------------------------------
# run_env <cwd> <state-dir> <data-dir> <path> <command...>: output + rc.
# Two ceilings. The parent of the git checkout holding <cwd>: mise reads that
# checkout's .mise.toml and nothing above it (a worktree sits inside the main
# checkout). $WORK: a task that runs in the empty $HOME does not pick up
# configs above it, such as the real ~/.config/mise/config.toml when $TMPDIR
# is under the real home.
run_env() {
    local cwd="$1" state="$2" data="$3" path="$4" top
    shift 4
    top="$(git -C "$cwd" rev-parse --show-toplevel)" || return 1
    (cd "$cwd" && env -i HOME="$EMPTY_HOME" PATH="$path" TERM=dumb \
        ${LANG:+LANG="$LANG"} ${LC_ALL:+LC_ALL="$LC_ALL"} ${LC_CTYPE:+LC_CTYPE="$LC_CTYPE"} \
        MISE_GLOBAL_CONFIG_FILE="$WORK/global-tasks.toml" MISE_CONFIG_DIR="$WORK/mise/cfg" \
        MISE_STATE_DIR="$state" MISE_CACHE_DIR="$WORK/mise/cache" MISE_DATA_DIR="$data" \
        MISE_CEILING_PATHS="$(dirname "$top"):$WORK" MISE_TASK_RUN_AUTO_INSTALL=0 \
        "$@" </dev/null 2>&1)
}
run_mise() {  # run_mise <cwd> <state-dir> <data-dir> <path> <mise args...>
    local cwd="$1" state="$2" data="$3" path="$4"
    shift 4
    run_env "$cwd" "$state" "$data" "$path" "$MISE_BIN" "$@"
}
run_just() {  # run_just <cwd> <state-dir> <data-dir> <path> <just args...>
    local cwd="$1" state="$2" data="$3" path="$4"
    shift 4
    run_env "$cwd" "$state" "$data" "$path" "$JUST_BIN" "$@"
}
# path_without <tool>: a directory of symlinks to everything on $PATH except
# <tool>, for PATH= when the tool must be missing rather than broken.
path_without() {
    local tool="$1" d="$WORK/nopath-$1" dirs i
    if [ ! -d "$d" ]; then
        mkdir -p "$d"
        IFS=: read -ra dirs <<<"$PATH"
        for ((i = ${#dirs[@]} - 1; i >= 0; i--)); do  # earlier PATH entries win
            [ -d "${dirs[i]}" ] && ln -sf "${dirs[i]}"/* "$d"/ 2>/dev/null
        done
        rm -f "$d/$tool"
    fi
    echo "$d"
}
# run_task <root> <task> [extra args]: run with the real tool installs.
run_task() {
    local root="$1" task="$2"
    shift 2
    run_mise "$root" "$WORK/mise/state" "$REAL_MISE_DATA" "$PATH" run "$task" "$@"
}

# --- Task working directory (first: fresh state, nothing trusted) -------------
echo "Dir: .mise.toml tasks run in the repo root"
for sub in . tests; do
    [ -d "$REPO/$sub" ] || continue
    out=$(run_mise "$REPO/$sub" "$WORK/mise/state-dir" "$REAL_MISE_DATA" "$PATH" tasks ls --json); rc=$?
    if [ $rc -ne 0 ]; then
        log_fail "mise tasks ls fails in $sub (untrusted .mise.toml?): $(head -3 <<<"$out")"
        continue
    fi
    printf '%s\n' "$out" >"$WORK/tasks.json"
    python3 - "$REPO" "$sub" "$WORK/tasks.json" >"$WORK/dir.out" <<'PY' || { log_fail "could not parse mise tasks ls --json"; continue; }
import json, os, sys
repo, sub, path = sys.argv[1:4]
tasks = json.load(open(path, encoding="utf-8"))
local = os.path.join(repo, ".mise.toml")
mine = [t for t in tasks if os.path.realpath(t.get("source") or "") == local]
wrong = [t for t in mine if os.path.realpath(t.get("dir") or "") != repo]
for t in wrong:
    print(f"FAIL {t['name']} runs in {t.get('dir')!r}, not the repo root (invoked from {sub})")
if mine and not wrong:
    print(f"PASS all {len(mine)} .mise.toml tasks run in the repo root (invoked from {sub})")
if not mine:
    print(f"FAIL no task is defined in {local}")
PY
    while IFS= read -r l; do
        case "$l" in
            PASS\ *) log_pass "${l#PASS }" ;;
            FAIL\ *) log_fail "${l#FAIL }" ;;
        esac
    done <"$WORK/dir.out"
done

# --- apply/diff/status/verify/check act on this checkout (#397) -----------------
# check is an alias of status. It used to be a task of its own with no run, so
# `mise run check` and qa's dependency on it ran nothing (#439): it must reach
# `chezmoi status`, and qa must run status.
echo "Source: chezmoi tasks pass --source <this checkout>"
STUB_CZ="$WORK/stub-chezmoi"; mkdir -p "$STUB_CZ"
# shellcheck disable=SC2016 # $(pwd -P) and $* expand when the stub runs
printf '#!/bin/sh\necho "MISE-TASKS-STUB chezmoi pwd=$(pwd -P) args=$*"\n' >"$STUB_CZ/chezmoi"
chmod +x "$STUB_CZ/chezmoi"
if [ ! -x "$STUB_CZ/chezmoi" ]; then
    log_fail "stub chezmoi is not executable; not running apply"
else
    # status first: its sentinel proves the stub shadows the real chezmoi
    # before apply runs at all. The empty data dir keeps the pinned chezmoi
    # off PATH; apply also gets --dry-run in case the stub is ever bypassed.
    for t in status check diff verify apply; do
        want=$t; [ "$t" = check ] && want=status
        extra=(); [ "$t" = apply ] && extra=(--dry-run)
        out=$(run_mise "$REPO/tests" "$WORK/mise/state" "$EMPTY_DATA" "$STUB_CZ:$PATH" run "$t" ${extra[@]+"${extra[@]}"}); rc=$?
        line=$(grep 'MISE-TASKS-STUB chezmoi' <<<"$out" | head -1)
        if [ -z "$line" ]; then
            log_fail "$t: the stub chezmoi never ran (rc=$rc): $(grep -v '^\[' <<<"$out" | head -1)"
            [ "$t" = status ] && { log_fail "stopping before apply: stub not in effect"; break; }
            continue
        fi
        src=$(sed -nE 's/.*--source ([^ ]+).*/\1/p' <<<"$line")
        if [ -z "$src" ] || [ "$(cd "$src" 2>/dev/null && pwd -P)" != "$REPO" ]; then
            log_fail "$t: chezmoi ran without --source <this checkout>: ${line#*args=}"
        elif ! grep -qE -- "--source [^ ]+ $want( |\$)" <<<"$line"; then
            log_fail "$t: expected \`chezmoi --source <this checkout> $want\`, ran: ${line#*args=}"
        else
            log_pass "$t: runs \`chezmoi $want\` with --source set to this checkout (invoked from tests/)"
        fi
    done
    # qa depends on check; a dry run lists what would run without running it.
    out=$(run_mise "$REPO/tests" "$WORK/mise/state" "$EMPTY_DATA" "$STUB_CZ:$PATH" run --dry-run qa); rc=$?
    if [ $rc -eq 0 ] && grep -q '^\[status\] ' <<<"$out" && grep -q '^\[lint\] ' <<<"$out"; then
        log_pass "qa: its check dependency resolves to status, and lint runs too"
    else
        log_fail "qa: rc=$rc and the dry run lists no status and lint: $(head -3 <<<"$out" | tr '\n' ' ')"
    fi
fi

# --- clean deletes only inside this checkout -----------------------------------
echo "Clean: deletes temp files in this checkout only"
CF="$WORK/cleanfix"; STUB_CL="$WORK/stub-clean"
mkdir -p "$CF/sub" "$CF/.claude/worktrees/other" "$STUB_CL"
cp "$REPO/.mise.toml" "$CF/.mise.toml"
git -C "$CF" init -q
for f in "$CF/zz.tmp" "$CF/sub/zz.tmp" "$CF/.DS_Store" "$CF/.claude/worktrees/other/zz.tmp" \
    "$CF/.git/zz.tmp" "$EMPTY_HOME/zz.tmp"; do : >"$f"; done
# brew cleanup and mise prune go to stubs; the task must not reach the real ones.
for s in brew mise; do
    printf '#!/bin/sh\necho "MISE-TASKS-STUB %s $*"\n' "$s" >"$STUB_CL/$s"
    chmod +x "$STUB_CL/$s"
done
if [ "$(PATH="$STUB_CL:$PATH" command -v brew)" != "$STUB_CL/brew" ] ||
    [ "$(PATH="$STUB_CL:$PATH" command -v mise)" != "$STUB_CL/mise" ]; then
    log_fail "clean: stub brew/mise do not shadow the real ones; not running clean"
else
    out=$(run_mise "$CF/sub" "$WORK/mise/state" "$EMPTY_DATA" "$STUB_CL:$PATH" run clean); rc=$?
    gone=""; kept=""
    for f in zz.tmp sub/zz.tmp .DS_Store; do [ -e "$CF/$f" ] && kept="$kept $f"; done
    for f in "$CF/.claude/worktrees/other/zz.tmp" "$CF/.git/zz.tmp" "$EMPTY_HOME/zz.tmp"; do
        [ -e "$f" ] || gone="$gone ${f#"$WORK"/}"
    done
    if [ $rc -ne 0 ] || [ "$(grep -c 'MISE-TASKS-STUB' <<<"$out")" -ne 2 ]; then
        log_fail "clean: rc=$rc, stub calls $(grep -c 'MISE-TASKS-STUB' <<<"$out")/2: $(grep -v '^\[' <<<"$out" | head -1)"
    elif [ -n "$gone" ]; then
        log_fail "clean deleted files outside this checkout:$gone"
    elif [ -n "$kept" ]; then
        log_fail "clean left temp files in this checkout:$kept"
    else
        log_pass "clean: removes *.tmp/.DS_Store in the checkout; other worktrees, .git and \$HOME untouched"
    fi
fi

# --- Lint tasks against fixtures and this repo ---------------------------------
echo "Lint: fail on findings and on a broken linter, pass clean input"
mkfix() {  # <dir> bad|clean
    local d="$1" kind="$2"
    mkdir -p "$d/private_dot_config/nvim/lua" "$d/.github/workflows" "$d/scripts" "$d/docs"
    cp "$REPO/.mise.toml" "$d/.mise.toml"
    cp "$REPO/scripts/check-doc-references.py" "$d/scripts/"
    cp "$REPO/justfile" "$d/justfile"
    mkdir -p "$d/private_dot_config/just"
    cp "$REPO"/private_dot_config/just/*.just "$d/private_dot_config/just/"
    printf '#!/bin/sh\necho "ok"\n' >"$d/ok.sh"
    printf 'local M = {}\nreturn M\n' >"$d/private_dot_config/nvim/lua/ok.lua"
    printf 'on: push\njobs:\n  j:\n    runs-on: ubuntu-latest\n    steps:\n      - run: "true"\n' \
        >"$d/.github/workflows/ok.yml"
    printf '# Docs\n\nSee [the readme](./README.md).\n' >"$d/docs/README.md"
    if [ "$kind" = bad ]; then
        # shellcheck disable=SC2016 # the planted script's findings are the point
        printf '#!/bin/sh\nf() { local x=$(false); echo $x; }\nf\n' >"$d/zz-fixture.sh"
        printf 'local zz_fixture_unused = 1\n' >"$d/private_dot_config/nvim/lua/zz_fixture.lua"
        printf 'on: push\njobs:\n  j:\n    runs-on: ubuntu-latest\n    zz_fixture_bogus: 1\n    steps:\n      - run: "true"\n' \
            >"$d/.github/workflows/zz-fixture.yml"
        printf '# Fixture\n\nSee [missing](./zz-fixture-missing.md).\n' >"$d/docs/zz-fixture.md"
    fi
    git -C "$d" init -q && git -C "$d" add -A
}
mkfix "$WORK/bad" bad
mkfix "$WORK/clean" clean

available=""; missing=""
check_lint() {  # <task> <tool> <marker in the bad fixture's output>
    local t="$1" tool="$2" marker="$3" out rc stub="$WORK/stub-$2"
    local msg="$tool is missing or cannot run"

    # Broken tool: a stub that fails --version. The empty data dir keeps a
    # mise-installed copy from shadowing it.
    mkdir -p "$stub"
    printf '#!/bin/sh\necho "MISE-TASKS-STUB broken %s" >&2\nexit 97\n' "$tool" >"$stub/$tool"
    chmod +x "$stub/$tool"
    out=$(run_mise "$WORK/clean" "$WORK/mise/state" "$EMPTY_DATA" "$stub:$PATH" run "$t"); rc=$?
    if ! grep -q "MISE-TASKS-STUB broken $tool" <<<"$out" && [ $rc -eq 0 ]; then
        log_fail "$t: exit 0 and the broken $tool stub never ran; the task checks nothing"
    elif [ $rc -ne 0 ] && grep -q "$msg" <<<"$out"; then
        log_pass "$t: a broken $tool fails the task (rc=$rc) and names it"
    else
        log_fail "$t: with a broken $tool, rc=$rc and no '$msg': $(grep -v '^\[' <<<"$out" | head -1)"
    fi

    out=$(run_task "$WORK/clean" "$t"); rc=$?
    if grep -q "$msg" <<<"$out"; then
        skip_or_fail "$tool" "$t: $tool is missing or cannot run here; fixture and repo checks not run"
        missing="$missing $tool"
        return
    fi
    available="$available $tool"
    if [ $rc -eq 0 ]; then log_pass "$t: clean fixture passes"
    else log_fail "$t: clean fixture rc=$rc: $(grep -v '^\[' <<<"$out" | head -3 | tr '\n' ' ')"; fi

    out=$(run_task "$WORK/bad" "$t"); rc=$?
    if [ $rc -ne 0 ] && grep -q "$marker" <<<"$out"; then
        log_pass "$t: planted finding fails the task (rc=$rc) and is named ($marker)"
    elif [ $rc -ne 0 ]; then
        log_fail "$t: rc=$rc but $marker never named; it errored before checking: $(grep -v '^\[' <<<"$out" | head -1)"
    else
        log_fail "$t: exit 0 on a planted finding ($marker)"
    fi

    out=$(run_task "$REPO" "$t"); rc=$?
    if [ $rc -eq 0 ]; then log_pass "$t: this repo passes"
    else log_fail "$t: this repo fails (rc=$rc):"; grep -v '^\[' <<<"$out" | head -15 | sed 's/^/      /'; fi
}
check_lint lint:shell   shellcheck zz-fixture.sh
check_lint lint:lua     luacheck   zz_fixture.lua
check_lint lint:actions actionlint zz-fixture.yml
check_lint lint:docs    python3    zz-fixture-missing.md

echo "Lint: the aggregate runs every linter and fails if any fails"
out=$(run_task "$WORK/bad" lint); rc=$?
lint_can_fail=0
if [ $rc -eq 0 ]; then
    log_fail "lint: exit 0 on the bad fixture (a linter failure was swallowed)"
else
    lint_can_fail=1
    unseen=""
    for pair in shellcheck:zz-fixture.sh luacheck:zz_fixture.lua actionlint:zz-fixture.yml python3:zz-fixture-missing.md; do
        case " $available " in *" ${pair%%:*} "*) grep -q "${pair#*:}" <<<"$out" || unseen="$unseen ${pair#*:}" ;; esac
    done
    if [ -z "$unseen" ]; then log_pass "lint: bad fixture fails (rc=$rc) with every available linter's finding"
    else log_fail "lint: rc=$rc but these findings never appeared (it stopped early?):$unseen"; fi
fi
if [ -n "$missing" ]; then
    log_skip "lint on this repo: needs every linter; missing or broken:$missing"
elif [ "$lint_can_fail" -eq 0 ]; then
    log_fail "lint on this repo: not run; an exit 0 from a task that cannot fail proves nothing"
else
    out=$(run_task "$REPO" lint); rc=$?
    if [ $rc -eq 0 ]; then log_pass "lint: this repo passes"
    else log_fail "lint: this repo fails (rc=$rc)"; fi
fi

# --- just lint* recipes run the mise tasks (#439) -------------------------------
echo "Just: each lint* recipe reaches mise and fails when its tool is gone"
if [ -z "$JUST_BIN" ]; then
    skip_or_fail just "just is not installed; recipe behaviour not run (the delegation is checked statically above)"
else
    STUB_MISE="$WORK/stub-mise"; mkdir -p "$STUB_MISE"
    printf '#!/bin/sh\necho "MISE-TASKS-STUB mise $*"\n' >"$STUB_MISE/mise"
    chmod +x "$STUB_MISE/mise"
    # recipe : mise task : tool the task needs : name the bad fixture plants
    for row in "lint-shell lint:shell shellcheck zz-fixture.sh" \
        "lint-lua lint:lua luacheck zz_fixture.lua" \
        "lint-actions lint:actions actionlint zz-fixture.yml" \
        "lint-docs lint:docs python3 zz-fixture-missing.md" \
        "lint lint shellcheck zz-fixture.sh"; do
        read -r recipe task tool marker <<<"$row"

        # Delegation: with mise stubbed, the recipe's whole effect is this call.
        out=$(run_just "$WORK/clean/docs" "$WORK/mise/state" "$EMPTY_DATA" "$STUB_MISE:$PATH" "$recipe"); rc=$?
        if [ $rc -eq 0 ] && grep -qx "MISE-TASKS-STUB mise run $task" <<<"$out"; then
            log_pass "just $recipe: runs \`mise run $task\`"
        else
            log_fail "just $recipe: rc=$rc and no \`mise run $task\` call: $(grep -v '^\[' <<<"$out" | head -2 | tr '\n' ' ')"
        fi

        # Missing tool: absent from PATH (and from mise's installs), not just
        # broken. The old recipes printed "not installed" and exited 0 here.
        out=$(run_just "$WORK/clean" "$WORK/mise/state" "$EMPTY_DATA" "$(path_without "$tool")" "$recipe"); rc=$?
        if [ $rc -ne 0 ] && grep -q "$tool is missing or cannot run" <<<"$out"; then
            log_pass "just $recipe: without $tool it fails (rc=$rc) and names it"
        else
            log_fail "just $recipe: without $tool, rc=$rc and no '$tool is missing or cannot run': $(grep -v '^\[' <<<"$out" | head -2 | tr '\n' ' ')"
        fi

        # Planted finding, when the linter exists here.
        case " $available " in
            *" $tool "*)
                out=$(run_just "$WORK/bad" "$WORK/mise/state" "$REAL_MISE_DATA" "$PATH" "$recipe"); rc=$?
                if [ $rc -ne 0 ] && grep -q "$marker" <<<"$out"; then
                    log_pass "just $recipe: planted finding fails (rc=$rc) and is named ($marker)"
                else
                    log_fail "just $recipe: rc=$rc on the bad fixture, $marker not named: $(grep -v '^\[' <<<"$out" | head -2 | tr '\n' ' ')"
                fi
                ;;
            *) log_skip "just $recipe: $tool is not usable here; planted-finding check not run" ;;
        esac
    done
fi

echo
echo "passed=$pass_count failed=$fail_count skipped=$skip_count"
[ "$fail_count" -eq 0 ]
