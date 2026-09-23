#!/usr/bin/env bash
# Guard: no per-repo Renovate runner while the account-wide App owns this repo.
#
# Renovate for this repo runs from the account-wide runner (the
# `laurigates-renovate` GitHub App). A workflow here that also runs Renovate
# adds a second identity. Each identity keeps its own Dependency Dashboard
# (#373, #379) and treats the other's commits on a shared renovate/* branch as
# manual edits, so neither opens that branch's PR. Scaffolds and the
# configure-workflows skill still emit a per-repo renovate.yml, so the second
# runner can come back without anyone deciding to add it.
#
# Runner shapes detected in `uses:` values of .github/workflows/*.y{a,}ml:
#   - renovatebot/github-action   the self-hosted action
#   - reusable-renovate.yml       a caller of the org reusable workflow
# Other shapes (a renovate container image, `npx renovate`) are not detected.
#
# The patterns are control-tested against planted fixtures on every run, so a
# pattern that stops matching fails here instead of reporting a clean tree.
#
# Usage: tests/test-renovate-single-owner.sh [workflows-dir]

set -uo pipefail

if [ "$#" -gt 0 ]; then
    WORKFLOWS_DIR="$1"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$(dirname "$SCRIPT_DIR")" || exit 1
    WORKFLOWS_DIR=".github/workflows"
fi
# A missing directory would scan nothing and pass.
[ -d "$WORKFLOWS_DIR" ] || { echo "FAIL: not a directory: $WORKFLOWS_DIR"; exit 1; }

RUNNER_RE='renovatebot/github-action|reusable-renovate\.ya?ml'
# A `uses:` value naming a runner. `^[^#]*` skips commented-out lines, and the
# value stops at whitespace, a quote or `#`, so names and trailing comments that
# mention a runner are not flagged.
USES_RE="^[^#]*uses:[[:space:]]*['\"]?[^'\"#[:space:]]*(${RUNNER_RE})"

# Print file:line:text for each `uses:` line that runs Renovate.
# Exit 0 = found, 1 = none, 2 = grep error.
scan() {
    local dir="$1" files
    shopt -s nullglob
    files=("$dir"/*.yml "$dir"/*.yaml)
    shopt -u nullglob
    [ "${#files[@]}" -gt 0 ] || return 1
    grep -HnE "$USES_RE" "${files[@]}"
}

fail=0

# --- Control: the patterns still match the known runner shapes -----------
FIXTURES=$(mktemp -d)
trap 'rm -rf "$FIXTURES"' EXIT

cat >"$FIXTURES/reusable-caller.yml" <<'EOF'
jobs:
  renovate:
    uses: laurigates/.github/.github/workflows/reusable-renovate.yml@main
EOF
cat >"$FIXTURES/action.yaml" <<'EOF'
jobs:
  renovate:
    runs-on: ubuntu-latest
    steps:
      - uses: renovatebot/github-action@v46.1.15
EOF
cat >"$FIXTURES/validator-only.yml" <<'EOF'
# Validates renovate.json5; does not run Renovate.
# uses: renovatebot/github-action@v46.1.15  (commented out)
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - run: npx --yes --package renovate -- renovate-config-validator renovate.json5
EOF
cat >"$FIXTURES/name-mention.yml" <<'EOF'
jobs:
  lint:
    name: Validate renovatebot/github-action inputs
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5  # reusable-renovate.yml is called elsewhere
EOF

control=$(scan "$FIXTURES")
for f in reusable-caller.yml action.yaml; do
    if ! grep -q "/$f:" <<<"$control"; then
        echo "FAIL: control fixture $f was not flagged; the runner patterns no longer match"
        fail=1
    fi
done
for f in validator-only.yml name-mention.yml; do
    if grep -q "/$f:" <<<"$control"; then
        echo "FAIL: control fixture $f was flagged; the patterns match non-runner lines"
        fail=1
    fi
done

# --- The real tree --------------------------------------------------------
hits=$(scan "$WORKFLOWS_DIR")
case $? in
    0)
        echo "FAIL: per-repo Renovate runner found in $WORKFLOWS_DIR:"
        printf '  %s\n' "${hits//$'\n'/$'\n'  }"
        echo "Renovate for this repo runs from the account-wide App; a second runner"
        echo "contends for its renovate/* branches (#373, #379). Remove the workflow."
        fail=1
        ;;
    1) ;;
    *)
        echo "FAIL: scanning $WORKFLOWS_DIR failed"
        fail=1
        ;;
esac

[ "$fail" -eq 0 ] && echo "PASS: no per-repo Renovate runner in $WORKFLOWS_DIR"
exit "$fail"
