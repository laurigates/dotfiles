#!/usr/bin/env bash
# Regression test: telegram-send-file uploads a file to the configured chat
# with the Bot API method that fits its type, refuses a file the Bot API would
# reject before any network call, and never prints the bot token (#519).
#
# Before this script the telegram skill could only send text, and a direct
# Bot API call is not an option for an agent: the upload URL carries the token,
# and hooks-plugin's secret-protection.sh blocks a command that names it.
#
# Every curl call goes to a stub on PATH that logs its arguments one per line
# and answers by STUB_MODE. Nothing reaches the network. The fixtures are real
# file signatures (a 1x1 PNG, an MP4 ftyp box), typed by the real `file`; the
# oversize fixtures are sparse, so they take no disk space.
#
# Checked here:
#   Image    a PNG goes to sendPhoto in the `photo` field, with chat_id.
#   Video    an MP4 goes to sendVideo in the `video` field.
#   Other    a text file goes to sendDocument in the `document` field.
#   Caption  the caption is passed with --form-string (curl -F would read a
#            leading @ or < as a file name); no caption field without one.
#   Flags    -d sends an image as a document; -s sets disable_notification.
#   Path     a path holding `"`, `;` and `,` is quoted for curl -F.
#   BigPhoto a PNG over 10 MB and under 50 MB goes to sendDocument.
#   Oversize a file over 50 MB: exit 2, the limit is named, curl never called.
#   Missing  a missing file, a directory, an empty file, no arguments: exit 2,
#            curl never called.
#   Env      token or chat id unset: exit 2, the variable is named, curl never
#            called.
#   API      ok:false from the Bot API: exit 1, code and description printed.
#   Curl     curl fails and echoes the URL (token included) on stderr: exit 1,
#            the error is printed with the token redacted.
#   Token    no scenario's stdout or stderr contains the fake token.
#   Hook     when hooks-plugin is installed, secret-protection.sh lets a
#            `telegram-send-file` command through, and still blocks a command
#            that prints whether the token variable is set (the control).
#
# Usage: tests/test-telegram-send-file.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT="$REPO_DIR/dot_local/bin/executable_telegram-send-file"
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
# has_line <file> <fixed-string>: some whole line of the file is the string.
has_line() { grep -qxF -- "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STUB_DIR="$WORK/bin"
FIX="$WORK/fixtures"
mkdir -p "$STUB_DIR" "$FIX"

# The curl stub: logs each argument on its own line, answers by STUB_MODE.
cat >"$STUB_DIR/curl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$STUB_LOG"
url=""
for a in "$@"; do
  case "$a" in https://api.telegram.org/*) url="$a" ;; esac
done
case "$STUB_MODE" in
  ok)
    echo '{"ok":true,"result":{"message_id":7}}' ;;
  apierr)
    echo '{"ok":false,"error_code":400,"description":"Bad Request: chat not found"}' ;;
  curlfail)
    echo "curl: (6) Could not resolve host while fetching ${url}" >&2
    exit 6 ;;
  *)
    echo "stub curl: unexpected mode ${STUB_MODE}" >&2
    exit 97 ;;
esac
STUB
chmod +x "$STUB_DIR/curl"

export PATH="$STUB_DIR:$PATH"
export STUB_LOG="$WORK/curl.log"

check "curl resolves to the executable stub" test "$(command -v curl)" = "$STUB_DIR/curl"
check "telegram-send-file exists and is executable" test -x "$SCRIPT"

# ── Fixtures ─────────────────────────────────────────────────────────────────
PNG_B64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
printf '%s' "$PNG_B64" | base64 --decode >"$FIX/shot.png"
printf '\000\000\000\040ftypisom\000\000\002\000isomiso2avc1mp41' >"$FIX/clip.mp4"
printf 'plain text\n' >"$FIX/notes.txt"
printf 'plain text\n' >"$FIX/odd \"name\"; a,b.txt"
: >"$FIX/empty.bin"

# grow <file> <bytes>: extend a file to the given size with a sparse tail.
# With count=0, dd sets the length to the seek offset and keeps the head.
grow() { dd if=/dev/zero of="$1" bs=1 count=0 seek="$2" 2>/dev/null; }
cp "$FIX/shot.png" "$FIX/big.png"
grow "$FIX/big.png" $((10 * 1024 * 1024 + 1))
cp "$FIX/clip.mp4" "$FIX/huge.mp4"
grow "$FIX/huge.mp4" $((50 * 1024 * 1024 + 1))

# The fixtures must be typed as intended, or the routing checks prove nothing.
mime() { file -b -L --mime-type -- "$1"; }
check "fixture: shot.png is image/png" test "$(mime "$FIX/shot.png")" = image/png
check "fixture: big.png is image/png" test "$(mime "$FIX/big.png")" = image/png
check "fixture: clip.mp4 is video/mp4" test "$(mime "$FIX/clip.mp4")" = video/mp4
check "fixture: big.png is over 10 MB" test "$(wc -c <"$FIX/big.png")" -gt $((10 * 1024 * 1024))
check "fixture: huge.mp4 is over 50 MB" test "$(wc -c <"$FIX/huge.mp4")" -gt $((50 * 1024 * 1024))

# run <name> <mode> [args...]: run telegram-send-file; stdout+stderr to
# $WORK/<name>.out, exit code to $WORK/<name>.rc, curl arguments to
# $WORK/<name>.curl. Token and chat id come from the caller's env.
run() {
    local name="$1" mode="$2"
    shift 2
    : >"$STUB_LOG"
    STUB_MODE="$mode" "$SCRIPT" "$@" >"$WORK/$name.out" 2>&1
    echo $? >"$WORK/$name.rc"
    cp "$STUB_LOG" "$WORK/$name.curl"
}
rc() { cat "$WORK/$1.rc"; }
# method <name>: the Bot API method in the URL curl was given.
method() { sed -n 's|^https://api\.telegram\.org/bot.*/||p' "$WORK/$1.curl"; }

# ── Env ──────────────────────────────────────────────────────────────────────
(
    unset TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID
    run notoken ok "$FIX/notes.txt"
)
check "notoken: exit 2" test "$(rc notoken)" = 2
check "notoken: names the variable" has "$WORK/notoken.out" "TELEGRAM_BOT_TOKEN"
check "notoken: curl not called" test ! -s "$WORK/notoken.curl"

(
    unset TELEGRAM_CHAT_ID
    # A prefix assignment on a function call is exported for the call (bash).
    TELEGRAM_BOT_TOKEN="$FAKE_TOKEN" run nochat ok "$FIX/notes.txt"
)
check "nochat: exit 2" test "$(rc nochat)" = 2
check "nochat: names the variable" has "$WORK/nochat.out" "TELEGRAM_CHAT_ID"
check "nochat: curl not called" test ! -s "$WORK/nochat.curl"

export TELEGRAM_BOT_TOKEN="$FAKE_TOKEN"
export TELEGRAM_CHAT_ID="$FAKE_CHAT"

# ── Image ────────────────────────────────────────────────────────────────────
run image ok "$FIX/shot.png" "a caption"
check "image: exit 0" test "$(rc image)" = 0
check "image: curl was called" test -s "$WORK/image.curl"
check "image: method sendPhoto" test "$(method image)" = sendPhoto
check "image: photo field holds the file" has_line "$WORK/image.curl" "photo=@\"$FIX/shot.png\""
check "image: chat_id field" has_line "$WORK/image.curl" "chat_id=$FAKE_CHAT"
check "image: caption field" has_line "$WORK/image.curl" "caption=a caption"
check "image: not silent by default" has_line "$WORK/image.curl" "disable_notification=false"
check "image: prints nothing" test ! -s "$WORK/image.out"

# ── Video ────────────────────────────────────────────────────────────────────
run video ok "$FIX/clip.mp4"
check "video: exit 0" test "$(rc video)" = 0
check "video: method sendVideo" test "$(method video)" = sendVideo
check "video: video field holds the file" has_line "$WORK/video.curl" "video=@\"$FIX/clip.mp4\""
check "video: no caption field without a caption" lacks "$WORK/video.curl" "caption="

# ── Other ────────────────────────────────────────────────────────────────────
run other ok "$FIX/notes.txt"
check "other: exit 0" test "$(rc other)" = 0
check "other: method sendDocument" test "$(method other)" = sendDocument
check "other: document field holds the file" has_line "$WORK/other.curl" "document=@\"$FIX/notes.txt\""

# ── Caption ──────────────────────────────────────────────────────────────────
run caption ok "$FIX/notes.txt" "@home; type=x" "second word"
check "caption: exit 0" test "$(rc caption)" = 0
check "caption: extra arguments are joined" has_line "$WORK/caption.curl" "caption=@home; type=x second word"
check "caption: passed with --form-string" \
    test "$(grep -B1 -xF -- 'caption=@home; type=x second word' "$WORK/caption.curl" | head -n 1)" = "--form-string"

# ── Flags ────────────────────────────────────────────────────────────────────
run asdoc ok -d "$FIX/shot.png"
check "asdoc: exit 0" test "$(rc asdoc)" = 0
check "asdoc: -d sends an image with sendDocument" test "$(method asdoc)" = sendDocument

run silent ok -s "$FIX/notes.txt"
check "silent: exit 0" test "$(rc silent)" = 0
check "silent: disable_notification=true" has_line "$WORK/silent.curl" "disable_notification=true"

run badflag ok --nope "$FIX/notes.txt"
check "badflag: exit 2" test "$(rc badflag)" = 2
check "badflag: curl not called" test ! -s "$WORK/badflag.curl"

# ── Path ─────────────────────────────────────────────────────────────────────
run oddpath ok "$FIX/odd \"name\"; a,b.txt"
check "oddpath: exit 0" test "$(rc oddpath)" = 0
check "oddpath: quotes are escaped inside a quoted name" \
    has_line "$WORK/oddpath.curl" "document=@\"$FIX/odd \\\"name\\\"; a,b.txt\""

# ── BigPhoto ─────────────────────────────────────────────────────────────────
run bigphoto ok "$FIX/big.png"
check "bigphoto: exit 0" test "$(rc bigphoto)" = 0
check "bigphoto: an image over 10 MB goes to sendDocument" test "$(method bigphoto)" = sendDocument

# ── Oversize ─────────────────────────────────────────────────────────────────
run oversize ok "$FIX/huge.mp4"
check "oversize: exit 2" test "$(rc oversize)" = 2
check "oversize: names the limit" has "$WORK/oversize.out" "50 MB"
check "oversize: curl not called" test ! -s "$WORK/oversize.curl"

# ── Missing ──────────────────────────────────────────────────────────────────
run missing ok "$FIX/does-not-exist.mp4"
check "missing: exit 2" test "$(rc missing)" = 2
check "missing: names the path" has "$WORK/missing.out" "does-not-exist.mp4"
check "missing: curl not called" test ! -s "$WORK/missing.curl"

run isdir ok "$FIX"
check "isdir: exit 2" test "$(rc isdir)" = 2
check "isdir: curl not called" test ! -s "$WORK/isdir.curl"

run empty ok "$FIX/empty.bin"
check "empty: exit 2" test "$(rc empty)" = 2
check "empty: curl not called" test ! -s "$WORK/empty.curl"

run noargs ok
check "noargs: exit 2" test "$(rc noargs)" = 2
check "noargs: curl not called" test ! -s "$WORK/noargs.curl"

# ── API ──────────────────────────────────────────────────────────────────────
run apierr apierr "$FIX/notes.txt"
check "apierr: exit 1" test "$(rc apierr)" = 1
check "apierr: error code printed" has "$WORK/apierr.out" "400"
check "apierr: description printed" has "$WORK/apierr.out" "chat not found"
check "apierr: names the method" has "$WORK/apierr.out" "sendDocument"

# ── Curl ─────────────────────────────────────────────────────────────────────
run curlfail curlfail "$FIX/notes.txt"
check "curlfail: exit 1" test "$(rc curlfail)" = 1
check "curlfail: curl error surfaced" has "$WORK/curlfail.out" "Could not resolve host"
check "curlfail: the token is redacted" has "$WORK/curlfail.out" "<redacted>"

# ── Token ────────────────────────────────────────────────────────────────────
# Control: the stub did receive the token, so its absence below is the script's
# doing.
check "token control: curl was given the token in the URL" has "$WORK/curlfail.curl" "$FAKE_TOKEN"
for name in notoken nochat image video other caption asdoc silent badflag oddpath \
    bigphoto oversize missing isdir empty noargs apierr curlfail; do
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
    check "hook: telegram-send-file is allowed" \
        test "$(hook_rc 'telegram-send-file tmp/render.mp4 "Render done"')" = 0
else
    printf 'SKIP: hook checks (no %s)\n' "$HOOK"
fi

printf '%d checks, %d failed\n' "$checks" "$fails"
[[ "$fails" -eq 0 ]]
