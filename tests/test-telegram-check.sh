#!/usr/bin/env bash
# Regression test: telegram-check diagnoses the Telegram configuration without
# the bot token ever appearing in a command or in its output (#518).
#
# The telegram skill's failure-mode table used to say "verify the chat id with
# curl .../getUpdates". That call needs the token in the URL, and
# hooks-plugin's secret-protection.sh blocks any Bash command that names the
# token variable, so an agent could neither confirm the variables were set nor
# see which chat they point at. telegram-check reads both variables itself and
# reports only what they resolve to.
#
# Every curl call goes to a stub on PATH that returns canned Bot API JSON keyed
# on the method in the URL and on STUB_MODE. A method the scenario does not
# expect exits 97. Nothing reaches the network.
#
# Checked here:
#   Unset    both variables unset, then only the chat id: exit 2, each variable
#            reported set/unset, STATUS=FAIL, and curl is never called.
#   OK       getMe + getChat succeed: exit 0, bot username and chat title/type
#            printed, STATUS=OK.
#   Auth     getMe returns ok:false 401: exit 1, the error code is printed.
#   Chat     getChat returns 400 chat not found: exit 1, the description and a
#            hint pointing at --updates are printed.
#   Curl     curl itself fails and echoes the URL (token included) on stderr:
#            exit 1, the token is redacted from what telegram-check prints.
#   Updates  --updates lists each distinct chat seen in pending updates once.
#   Token    no scenario's stdout or stderr contains the fake token.
#   Hook     when hooks-plugin is installed, secret-protection.sh lets the
#            commands `telegram-check` and `telegram-check --updates` through,
#            and still blocks a command that prints whether the token variable
#            is set (the control: if that stops blocking, this check proves
#            nothing). A bare `[ -n "$..." ]` test no longer blocks at
#            hooks-plugin HEAD, so it cannot serve as the control.
#
# Usage: tests/test-telegram-check.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT="$REPO_DIR/dot_local/bin/executable_telegram-check"
MARKETPLACE_DIR="${CLAUDE_PLUGINS_MARKETPLACE_DIR:-$HOME/.claude/plugins/marketplaces/laurigates-claude-plugins}"
HOOK="${SECRET_PROTECTION_HOOK:-$MARKETPLACE_DIR/hooks-plugin/hooks/secret-protection.sh}"

# A fake token that matches no real token format.
FAKE_TOKEN="000000-fake-telegram-token-for-tests"
FAKE_CHAT="-1001234567890"

checks=0
fails=0

# check <desc> <cmd...>: pass when the command succeeds.
check() {
    local desc="$1"
    shift
    checks=$((checks + 1))
    if ! "$@"; then
        printf 'FAIL: %s\n' "$desc"
        fails=$((fails + 1))
    fi
}

# has <file> <fixed-string>: the file contains the string.
has() { grep -qF -- "$2" "$1"; }
lacks() { ! grep -qF -- "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STUB_DIR="$WORK/bin"
mkdir -p "$STUB_DIR"

# The curl stub: logs its arguments, finds the Bot API URL, answers by method.
cat >"$STUB_DIR/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$STUB_LOG"
url=""
for a in "$@"; do
  case "$a" in https://api.telegram.org/*) url="$a" ;; esac
done
method="${url##*/}"
method="${method%%\?*}"
case "${STUB_MODE}:${method}" in
  curlfail:getMe)
    echo "curl: (6) Could not resolve host while fetching ${url}" >&2
    exit 6 ;;
  auth:getMe)
    echo '{"ok":false,"error_code":401,"description":"Unauthorized"}' ;;
  *:getMe)
    echo '{"ok":true,"result":{"id":42,"is_bot":true,"first_name":"Fake","username":"fake_test_bot"}}' ;;
  chat:getChat)
    echo '{"ok":false,"error_code":400,"description":"Bad Request: chat not found"}' ;;
  ok:getChat|updates:getChat)
    echo '{"ok":true,"result":{"id":-1001234567890,"type":"supergroup","title":"Test Group"}}' ;;
  updates:getUpdates)
    echo '{"ok":true,"result":[
      {"update_id":1,"message":{"chat":{"id":-1001234567890,"type":"supergroup","title":"Test Group"},"text":"a"}},
      {"update_id":2,"message":{"chat":{"id":-1001234567890,"type":"supergroup","title":"Test Group"},"text":"b"}},
      {"update_id":3,"message":{"chat":{"id":777,"type":"private","first_name":"Pat","username":"pat_u"},"text":"c"}},
      {"update_id":4,"poll_answer":{"poll_id":"p","option_ids":[0]}}
    ]}' ;;
  *)
    echo "stub curl: unexpected call ${STUB_MODE}:${method}" >&2
    exit 97 ;;
esac
STUB
chmod +x "$STUB_DIR/curl"

export PATH="$STUB_DIR:$PATH"
export STUB_LOG="$WORK/curl.log"

check "curl resolves to the executable stub" test "$(command -v curl)" = "$STUB_DIR/curl"
check "telegram-check exists and is executable" test -x "$SCRIPT"

# run <name> <mode> [args...]: run telegram-check; stdout+stderr to $WORK/<name>.out,
# exit code to $WORK/<name>.rc. Token and chat id come from the caller's env.
run() {
    local name="$1" mode="$2"
    shift 2
    : >"$STUB_LOG"
    STUB_MODE="$mode" "$SCRIPT" "$@" >"$WORK/$name.out" 2>&1
    echo $? >"$WORK/$name.rc"
    cp "$STUB_LOG" "$WORK/$name.curl"
}
rc() { cat "$WORK/$1.rc"; }

# ── Unset ────────────────────────────────────────────────────────────────────
(
    unset TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID
    run unset ok
)
check "unset: exit 2" test "$(rc unset)" = 2
check "unset: token reported unset" has "$WORK/unset.out" "TELEGRAM_BOT_TOKEN=unset"
check "unset: chat id reported unset" has "$WORK/unset.out" "TELEGRAM_CHAT_ID=unset"
check "unset: STATUS=FAIL" has "$WORK/unset.out" "STATUS=FAIL"
check "unset: curl not called" test ! -s "$WORK/unset.curl"

(
    unset TELEGRAM_CHAT_ID
    # A prefix assignment on a function call is exported for the call (bash).
    TELEGRAM_BOT_TOKEN="$FAKE_TOKEN" run nochat ok
)
check "nochat: exit 2" test "$(rc nochat)" = 2
check "nochat: token reported set" has "$WORK/nochat.out" "TELEGRAM_BOT_TOKEN=set"
check "nochat: chat id reported unset" has "$WORK/nochat.out" "TELEGRAM_CHAT_ID=unset"
check "nochat: curl not called" test ! -s "$WORK/nochat.curl"

export TELEGRAM_BOT_TOKEN="$FAKE_TOKEN"
export TELEGRAM_CHAT_ID="$FAKE_CHAT"

# ── OK ───────────────────────────────────────────────────────────────────────
run ok ok
check "ok: exit 0" test "$(rc ok)" = 0
check "ok: bot username" has "$WORK/ok.out" "BOT_USERNAME=fake_test_bot"
check "ok: chat title" has "$WORK/ok.out" "CHAT_TITLE=Test Group"
check "ok: chat type" has "$WORK/ok.out" "CHAT_TYPE=supergroup"
check "ok: chat id" has "$WORK/ok.out" "CHAT_ID=$FAKE_CHAT"
check "ok: STATUS=OK" has "$WORK/ok.out" "STATUS=OK"
check "ok: getChat was asked about the configured chat" has "$WORK/ok.curl" "chat_id=$FAKE_CHAT"

# ── Auth ─────────────────────────────────────────────────────────────────────
run auth auth
check "auth: exit 1" test "$(rc auth)" = 1
check "auth: error code printed" has "$WORK/auth.out" "401"
check "auth: STATUS=FAIL" has "$WORK/auth.out" "STATUS=FAIL"

# ── Chat ─────────────────────────────────────────────────────────────────────
run chat chat
check "chat: exit 1" test "$(rc chat)" = 1
check "chat: bot still identified" has "$WORK/chat.out" "BOT_USERNAME=fake_test_bot"
check "chat: description printed" has "$WORK/chat.out" "chat not found"
check "chat: hint points at --updates" has "$WORK/chat.out" "--updates"
check "chat: STATUS=FAIL" has "$WORK/chat.out" "STATUS=FAIL"

# ── Curl ─────────────────────────────────────────────────────────────────────
run curlfail curlfail
check "curlfail: exit 1" test "$(rc curlfail)" = 1
check "curlfail: curl error surfaced" has "$WORK/curlfail.out" "Could not resolve host"
check "curlfail: STATUS=FAIL" has "$WORK/curlfail.out" "STATUS=FAIL"

# ── Updates ──────────────────────────────────────────────────────────────────
run updates updates --updates
check "updates: exit 0" test "$(rc updates)" = 0
check "updates: supergroup listed" has "$WORK/updates.out" "$FAKE_CHAT"
check "updates: private chat listed" has "$WORK/updates.out" "pat_u"
check "updates: two distinct chats" has "$WORK/updates.out" "UPDATE_CHATS=2"
check "updates: each chat listed once" test "$(grep -c '^UPDATE_CHAT=' "$WORK/updates.out")" = 2

# ── Token ────────────────────────────────────────────────────────────────────
for name in unset nochat ok auth chat curlfail updates; do
    check "$name: output contains no token" lacks "$WORK/$name.out" "$FAKE_TOKEN"
done

# ── Hook ─────────────────────────────────────────────────────────────────────
# hook_rc <command>: exit code of secret-protection.sh for a Bash call running it.
hook_rc() {
    jq -n --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}' |
        env -u CLAUDE_HOOKS_DISABLE_SECRET_PROTECTION bash "$HOOK" >/dev/null 2>&1
    echo $?
}
if [[ -f "$HOOK" ]]; then
    # shellcheck disable=SC2016  # the control is literal command text
    check "hook control: a presence report naming the token is blocked" \
        test "$(hook_rc 'printf "%s\n" "${TELEGRAM_BOT_TOKEN:+set}"')" = 2
    check "hook: telegram-check is allowed" test "$(hook_rc 'telegram-check')" = 0
    check "hook: telegram-check --updates is allowed" test "$(hook_rc 'telegram-check --updates')" = 0
else
    printf 'SKIP: hook checks (no %s)\n' "$HOOK"
fi

printf '%d checks, %d failed\n' "$checks" "$fails"
[[ "$fails" -eq 0 ]]
