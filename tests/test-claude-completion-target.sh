#!/usr/bin/env bash
# Regression test: the Claude completion generator writes to $HOME, never to the
# chezmoi source checkout (#542).
#
# What is being protected
# ------------------------
# run_onchange_update-claude-completion.sh.tmpl runs
# scripts/generate-claude-completion-simple.sh on every apply after a Claude CLI
# update. The generator used to write dot_zfunc/_claude inside the source tree,
# so each apply left the checkout with an uncommitted change. A dirty checkout
# turns off the repos-sync-nudge auto-pull (it fast-forwards only when
# `git status --porcelain` is empty) and can stop a later `chezmoi update` at
# `git pull`. The completion now goes straight to ~/.zfunc/_claude, the same
# place run_onchange_02-generate-completions.sh.tmpl writes every other one.
#
# How
# ---
# The generator is copied into a scratch git repo laid out like this one, with a
# tracked placeholder at dot_zfunc/_claude (the old target), and run there with a
# scratch HOME and an executable stub `claude` first on PATH. The test then
# asserts:
#   - the completion lands in $HOME/.zfunc/_claude, holds the stub's commands,
#     and passes `zsh -n`;
#   - `git status --porcelain` of the scratch repo is unchanged, so the old
#     source-tree target was neither modified nor re-created;
#   - CLAUDE_COMPLETION_FILE overrides the output path;
#   - `chezmoi managed` for this repo does not list .zfunc/_claude.
# Running in a scratch repo means a regression fails the test without dirtying
# this checkout.
#
# Usage: tests/test-claude-completion-target.sh
# Requires: git, zsh (the generator validates with `zsh -n`), chezmoi.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
GENERATOR="scripts/generate-claude-completion-simple.sh"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
fail() { echo "${RED}FAIL${NC}: $*"; exit 1; }

for tool in git zsh chezmoi; do
    command -v "$tool" >/dev/null 2>&1 || fail "$tool not installed"
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"
: > "$tmp/chezmoi.toml"

# Stub claude: a top-level help with a Commands block, an mcp subcommand, and no
# config subcommand (an unknown subcommand falls back to the top-level help, as
# the real CLI does).
cat > "$tmp/bin/claude" <<'STUB'
#!/usr/bin/env bash
top_help() {
    cat <<'EOF'
Usage: claude [options] [command] [prompt]

Options:
  -h, --help        Display help for command

Commands:
  stubcmd           Stub command for the completion target test
  mcp               Configure and manage MCP servers
EOF
}
case "$*" in
    --version) echo "0.0.0-stub (Claude Code)" ;;
    "mcp --help")
        cat <<'EOF'
Usage: claude mcp [options] [command]

Commands:
  stubmcp           Stub MCP subcommand
EOF
        ;;
    *) top_help ;;
esac
STUB
chmod +x "$tmp/bin/claude"
PATH="$tmp/bin:$PATH"
[ "$(command -v claude)" = "$tmp/bin/claude" ] || fail "stub claude is not first on PATH"

# Scratch repo with the old source-tree target tracked, so a write to it shows
# up as a modification.
src="$tmp/src"
mkdir -p "$src/scripts" "$src/dot_zfunc"
cp "$REPO_DIR/$GENERATOR" "$src/$GENERATOR"
printf '#compdef claude\n# placeholder\n' > "$src/dot_zfunc/_claude"
git -C "$src" init -q
git -C "$src" add -- scripts dot_zfunc
git -C "$src" -c user.name=test -c user.email=test@example.invalid commit -qm init
before=$(git -C "$src" status --porcelain)

run_generator() {
    env HOME="$tmp/home" PATH="$PATH" "$@" "$src/$GENERATOR" >"$tmp/out" 2>&1
}

# Default target: $HOME/.zfunc/_claude.
run_generator || { cat "$tmp/out"; fail "generator exited non-zero"; }
target="$tmp/home/.zfunc/_claude"
[ -f "$target" ] || { cat "$tmp/out"; fail "no completion written to \$HOME/.zfunc/_claude"; }
grep -qF "'stubcmd:Stub command for the completion target test'" "$target" ||
    fail "completion at $target does not hold the stub's commands"
grep -qF "'stubmcp:Stub MCP subcommand'" "$target" ||
    fail "completion at $target does not hold the stub's mcp subcommands"
zsh -n "$target" || fail "completion at $target fails zsh -n"

after=$(git -C "$src" status --porcelain)
if [ "$before" != "$after" ]; then
    echo "${RED}FAIL${NC}: the generator changed the source checkout (#542). git status --porcelain:"
    printf '%s\n' "$after" | sed 's/^/        /'
    exit 1
fi

# Explicit target.
custom="$tmp/custom/_claude"
run_generator CLAUDE_COMPLETION_FILE="$custom" || { cat "$tmp/out"; fail "generator exited non-zero with CLAUDE_COMPLETION_FILE"; }
[ -f "$custom" ] || fail "CLAUDE_COMPLETION_FILE=$custom was not written"

# chezmoi must not manage the generated file, or apply would fight the generator.
managed=$(chezmoi managed \
    --source="$REPO_DIR" \
    --destination="$tmp/dest" \
    --config="$tmp/chezmoi.toml" \
    --cache="$tmp/cache" \
    --persistent-state="$tmp/chezmoistate.boltdb" \
    --exclude=scripts,externals 2>"$tmp/stderr") || { cat "$tmp/stderr"; fail "chezmoi managed exited non-zero"; }
if grep -qxF ".zfunc/_claude" <<<"$managed"; then
    fail "chezmoi still manages .zfunc/_claude; remove dot_zfunc/_claude from the source (#542)"
fi

echo "${GREEN}PASS${NC}: Claude completion is written to \$HOME/.zfunc/_claude, passes zsh -n," \
    "and leaves the source checkout clean"
