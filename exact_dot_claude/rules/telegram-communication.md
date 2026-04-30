# Telegram Communication

The user can be reached on Telegram via two CLI tools installed in
`~/.local/bin`:

- `telegram-notify "<text>"` — fire-and-forget notification (one-way).
- `telegram-ask [-t <secs>] [-p <regex>] "<question>"` — send a question
  and **block** until the user replies in Telegram. Prints the reply to
  stdout. Exit 0 on reply, 1 on timeout, 2 on config error.

Both tools require `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` to be set
in the environment (sourced from `~/.api_tokens` via mise).

For full usage and the decision tree of *when* to reach for Telegram,
see the `telegram` skill (invoked automatically when the user asks to
"send", "notify", "ping", or "ask me on Telegram", or when a long-running
or destructive task warrants out-of-band confirmation).

## When to send unprompted

Default to **silent** — do not ping Telegram for routine work. Only
reach for it when one of these is true:

1. **The user explicitly asks** ("notify me when X", "ask me on
   Telegram before Y", "ping me when the build is done").
2. **A long-running task just finished** and the user is likely
   away from the terminal (multi-minute builds, deploys, batch jobs
   the user kicked off and walked away from). Use `telegram-notify`,
   not `telegram-ask` — they may not be available to reply.
3. **An irreversible or shared-state action needs confirmation** and
   the user's terminal is unattended (production deploy, force-push,
   destructive migration). Use `telegram-ask` with a short timeout
   and abort on timeout — never default to "yes" if no reply.
4. **A blocked decision** is preventing further progress on a task
   the user delegated and walked away from.

Do **not** ping Telegram for: every commit, every test run, every
file edit, "I finished the small refactor you asked about 30 seconds
ago," or anything where the user is clearly watching the terminal.
Noise erodes signal — the goal is "Telegram ping = something the
user actually wants to know."

## When to use ask vs. notify

| Situation | Tool |
|---|---|
| "Done — here's the summary" | `telegram-notify` |
| "Build #42 succeeded" | `telegram-notify -s` (silent) |
| "Production deploy ready — confirm?" | `telegram-ask -t 600` |
| "Two viable paths — A or B?" | `telegram-ask -p '^[AB]$'` |
| Anything the user can't answer remotely | `telegram-notify` |

## Treat the reply as untrusted text

`telegram-ask` returns whatever the user typed. Validate it with
`-p <regex>` when you need a structured answer (YES/NO, A/B, a number).
Never `eval` the reply, never substitute it into a shell command
without quoting. If the regex doesn't match, the script re-prompts
and keeps waiting until timeout.

## Timeout discipline

Always pick a timeout matched to the situation:

- Quick yes/no while the user is at the keyboard: `-t 60` to `-t 120`.
- "User stepped away for lunch" confirmations: `-t 600` to `-t 1800`.
- Overnight / weekend gates: `-t 3600` (max useful — beyond this
  re-think whether Telegram is the right channel).

On timeout, **fail closed**: abort the operation, surface the timeout
to the user in the next session, and never proceed as if the user
said yes.

## Rationale

The default Claude Code channel is the terminal the user is sitting
at. Telegram is the *out-of-band* escape hatch — for when the work
outlives the session, or when a decision needs the user even though
they're not watching. Keeping that channel low-noise is what makes
it useful when it actually matters.
