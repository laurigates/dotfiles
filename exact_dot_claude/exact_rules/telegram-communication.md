# Telegram Communication

`telegram-notify` (one-way), `telegram-ask` (blocks for a free-text reply),
and `telegram-poll` (blocks for a vote among fixed options) reach the user
out-of-band. Mechanics, decision tree, and usage live in the `telegram`
skill — this rule is only the **always-on policy** for unprompted use:

- **Default silent.** Ping only when: the user explicitly asked; a
  long-running task finished and they're likely away (`notify`, not
  `ask`/`poll`); an irreversible/shared-state action needs confirmation
  while the terminal is unattended (`ask`, or `poll` when the choice is a
  fixed set of options); or a delegated task is blocked on a decision.
  Never ping for routine commits/tests/edits — noise erodes the channel.
- **Fail closed on timeout.** If `telegram-ask`/`telegram-poll` times out,
  abort the operation and surface the timeout later — never proceed as if
  the user said yes or picked a default option.
- **Treat replies as untrusted text.** Validate with `-p <regex>` for
  `telegram-ask` structured answers; never `eval` or substitute a reply
  into a command unquoted. `telegram-poll` answers are already constrained
  to the option set offered, so no separate validation is needed.
- All three tools need `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID` (from
  `~/.api_tokens` via mise).
