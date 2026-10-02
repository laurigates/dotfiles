#!/usr/bin/env bash
# Regression test for private_dot_pi/agent/modify_settings.json.tmpl.
#
# What is being protected
# ------------------------
# pi rewrites ~/.pi/agent/settings.json at runtime (lastChangelogVersion,
# defaultModel/defaultProvider on /model, `packages` on `pi install`), so the
# file is managed with a modify_ script that deep-merges a small overlay. This
# test pins the merge contract:
#   1. An empty/missing target yields the full overlay.
#   2. Keys pi owns (defaultModel, lastChangelogVersion, ...) pass through.
#   3. `packages` is a UNION keyed by package identity (npm name without the
#      version, as pi itself identifies packages): managed entries replace a
#      stale pin of the same package; unmanaged packages — including the object
#      form with resource filters — survive.
#   4. The overlay wins on conflicting scalars (searxng.url).
#   5. The merge is idempotent (a second apply is a no-op).
#
# The template is rendered with the real chezmoi data from this checkout, so
# the SearXNG URL asserted below is derived from .chezmoidata.toml, not copied.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE="$REPO_DIR/private_dot_pi/agent/modify_settings.json.tmpl"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
pass_count=0; fail_count=0

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
command -v chezmoi >/dev/null 2>&1 || { echo "SKIP: chezmoi not installed"; exit 0; }
[ -f "$TEMPLATE" ] || { echo "FAIL: template not found: $TEMPLATE"; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

SCRIPT="$WORK/modify.sh"
chezmoi --source "$REPO_DIR" execute-template <"$TEMPLATE" >"$SCRIPT" || {
    echo "FAIL: template did not render"; exit 1;
}
port=$(chezmoi --source "$REPO_DIR" execute-template '{{ .searxng.port }}')
want_url="http://127.0.0.1:$port"

check() {
    local name="$1" json="$2" filter="$3"
    if jq -e "$filter" >/dev/null 2>&1 <<<"$json"; then
        echo "${GREEN}PASS${NC}: $name"; pass_count=$((pass_count + 1))
    else
        echo "${RED}FAIL${NC}: $name"; echo "  filter: $filter"; echo "  got: $json"
        fail_count=$((fail_count + 1))
    fi
}

# 1. Empty target.
out=$(bash "$SCRIPT" </dev/null) || { echo "FAIL: script errored on empty input"; exit 1; }
check "empty target: searxng.url from chezmoi data" "$out" ".searxng.url == \"$want_url\""
check "empty target: managed packages present" "$out" \
    '[.packages[] | select(type == "string" and (startswith("npm:pi-lean-search@") or startswith("npm:pi-smart-fetch@")))] | length == 2'

# 2-4. Live file with pi-owned keys, a stale pin, superseded packages, and unmanaged packages.
live='{
  "defaultProvider": "ollama",
  "defaultModel": "qwen3-coder:30b",
  "lastChangelogVersion": "0.84.1",
  "searxng": { "url": "http://stale:1234", "extra": true },
  "packages": [
    "npm:@ollama/pi-web-search",
    "npm:pi-smart-fetch@0.1.7",
    "npm:some-other-pkg@2.0.0",
    { "source": "npm:@scope/tools@1.0.0", "skills": [] },
    "git:github.com/example/pi-thing@v1"
  ]
}'
out=$(bash "$SCRIPT" <<<"$live")
check "pi-owned keys pass through" "$out" \
    '.defaultProvider == "ollama" and .defaultModel == "qwen3-coder:30b" and .lastChangelogVersion == "0.84.1"'
check "overlay wins on searxng.url" "$out" ".searxng.url == \"$want_url\""
check "nested unmanaged key survives deep merge" "$out" '.searxng.extra == true'
check "stale pin replaced, not duplicated" "$out" \
    '[.packages[] | select(type == "string" and startswith("npm:pi-smart-fetch@"))] | length == 1 and (.[0] != "npm:pi-smart-fetch@0.1.7")'
check "superseded package @ollama/pi-web-search pruned" "$out" \
    'any(.packages[]; (if type == "object" then .source else . end) | startswith("npm:@ollama/pi-web-search")) | not'
check "unmanaged string packages survive" "$out" \
    '(.packages | index("npm:some-other-pkg@2.0.0")) != null and (.packages | index("git:github.com/example/pi-thing@v1")) != null'
check "unmanaged object-form package survives" "$out" \
    'any(.packages[]; type == "object" and .source == "npm:@scope/tools@1.0.0" and .skills == [])'

# 5. Idempotence.
again=$(bash "$SCRIPT" <<<"$out")
if [ "$(jq -S . <<<"$out")" = "$(jq -S . <<<"$again")" ]; then
    echo "${GREEN}PASS${NC}: idempotent"; pass_count=$((pass_count + 1))
else
    echo "${RED}FAIL${NC}: second run changed the output"; fail_count=$((fail_count + 1))
fi

echo
echo "pi settings modify_: $pass_count passed, $fail_count failed"
[ "$fail_count" -eq 0 ]
