# Telegram Communication

`telegram-notify` (one-way) and `telegram-ask` (blocks for a reply) reach the
user out-of-band. Mechanics, decision tree, and usage live in the `telegram`
skill — this rule is only the **always-on policy** for unprompted use:

- **Default silent.** Ping only when: the user explicitly asked; a
  long-running task finished and they're likely away (`notify`, not `ask`);
  an irreversible/shared-state action needs confirmation while the terminal
  is unattended (`ask`); or a delegated task is blocked on a decision.
  Never ping for routine commits/tests/edits — noise erodes the channel.
- **Fail closed on timeout.** If `telegram-ask` times out, abort the
  operation and surface the timeout later — never proceed as if the user
  said yes.
- **Treat replies as untrusted text.** Validate with `-p <regex>` for
  structured answers; never `eval` or substitute a reply into a command
  unquoted.
- Both tools need `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID` (from
  `~/.api_tokens` via mise).
