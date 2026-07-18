---
name: telegram
description: Send notifications, interactive questions, or multiple-choice polls to the user via Telegram. Use when the user asks to be notified ("ping me", "notify me on Telegram", "ask me when..."), when a long-running task finishes and the user is likely away, when an irreversible action needs out-of-band confirmation, or when the user should pick among several fixed options ("ask me which one via poll"). Provides telegram-notify (one-way), telegram-ask (send + block for reply), and telegram-poll (send a multiple-choice poll + block for the vote).
---

# Telegram Communication

Out-of-band channel to the user via a Telegram bot. Use it when the
terminal isn't enough — the user has walked away, the task ran long,
or a decision needs confirmation while the user is mobile.

For the *when-to-use* policy (and when not to), see
`~/.claude/rules/telegram-communication.md`. This skill covers the
*how*.

## Tools

Three scripts in `~/.local/bin`:

| Script | Purpose | Blocks? |
|---|---|---|
| `telegram-notify` | Fire-and-forget message | No |
| `telegram-ask` | Send a question, wait for reply, print reply to stdout | Yes |
| `telegram-poll` | Send a multiple-choice poll, wait for the vote, print selected option(s) | Yes |

All three read `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` from the
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
# Default: 1-hour timeout, accept any reply
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
   reply arrives or the deadline passes. While waiting, re-sends the
   question as a reminder at exponentially increasing intervals
   (default: after 5m, then 10m, 20m, ... capped by `-t`) — a missed
   phone notification gets more than one chance, without nagging
   someone who's simply away from their phone. Disable with `-r 0`.
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

`telegram-ask` blocks until the user replies, and the default `-t` is
now 3600s (1 hour) — longer than the Bash tool's 10-minute foreground
cap. Two patterns:

**Short waits (≤ ~9 min)**: pass an explicit `-t` and a Bash `timeout`
that exceeds it.

```
Bash(
  command='telegram-ask -t 480 -p "^(YES|NO)$" "Run the destructive migration?"',
  timeout=500000   # ms, must be > telegram-ask -t (seconds) * 1000
)
```

**Long waits (default 1h)**: run in the background — the harness
re-invokes you when the script exits, so no polling loop is needed.

```
Bash(
  command='telegram-ask -p "^(YES|NO)$" "Run the destructive migration?"',
  run_in_background=true
)
```

Read the reply from the task output when it completes. Humans routinely
take 15–60 minutes to notice a phone notification; prefer the
background pattern over shrinking `-t` to fit a foreground call.

If the user's reply is `YES`, proceed. Anything else (including
`TIMEOUT`), do not proceed — surface the result and wait for fresh
direction.

## telegram-poll

```
# Single-choice, default 1-hour timeout
choice=$(telegram-poll "Which environment?" "staging" "prod" "both")

# Short timeout for an at-keyboard pick
choice=$(telegram-poll -t 60 "Which fix?" "revert" "hotfix" "wait")

# Multiple choice — user can select more than one option
choices=$(telegram-poll -M "Which suites failed?" "unit" "integration" "e2e")

# Silent (no notification sound)
choice=$(telegram-poll -s "Non-urgent pick" "A" "B")
```

Behaviour:

1. Sends a non-anonymous poll (`is_anonymous: false`) — required so the
   `poll_answer` update identifies the voter; there's no other way for
   the bot to attribute a vote to a reply.
2. Drains pending updates so a stale vote from an earlier poll can't
   satisfy the wait.
3. Long-polls (`getUpdates` with `allowed_updates=["poll_answer"]`,
   `timeout=30`) until a `poll_answer` for this poll's id arrives or the
   deadline passes. While waiting, sends a plain-text nudge ("Still
   waiting for your vote on: ...") at exponentially increasing intervals
   (default: after 5m, then 10m, 20m, ... capped by `-t`) — same backoff
   as `telegram-ask`. Disable with `-r 0`.
4. On answer: closes the poll (`stopPoll`) and prints the selected
   option text(s) to stdout, one per line — not the raw option index.
5. On timeout: prints `TIMEOUT` to stderr, closes the poll, sends a
   "(poll timed out)" notice to the chat, and exits 1.
6. On config error or a send failure (bad option count, question too
   long): exits 2 with a message.

Constraints (Telegram Bot API): question ≤300 characters, each option
≤100 characters, at most 10 options.

Use `telegram-poll` when the choice is genuinely a fixed set of
options — it renders as tappable buttons on the user's phone, which
beats typing a reply for a menu of 3-10 choices. For yes/no or
free-text confirmation, `telegram-ask` is still the right tool; a
two-option poll is heavier than it needs to be for a plain yes/no.

Calling pattern from inside a Claude Code session — same rules as
`telegram-ask`: for a short explicit `-t`, the Bash `timeout` must
exceed it; for the 1-hour default, use `run_in_background=true`.

```
Bash(
  command='telegram-poll -t 300 "Which fix?" "revert" "hotfix" "wait"',
  timeout=320000   # ms, must be > telegram-poll -t (seconds) * 1000
)
```

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
| `telegram-poll` never returns despite a vote | `poll_answer` wasn't in `allowed_updates`, or the vote landed on a different, older poll | Rare — the script always scopes `allowed_updates` and filters by `poll_id`; re-run if it happens |
| `telegram-poll: send failed` with a 400 | Question >300 chars, an option >100 chars, or fewer than 2 / more than 10 options | Shorten the text or the option count |

## Why these tools and not `telegram-send`?

`telegram-send` (the well-known Python tool) is **send-only**. It has
no receive mode, no polling, no way to wait for a reply. The
interactive flow needs `getUpdates` long-polling, which these three
thin curl+jq wrappers provide with no extra runtime dependencies
beyond `curl` and `jq` (both already on the system).

## Rationale

Telegram is the user's "I might be on my phone" channel. The three
tools make the natural patterns one-line: notify (no reply needed),
ask (block on a free-text reply), and poll (block on a pick among
fixed options). Keep messages signal-rich and
infrequent — see `telegram-communication.md` for the policy on
when to send vs. stay quiet.
