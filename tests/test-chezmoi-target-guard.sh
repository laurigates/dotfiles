#!/usr/bin/env bash
# Regression test for exact_dot_claude/hooks/executable_chezmoi-target-guard.sh.
#
# What is being protected
# ------------------------
# ~/.claude/rules/, ~/.claude/skills/ and ~/.claude/CLAUDE.md are rendered from
# the chezmoi source. A write straight into the target is either clobbered by
# the next apply (managed path) or loads forever without reaching version
# control (new unmanaged file). The file tools (Write/Edit/...) were blocked
# first; shell writes were the remaining gap. Pinned here:
#   1. Shell writes into those trees are BLOCKED (exit 2): heredoc redirect,
#      tee, cp into the directory, sed -i, rm of a managed rule, and the ~,
#      $HOME, ${HOME} and absolute spellings of the path.
#   2. Read-only shell commands, writes to .chezmoiignore'd paths, writes
#      outside the guarded trees, rm of an unmanaged stray, and paths that only
#      appear inside quoted prose all pass (exit 0).
#   3. The printed source path follows chezmoi's spelling of the parent
#      directory (exact_rules/), for the file tools and Bash alike.
#
# Isolation: a stub `chezmoi` is put first on PATH and HOME points at a temp
# dir, so no real chezmoi state or home file is read.

# shellcheck disable=SC2016 # the commands under test carry literal $HOME text
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOOK="${HOOK:-$REPO_DIR/exact_dot_claude/hooks/executable_chezmoi-target-guard.sh}"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
pass_count=0; fail_count=0

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
[ -f "$HOOK" ] || { echo "FAIL: hook not found: $HOOK"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
STUB_DIR="$WORK/bin"
FAKE_HOME="$WORK/home"
SRC="$WORK/src"
mkdir -p "$STUB_DIR" "$FAKE_HOME/.claude/rules" "$FAKE_HOME/.claude/skills/notebooklm" "$FAKE_HOME/.claude/plans"
printf 'managed\n' >"$FAKE_HOME/.claude/rules/managed.md"
printf 'stray\n' >"$FAKE_HOME/.claude/rules/stray.md"

# target<TAB>source for every path the stub reports as managed.
C="$FAKE_HOME/.claude"
S="$SRC/exact_dot_claude"
printf '%s\t%s\n' \
    "$C" "$S" \
    "$C/rules" "$S/exact_rules" \
    "$C/rules/managed.md" "$S/exact_rules/managed.md" \
    "$C/skills" "$S/skills" \
    "$C/CLAUDE.md" "$S/CLAUDE.md" >"$WORK/managed"

cat >"$STUB_DIR/chezmoi" <<EOF
#!/usr/bin/env bash
case "\$1" in
    ignored) printf '%s\n' .claude/skills/notebooklm .claude/plans ;;
    source-path)
        out=\$(awk -F '\t' -v p="\$2" '\$1 == p { print \$2; found = 1 } END { exit !found }' "$WORK/managed") || exit 1
        printf '%s\n' "\$out"
        ;;
    unmanaged) echo "something" ;;
esac
exit 0
EOF
chmod +x "$STUB_DIR/chezmoi"
PATH="$STUB_DIR:$PATH" command -v chezmoi | grep -q "^$STUB_DIR/" ||
    { echo "FAIL: chezmoi stub is not first on PATH"; exit 1; }

run_hook() {
    HOME="$FAKE_HOME" PATH="$STUB_DIR:$PATH" bash "$HOOK" >"$WORK/out" 2>&1
    echo $?
}

report() {
    local desc="$1" expected="$2" want="$3" actual="$4"
    if [ "$actual" = "$expected" ] && { [ -z "$want" ] || grep -qF -- "$want" "$WORK/out"; }; then
        echo "${GREEN}PASS${NC}: $desc (exit $actual)"
        pass_count=$((pass_count + 1))
    else
        echo "${RED}FAIL${NC}: $desc — expected exit $expected${want:+ and output containing '$want'}, got $actual"
        sed 's/^/    /' "$WORK/out"
        fail_count=$((fail_count + 1))
    fi
}

# check_bash <desc> <command> <expected-exit> [expected-output-substring]
check_bash() {
    local actual
    actual=$(jq -n --arg cmd "$2" --arg cwd "$WORK" '{tool_name:"Bash", cwd:$cwd, tool_input:{command:$cmd}}' | run_hook)
    report "$1" "$3" "${4:-}" "$actual"
}

# check_write <desc> <file_path> <expected-exit> [expected-output-substring]
check_write() {
    local actual
    actual=$(jq -n --arg p "$2" '{tool_name:"Write", tool_input:{file_path:$p, content:"x"}}' | run_hook)
    report "$1" "$3" "${4:-}" "$actual"
}

# --- 1. shell writes into the guarded trees: BLOCKED -----------------------
check_bash "heredoc redirect creating a new rule is BLOCKED, source path uses exact_rules/" \
    "cat > ~/.claude/rules/new.md <<'EOF'
# New rule
EOF" 2 "$S/exact_rules/new.md"

check_bash "tee -a into a managed rule (\$HOME spelling) is BLOCKED" \
    'echo extra | tee -a "$HOME/.claude/rules/managed.md" >/dev/null' 2 "$S/exact_rules/managed.md"

check_bash "cp into the rules directory is BLOCKED" \
    'cp /tmp/x.md ~/.claude/rules/' 2

check_bash "sed -i on a managed rule (absolute spelling) is BLOCKED" \
    "sed -i '' -e s/a/b/ $FAKE_HOME/.claude/rules/managed.md" 2

check_bash "rm of a managed rule is BLOCKED and points at git rm + apply" \
    'rm -f ~/.claude/rules/managed.md' 2 "git rm $S/exact_rules/managed.md"

check_bash "redirect into CLAUDE.md (\${HOME} spelling) is BLOCKED" \
    'printf x >> ${HOME}/.claude/CLAUDE.md' 2

check_bash "mv into a new skill directory is BLOCKED" \
    'mv /tmp/SKILL.md ~/.claude/skills/new-skill/SKILL.md' 2 "$S/skills/new-skill/SKILL.md"

check_bash "a write after a read in a compound command is BLOCKED" \
    'cat ~/.claude/rules/managed.md && echo x > ~/.claude/rules/managed.md' 2

# --- 2. reads, ignored paths, out-of-scope writes, prose: ALLOWED ----------
check_bash "read-only commands on the guarded trees are ALLOWED" \
    'cat ~/.claude/rules/managed.md; grep -r foo ~/.claude/rules | head; ls ~/.claude/skills; diff /tmp/a ~/.claude/CLAUDE.md 2>&1' 0

check_bash "copying a rule OUT of the target is ALLOWED" \
    'cp ~/.claude/rules/managed.md /tmp/' 0

check_bash "write into an ignored skill (skills/notebooklm) is ALLOWED" \
    'echo x > ~/.claude/skills/notebooklm/SKILL.md' 0

check_bash "write outside the guarded trees (~/.claude/plans) is ALLOWED" \
    'echo x > ~/.claude/plans/p.md' 0

check_bash "rm of an unmanaged stray rule is ALLOWED" \
    'rm ~/.claude/rules/stray.md' 0

check_bash "a target path inside quoted prose is ALLOWED" \
    'gh pr create --body "never run echo x > ~/.claude/rules/foo.md"' 0

check_bash "a target path inside a heredoc body is ALLOWED" \
    "cat > /tmp/notes.md <<'EOF'
echo x > ~/.claude/rules/foo.md
EOF" 0

# --- 3. file tools (pre-existing behaviour, with the exact_rules/ spelling) -
check_write "Write of a new rule is BLOCKED, source path uses exact_rules/" \
    "$FAKE_HOME/.claude/rules/new.md" 2 "$S/exact_rules/new.md"

check_write "Write of a managed rule is BLOCKED" \
    "$FAKE_HOME/.claude/rules/managed.md" 2 "$S/exact_rules/managed.md"

check_write "Write into an ignored skill is ALLOWED" \
    "$FAKE_HOME/.claude/skills/notebooklm/SKILL.md" 0

echo ""
echo "Passed: $pass_count, Failed: $fail_count"
[ "$fail_count" -eq 0 ]
