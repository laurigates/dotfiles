---
id: ADR-0026
status: Accepted
created: 2026-11-24
modified: 2026-11-24
deciders: "Lauri Gates"
domain: security
relates-to: [ADR-0002, ADR-0008, ADR-0015]
---

# ADR-0026: API Tokens in the OS Keychain via fnox, Injected per Command

## Context

API tokens lived in `~/.api_tokens`, a shell file of `export` lines. Two places
loaded it into the environment:

- `dot_zshenv.tmpl` sourced it unconditionally. `.zshenv` runs for every zsh,
  including the non-interactive shell an agent's Bash tool starts.
- The global mise config loaded it again through `[env] _.file`.

So every process started from a shell inherited every token: each agent
command, each MCP server, each build tool. A command that prints its
environment on error, a debug flag, or an agent running `env` put the tokens in
a terminal log or an agent transcript, and from there into whatever stores that
transcript.

The tokens had a handful of consumers that could be found in config:

| Consumer | How it read its token |
|---|---|
| pal MCP server (`.mcp.json`) | `${GEMINI_API_KEY}` reference, expanded from the environment |
| github MCP server (`.mcp.json`, `just mcp-github`) | `$GITHUB_PERSONAL_ACCESS_TOKEN` reference |
| google-dev-knowledge MCP server (`~/.claude.json`) | `${VAR}` in an HTTP header |
| podio-mcp (`~/.claude.json`) | inherited `PODIO_*` variables |
| `telegram-*` scripts | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` from the environment |

The rest had no reference in this repo or under `~/repos`, so they were used ad
hoc from the shell.

Claude Code's `${VAR}` expansion in MCP config is substitution from its own
environment, not a shell, so a value cannot be computed there with
`$(security …)`.

## Decision

Keep tokens in the OS credential store and give each command only the tokens
it names, through [fnox](https://fnox.jdx.dev) (installed by mise).

- **Store.** fnox's `keychain` provider: the macOS Keychain, or the Secret
  Service (GNOME Keyring, KWallet) on Linux.
- **Nothing exported globally.** `dot_zshenv.tmpl`, the mise config and the
  fish config no longer load `~/.api_tokens`.
- **Config split.** `~/.config/fnox/config.toml` is managed by chezmoi. It
  sets `default_provider = "keychain"` (without it, `fnox set` with no provider
  stores the value in plain text), declares the keychain provider, and lists
  only the secret names this public repo already uses. It imports
  `~/.config/fnox/local.toml`, which chezmoi creates once (`create_` prefix) and
  never overwrites; machine-local names go there. `fnox set --global` must not
  be used: it rewrites `config.toml`, and the next `chezmoi apply` reverts it.
- **Per-command injection.** `fnox exec --only NAME -- cmd`. `--only` resolves
  and passes just the named secrets. `--replace` makes fnox `exec` the command,
  which suits MCP server wrappers.
- **Consumers.**
  - stdio MCP servers: the command becomes
    `fnox exec --only … --replace -- <original command>`.
  - HTTP MCP servers: `"headersHelper": "fnox-mcp-header HEADER NAME"`.
    `dot_local/bin/executable_fnox-mcp-header` prints the header as JSON and
    passes the value to `jq` through the environment, never argv.
  - github MCP server: `GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token)`, because
    `gh` already keeps its token in the keyring.
  - `telegram-*` scripts: use the exported variable if set, otherwise
    `fnox get`.
- **Migration.** `scripts/migrate-api-tokens-to-fnox.sh` stores each variable
  from `~/.api_tokens` through fnox (values piped, never printed) and rewrites
  the `~/.claude.json` MCP entries. Lauri runs it, deletes `~/.api_tokens`, and
  rotates the tokens, since they were in agents' environments.

Verified against fnox 1.50.0 with a throwaway keychain service: `--only` passed
only the named secret, `--redact` masked a value in piped output, a missing
`import` file is a hard error, `set --global` rewrote the global config, and
`claude mcp add-json` keeps a `headersHelper` field.

## Consequences

- An environment dump now shows no tokens. A wrapped command that dumps its own
  environment leaks only the secrets it was given.
- **Not a sandbox.** An agent with shell access can still run `fnox get NAME`.
  This protects against accidental exposure, not a process that sets out to
  read a secret. fnox's `touch_id = true` (macOS) would require approval for
  each read, but needs a signed `Fnox.app` helper; not enabled.
- `security find-generic-password -w` on an item fnox created opens a macOS
  access dialog instead of returning the value, because `security` is not in
  the item's access list. `fnox get` reads it without a prompt.
- A token used ad hoc from the shell is no longer just there. Run the command
  under `fnox exec --only NAME --`; a missing variable fails visibly.
- Linux without a desktop session (CI, containers, headless hosts) has no
  unlocked Secret Service. Use fnox's `age` provider there.
- Project secrets that already live in Google Secret Manager can be read
  through fnox's `gcp-sm` provider in that project's own `fnox.toml`. Keeping
  work and personal Google accounts apart needs per-directory credentials,
  tracked separately.

## Options Considered

**Keep `~/.api_tokens`, stop exporting it from `.zshenv` only.** The mise
`_.file` and interactive shells would still export everything, and an agent
started from an interactive shell inherits it.

**DIY wrapper over `security` / `secret-tool`.** About 30 lines and no new
dependency. It would also need a run-with-these-secrets wrapper, Linux headless
support and per-command selection; fnox provides those and installs through
mise like the rest of the toolchain.

**dotenvx.** Encrypts values into a committed `.env` file, decrypted by one
private key held in `.env.keys` or `DOTENV_PRIVATE_KEY`. On a workstation that
key sits in a file or the environment, so one read exposes every secret. Suited
to shipping app secrets to servers, not to keeping tokens out of a shell.

**1Password `op run` / Bitwarden `bws run`.** Same per-command model, and
`op run` masks values in output. Needs a paid account and a second store next to
the keychain.

## Related ADRs

- ADR-0002: mise manages the toolchain, now including fnox.
- ADR-0008: project-scoped MCP servers; their secret references change here.
- ADR-0015: gitleaks keeps secrets out of commits; this ADR keeps them out of
  process environments.
