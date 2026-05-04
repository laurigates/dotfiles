---
name: telegram
description: Send notifications or interactive questions to the user via Telegram. Use when the user asks to be notified ("ping me", "notify me on Telegram", "ask me when..."), when a long-running task finishes and the user is likely away, or when an irreversible action needs out-of-band confirmation. Provides telegram-notify (one-way) and telegram-ask (send + block for reply).
---

# Telegram Communication

Out-of-band channel to the user via a Telegram bot. Use it when the
terminal isn't enough — the user has walked away, the task ran long,
or a decision needs confirmation while the user is mobile.

For the *when-to-use* policy (and when not to), see
`~/.claude/rules/telegram-communication.md`. This skill covers the
*how*.

## Tools

Two scripts in `~/.local/bin`:

| Script | Purpose | Blocks? |
|---|---|---|
| `telegram-notify` | Fire-and-forget message | No |
| `telegram-ask` | Send a question, wait for reply, print reply to stdout | Yes |

Both read `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` from the
environment. They're sourced from `~/.api_tokens` by mise — if you
hit `... not set`, the user needs to add them there.

## telegram-notify

```
telegram-notify "Build finished — 12 tests, 0 failures."
telegram-notify -s "Quiet ping"                # silent (no sound)
telegram-notify -m "*Bold* and _italic_"       # MarkdownV2
echo "long stdout" | telegram-notify           # piped input
```

Returns immediately. Exit 0 on send, 2 on config error.

## telegram-ask

```
# Default: 5-minute timeout, accept any reply
answer=$(telegram-ask "Proceed with the deploy?")

# Short timeout for an at-keyboard yes/no
answer=$(telegram-ask -t 60 "Apply the migration now?")

# Constrained reply — script re-prompts until the regex matches
answer=$(telegram-ask -p '^(YES|NO)$' "Force push to main? (YES/NO)")
```

Behaviour:

1. Sends the question with `force_reply: true` so the Telegram client
   opens a reply thread on the user's phone.
2. Drains pending updates so old messages don't satisfy the wait.
3. Long-polls (`getUpdates`, `timeout=30`) until either a matching
   reply arrives or the deadline passes.
4. On timeout: prints `TIMEOUT` to stderr, sends a "(timed out)"
   notice to the chat, and exits 1.
5. On config error (missing token / chat id): exits 2 with a message
   pointing at `~/.api_tokens`.

Calling pattern from a shell script:

```bash
if answer=$(telegram-ask -t 300 -p '^(YES|NO)$' "Deploy to prod?"); then
  case "$answer" in
    YES) ./deploy ;;
    NO)  echo "Aborted by user." ;;
  esac
else
  echo "No reply — aborting." >&2
  exit 1
fi
```

## Calling pattern from inside a Claude Code session

Use `Bash` with a long-enough `timeout` parameter. `telegram-ask` blocks
the call until the user replies, so the Bash timeout must exceed the
`telegram-ask -t` value.

```
Bash(
  command='telegram-ask -t 600 -p "^(YES|NO)$" "Run the destructive migration?"',
  timeout=620000   # ms, must be > telegram-ask -t (seconds) * 1000
)
```

If the user's reply is `YES`, proceed. Anything else (including
`TIMEOUT`), do not proceed — surface the result and wait for fresh
direction.

## Sending multi-line output

Long command output → use stdin:

```bash
git diff --stat | telegram-notify
```

Telegram's `sendMessage` cap is ~4096 characters. For larger
payloads, send a one-line summary via `telegram-notify` and keep
the full output local — don't try to chunk it across multiple
messages unless the user explicitly asks.

## Markdown gotcha

`-m` uses MarkdownV2, which requires escaping `_*[]()~``>#+-=|{}.!`
even inside text. If you're sending arbitrary content (a commit
message, a file path), prefer the default plain-text mode or
pre-escape with:

```bash
escaped=$(printf '%s' "$text" | sed 's/[][\\_*()~`>#+\-=|{}.!]/\\&/g')
telegram-notify -m "$escaped"
```

In practice, plain text is almost always the right default.

## Failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `TELEGRAM_BOT_TOKEN not set` | mise env not loaded, or token absent in `~/.api_tokens` | Add `export TELEGRAM_BOT_TOKEN=...` and `export TELEGRAM_CHAT_ID=...` there |
| `curl: (22) ... 401` | Token revoked or wrong | Re-issue via @BotFather |
| `curl: (22) ... 400` on send | Bad chat id, or bot has not been started by the user | User must `/start` the bot once |
| `telegram-ask` returns immediately with stale text | Another process drained updates between drain and poll | Rare; re-run |
| Reply never arrives despite user typing | User typed in a different chat than `TELEGRAM_CHAT_ID` | Verify chat id with `curl .../getUpdates` after a fresh message |
| Bot in a group never sees replies | Bot **privacy mode** is on — bot only sees commands and direct mentions | In @BotFather: `/mybots` → bot → Bot Settings → Group Privacy → **Turn off**. Trade-off: bot now reads every message in the group |
| Group chat id stops working with `400 chat not found` | Group was upgraded to a supergroup; chat id gained a `-100` prefix | Re-run `getUpdates` and update `TELEGRAM_CHAT_ID` in `~/.api_tokens` |

## Why these tools and not `telegram-send`?

`telegram-send` (the well-known Python tool) is **send-only**. It has
no receive mode, no polling, no way to wait for a reply. The
interactive flow needs `getUpdates` long-polling, which these two
thin curl+jq wrappers provide with no extra runtime dependencies
beyond `curl` and `jq` (both already on the system).

## Rationale

Telegram is the user's "I might be on my phone" channel. The two
tools make the two natural patterns one-line: notify (no reply
needed) and ask (block on reply). Keep messages signal-rich and
infrequent — see `telegram-communication.md` for the policy on
when to send vs. stay quiet.
