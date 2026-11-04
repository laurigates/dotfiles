#!/usr/bin/env bash
# Mechanical validation of the user-global Claude Code config sources (#513).
#
# What is being protected
# ------------------------
# exact_dot_claude/skills/*/SKILL.md and exact_dot_claude/modify_settings.json
# become ~/.claude/skills/ and ~/.claude/settings.json. These checks used to
# live in the prompt of .github/workflows/claude-config-validation.yml, a
# manually dispatched 50-turn LLM run that never ran. They are mechanical, so a
# script gives the same answer on every PR:
#
#   1. Every SKILL.md has a frontmatter block with a non-empty `name` and
#      `description`, and an optional `model` drawn from the values Claude Code
#      accepts: opus, sonnet, haiku, fable, inherit, or a full claude-* ID.
#   2. modify_settings.json (a bash modify_ script: chezmoi pipes the current
#      target on stdin and takes stdout as the new target) exits 0 and prints
#      valid, non-empty JSON for an empty-object target and for an empty one
#      (chezmoi passes empty stdin when ~/.claude/settings.json is missing).
#   3. Controls: each check is run on planted bad input and must fail there,
#      and on planted good input and must pass, so a checker that cannot fail
#      (or cannot pass) is caught.
#
# Frontmatter is cut out with awk and queried with `yq -r '.<key> // ""'`, the
# subset that mikefarah/yq (ubuntu-latest, the aqua package on dev machines)
# and kislyuk/yq (the Python jq wrapper some Linux distros ship as yq) both
# accept. `yq --front-matter=extract` exists only in mikefarah/yq.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_DIR/exact_dot_claude/skills"
SETTINGS_SCRIPT="$REPO_DIR/exact_dot_claude/modify_settings.json"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
pass_count=0; fail_count=0

pass() { echo "${GREEN}PASS${NC}: $1"; pass_count=$((pass_count + 1)); }
fail() { echo "${RED}FAIL${NC}: $1"; fail_count=$((fail_count + 1)); }

for tool in jq yq awk; do
    command -v "$tool" >/dev/null 2>&1 || { echo "FAIL: $tool not installed"; exit 1; }
done

MODEL_RE='^(opus|sonnet|haiku|fable|inherit|claude-.+)$'

# frontmatter FILE — print the YAML between a leading `---` line and the next
# `---` line. Exits 1 when the file does not open with a frontmatter block.
frontmatter() {
    awk 'NR == 1 { if ($0 != "---") exit 1; open = 1; next }
         open && $0 == "---" { closed = 1; exit }
         open { print }
         END { if (!closed) exit 1 }' "$1"
}

# fm_get YAML KEY — the key's value, or "" when absent or null.
fm_get() { yq -r ".$2 // \"\"" <<<"$1"; }

# check_skills DIR — validate every DIR/*/SKILL.md. Prints one line per
# finding; exits non-zero when any skill fails or none is found.
check_skills() {
    local dir="$1" rc=0 found=0 f rel fm key val model
    for f in "$dir"/*/SKILL.md; do
        [ -f "$f" ] || continue
        found=$((found + 1))
        rel="${f#"$dir"/}"
        if ! fm=$(frontmatter "$f"); then
            echo "  $rel: no frontmatter block (--- ... ---) at the top"; rc=1; continue
        fi
        if ! yq -r '.' <<<"$fm" >/dev/null 2>&1; then
            echo "  $rel: frontmatter is not valid YAML"; rc=1; continue
        fi
        for key in name description; do
            val=$(fm_get "$fm" "$key")
            if [ -z "${val//[[:space:]]/}" ]; then
                echo "  $rel: frontmatter '$key' is missing or empty"; rc=1
            fi
        done
        model=$(fm_get "$fm" model)
        if [ -n "$model" ] && ! [[ "$model" =~ $MODEL_RE ]]; then
            echo "  $rel: model '$model' is not one of opus|sonnet|haiku|fable|inherit|claude-*"; rc=1
        fi
    done
    if [ "$found" -eq 0 ]; then
        echo "  no */SKILL.md under $dir"; rc=1
    fi
    return "$rc"
}

# check_settings SCRIPT — run the modify_ script on `{}` and on empty stdin;
# each run must exit 0 and print valid, non-empty JSON.
check_settings() {
    local script="$1" rc=0 input label out
    for input in '{}' ''; do
        label="${input:-<empty>}"
        if ! out=$(printf '%s' "$input" | bash "$script" 2>&1); then
            echo "  target $label: script exited non-zero: $out"; rc=1; continue
        fi
        if [ -z "$out" ]; then
            echo "  target $label: script printed nothing"; rc=1; continue
        fi
        if ! jq empty <<<"$out" 2>/dev/null; then
            echo "  target $label: output is not valid JSON"; rc=1
        fi
    done
    return "$rc"
}

# expect NAME WANT CMD... — run a check, compare its exit status to WANT
# (pass|fail), and print its findings.
expect() {
    local name="$1" want="$2" out status
    shift 2
    out=$("$@" 2>&1); status=$?
    if { [ "$want" = pass ] && [ "$status" -eq 0 ]; } || { [ "$want" = fail ] && [ "$status" -ne 0 ]; }; then
        pass "$name"
        [ "$want" = fail ] && [ -n "$out" ] && echo "$out"
    else
        fail "$name (expected $want, exit $status)"
        [ -n "$out" ] && echo "$out"
    fi
    return 0
}

# --- Real tree ---------------------------------------------------------------

expect "skills: every SKILL.md has name, description, and an accepted model" pass check_skills "$SKILLS_DIR"
expect "settings: modify_settings.json prints valid JSON" pass check_settings "$SETTINGS_SCRIPT"

# --- Controls ----------------------------------------------------------------

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

plant() { # plant CASE FRONTMATTER — write $WORK/CASE/s/SKILL.md
    mkdir -p "$WORK/$1/s"
    printf -- '---\n%s\n---\n\nBody.\n' "$2" >"$WORK/$1/s/SKILL.md"
}

plant good $'name: good\ndescription: A planted valid skill.\nmodel: sonnet'
plant good-id $'name: good-id\ndescription: |\n  Block-scalar description.\nmodel: claude-opus-5-5'
plant empty-desc $'name: empty-desc\ndescription: ""'
plant missing-name $'description: No name here.'
plant bad-model $'name: bad-model\ndescription: Wrong model.\nmodel: gpt-4'
mkdir -p "$WORK/no-fm/s" && printf 'name: x\ndescription: y\n' >"$WORK/no-fm/s/SKILL.md"
mkdir -p "$WORK/none"

expect "control: valid skill with model alias passes" pass check_skills "$WORK/good"
expect "control: valid skill with block description and claude-* ID passes" pass check_skills "$WORK/good-id"
expect "control: empty description fails" fail check_skills "$WORK/empty-desc"
expect "control: missing name fails" fail check_skills "$WORK/missing-name"
expect "control: model gpt-4 fails" fail check_skills "$WORK/bad-model"
expect "control: SKILL.md without frontmatter fails" fail check_skills "$WORK/no-fm"
expect "control: a dir with no skills fails" fail check_skills "$WORK/none"

printf '#!/usr/bin/env bash\necho "{not json"\n' >"$WORK/bad-json.sh"
printf '#!/usr/bin/env bash\ncat >/dev/null\n' >"$WORK/no-output.sh"
printf '#!/usr/bin/env bash\necho "{}"; exit 3\n' >"$WORK/exit-3.sh"
printf '#!/usr/bin/env bash\ncat >/dev/null; echo "{\\"ok\\": true}"\n' >"$WORK/ok.sh"

expect "control: modify script printing valid JSON passes" pass check_settings "$WORK/ok.sh"
expect "control: modify script printing invalid JSON fails" fail check_settings "$WORK/bad-json.sh"
expect "control: modify script printing nothing fails" fail check_settings "$WORK/no-output.sh"
expect "control: modify script exiting non-zero fails" fail check_settings "$WORK/exit-3.sh"

echo
echo "claude config: $pass_count passed, $fail_count failed"
[ "$fail_count" -eq 0 ]
