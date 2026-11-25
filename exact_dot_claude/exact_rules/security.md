---
reviewed: 2026-02-16
---

# Security

## API Token Management

- API tokens live in the OS keychain through fnox, never in the shell
  environment: nothing exports them globally, so a crash that dumps the
  environment or an agent's `env` cannot show them. A command gets only what it
  names: `fnox exec --only NAME -- cmd` (dotfiles ADR-0026)
- New secret: `fnox -c ~/.config/fnox/local.toml set NAME` (hidden prompt or
  stdin, never argv). `fnox set --global` would rewrite the chezmoi-managed
  `~/.config/fnox/config.toml`
- MCP servers: wrap a stdio server's command in `fnox exec --only … --replace --`;
  give an HTTP server `"headersHelper": "fnox-mcp-header HEADER NAME"`. A
  `${VAR}` reference in `.mcp.json` only expands variables that are already
  exported, so it has nothing to read
- Private files use `private_` prefix in chezmoi
- Keep secrets out of version control

## MCP Server Security

- Never put a token value in `.mcp.json`; use the fnox patterns under API Token Management
- Prefer project-scoped MCP servers for focused context
