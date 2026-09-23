#!/usr/bin/env bash
# Authenticate pre-commit hook installs against the GitHub REST API (#434).
#
# StyLua's stylua-github hook is built by release-gitter, which lists releases
# with a bare requests.get and reads no token variable, so exporting
# GITHUB_TOKEN does nothing for it. requests does read $NETRC. This script
# writes the job token into a netrc outside the workspace and exports NETRC to
# every later step. Without it, each hook install is an anonymous call against
# the runner IP's 60/h limit, which hosted runners share.
#
# It then checks that GitHub accepted the credential. /rate_limit reports a
# core limit of 60 for anonymous callers and does not count against the limit,
# so a limit above 60 shows the netrc's Basic auth was accepted. A rejected
# token does not produce an HTTP error here (an invalid one returned 200 with
# limit 60), so the limit is the check. On failure the step stops the job
# instead of letting hook installs fall back to anonymous calls.
#
# Workflow usage:
#   - run: .github/scripts/github-api-netrc.sh
#     env:
#       GITHUB_TOKEN: ${{ github.token }}
set -euo pipefail

: "${GITHUB_TOKEN:?set GITHUB_TOKEN to the job token in the step env}"
: "${RUNNER_TEMP:?RUNNER_TEMP is unset; run this inside GitHub Actions}"
: "${GITHUB_ENV:?GITHUB_ENV is unset; run this inside GitHub Actions}"

netrc="$RUNNER_TEMP/github-api.netrc"
(
  umask 077
  # printf is a builtin, so the token never appears in a process argv.
  printf 'machine api.github.com login x-access-token password %s\n' "$GITHUB_TOKEN" >"$netrc"
)
echo "NETRC=$netrc" >>"$GITHUB_ENV"

if ! response=$(curl -sS --fail --netrc-file "$netrc" https://api.github.com/rate_limit); then
  echo "::error::GET api.github.com/rate_limit failed; cannot confirm the netrc credential (#434)" >&2
  exit 1
fi
core=$(jq -c '.resources.core' <<<"$response")
echo "api.github.com core rate limit via netrc: $core"
if ! jq -e '.limit > 60' <<<"$core" >/dev/null; then
  echo "::error::api.github.com did not authenticate the netrc credential (core limit <= 60); pre-commit hook installs would run anonymously (#434)" >&2
  exit 1
fi
