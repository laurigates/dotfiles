#!/usr/bin/env bash
# migrate-api-tokens-to-fnox.sh — one-shot move from ~/.api_tokens to fnox (ADR-0026).
#
# Step 1  Stores every variable assigned in ~/.api_tokens in the OS keychain
#         through fnox. Names already declared in ~/.config/fnox/config.toml
#         (chezmoi-managed) get only a keychain entry; the rest are also
#         recorded in ~/.config/fnox/local.toml (machine-local).
# Step 2  Rewrites the MCP entries in ~/.claude.json that read tokens from the
#         environment:
#           google-dev-knowledge (user scope)  ${VAR} header -> headersHelper
#           podio-mcp (every project's local scope) -> wrapped in `fnox exec`
#
# Values are piped straight into `fnox set` and never printed; output names
# variables only. ~/.api_tokens is left in place: delete it yourself once
# everything works, then rotate the tokens.
#
# Run after `chezmoi apply` has installed ~/.config/fnox/ and `mise install`
# has installed fnox. Close other Claude Code sessions first: they rewrite
# ~/.claude.json and can overwrite step 2.
#
# Usage: scripts/migrate-api-tokens-to-fnox.sh [--dry-run]
# Re-running is safe: values are overwritten, wrapped MCP entries are skipped.

set -euo pipefail

DRY_RUN=0
case "${1:-}" in
  --dry-run) DRY_RUN=1 ;;
  -h | --help) sed -n '2,24p' "$0"; exit 0 ;;
  "") ;;
  *) echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

# Overridable for testing; the defaults are the real locations.
TOKENS_FILE="${API_TOKENS_FILE:-$HOME/.api_tokens}"
FNOX_DIR="${FNOX_CONFIG_DIR:-$HOME/.config/fnox}"
MANAGED="$FNOX_DIR/config.toml"
LOCAL="$FNOX_DIR/local.toml"
CLAUDE_JSON="${CLAUDE_JSON:-$HOME/.claude.json}"

die() { echo "ERROR: $*" >&2; exit 1; }
command -v fnox >/dev/null || die "fnox not on PATH (run: mise install fnox)"
command -v jq >/dev/null || die "jq not on PATH"
[[ -f "$TOKENS_FILE" ]] || die "$TOKENS_FILE not found"
[[ -f "$MANAGED" && -f "$LOCAL" ]] || die "$MANAGED or $LOCAL missing (run: chezmoi apply ~/.config/fnox)"

# ── Step 1: tokens into the keychain ──────────────────────────────────────────
echo "=== STEP 1: ~/.api_tokens -> keychain"
# Preflight: the file must source cleanly under bash, or every later variable
# would read as empty. Output is discarded so no value can be printed.
# shellcheck disable=SC2016  # $1 is expanded by the inner bash, on purpose
env -i HOME="$HOME" PATH="$PATH" bash -ec 'set -a; . "$1"' _ "$TOKENS_FILE" >/dev/null 2>&1 ||
  die "$TOKENS_FILE does not source cleanly under bash (check it with: bash -n $TOKENS_FILE)"

names="$(sed -nE 's/^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=.*/\2/p' "$TOKENS_FILE" | sort -u)"
[[ -n "$names" ]] || die "no assignments found in $TOKENS_FILE"

stored=0
skipped=0
while IFS= read -r name; do
  # Resolve the value the way the shell did: source the file in a clean shell.
  # shellcheck disable=SC2016  # $1/$2 are expanded by the inner bash, on purpose
  value="$(env -i HOME="$HOME" PATH="$PATH" bash -c 'set -a; . "$1" >/dev/null 2>&1; printenv "$2"' _ "$TOKENS_FILE" "$name" || true)"
  if [[ -z "$value" ]]; then
    echo "SKIP $name (empty)"
    skipped=$((skipped + 1))
    continue
  fi
  if grep -qE "^${name}[[:space:]]*=" "$MANAGED"; then where="config.toml"; else where="local.toml"; fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "WOULD STORE $name ($where)"
    continue
  fi
  printf '%s' "$value" | fnox -c "$LOCAL" set "$name" --provider keychain >/dev/null
  if [[ "$where" == "config.toml" ]]; then
    # Declared in the managed file already; drop the duplicate fnox just wrote.
    fnox -c "$LOCAL" remove "$name" >/dev/null
  fi
  echo "STORED $name ($where)"
  stored=$((stored + 1))
done <<<"$names"
unset value
echo "STORED=$stored SKIPPED=$skipped"

# ── Step 2: MCP entries in ~/.claude.json ─────────────────────────────────────
echo "=== STEP 2: MCP entries"
[[ -f "$CLAUDE_JSON" ]] || { echo "SKIP no $CLAUDE_JSON"; exit 0; }
command -v claude >/dev/null || die "claude CLI not on PATH"

# Each rewrite is a remove followed by an add; keep a copy to restore from if an
# add fails half way.
if [[ "$DRY_RUN" -eq 0 ]]; then
  backup="$CLAUDE_JSON.pre-fnox.$(date +%Y%m%d%H%M%S)"
  (umask 077 && cp "$CLAUDE_JSON" "$backup")
  echo "BACKUP $backup"
fi

# google-dev-knowledge: one "${VAR}" header -> headersHelper via fnox-mcp-header.
gdk="$(jq -c '.mcpServers["google-dev-knowledge"] // empty' "$CLAUDE_JSON")"
if [[ -z "$gdk" ]]; then
  echo "SKIP google-dev-knowledge (not configured)"
elif jq -e 'has("headersHelper")' >/dev/null <<<"$gdk"; then
  echo "SKIP google-dev-knowledge (already uses headersHelper)"
elif ! jq -e '.headers // {} | to_entries | any(.value | test("^\\$\\{[A-Za-z_][A-Za-z0-9_]*\\}$"))' >/dev/null <<<"$gdk"; then
  echo "SKIP google-dev-knowledge (no \${VAR} header to convert)"
else
  new="$(jq -c '
    (.headers | to_entries | map(select(.value | test("^\\$\\{[A-Za-z_][A-Za-z0-9_]*\\}$"))) | first) as $h
    | .headersHelper = "fnox-mcp-header \($h.key) \($h.value | ltrimstr("${") | rtrimstr("}"))"
    | .headers |= del(.[$h.key])
    | if .headers == {} then del(.headers) else . end' <<<"$gdk")"
  echo "REWRITE google-dev-knowledge (user): $(jq -r .headersHelper <<<"$new")"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    claude mcp remove -s user google-dev-knowledge >/dev/null
    claude mcp add-json -s user google-dev-knowledge "$new" >/dev/null
  fi
fi

# podio-mcp: wrap each project's entry in `fnox exec --only 'PODIO_*'`. Env
# entries that are ${VAR} references are dropped (fnox now supplies them);
# literal values are kept.
while IFS= read -r dir; do
  [[ -n "$dir" ]] || continue
  entry="$(jq -c --arg d "$dir" '.projects[$d].mcpServers["podio-mcp"]' "$CLAUDE_JSON")"
  if [[ "$(jq -r .command <<<"$entry")" == fnox ]]; then
    echo "SKIP podio-mcp in $dir (already wrapped)"
    continue
  fi
  if [[ ! -d "$dir" ]]; then
    echo "SKIP podio-mcp in $dir (directory gone)"
    continue
  fi
  new="$(jq -c '
    ((.env // {}) | with_entries(select(.value | test("\\$\\{") | not))) as $kept
    | {type: (.type // "stdio"), command: "fnox",
       args: (["exec", "--only", "PODIO_*", "--replace", "--", .command] + (.args // []))}
    | if $kept == {} then . else .env = $kept end' <<<"$entry")"
  dropped="$(jq -r '(.env // {}) | to_entries | map(select(.value | test("\\$\\{")) | .key) | join(",")' <<<"$entry")"
  note=""
  [[ -z "$dropped" ]] || note=" (dropping \${VAR} env entries: $dropped)"
  echo "REWRITE podio-mcp in $dir: $(jq -r '[.command] + .args | join(" ")' <<<"$new")$note"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    (cd "$dir" && claude mcp remove -s local podio-mcp >/dev/null && claude mcp add-json -s local podio-mcp "$new" >/dev/null)
  fi
done < <(jq -r '.projects // {} | to_entries[] | select(.value.mcpServers["podio-mcp"]) | .key' "$CLAUDE_JSON")

echo "=== DONE"
echo "Next: open a new shell, run 'fnox check', start Claude Code and check /mcp."
echo "Then delete ~/.api_tokens and rotate the tokens."
