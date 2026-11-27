---
created: 2026-07-19
modified: 2026-08-31
reviewed: 2026-08-31
paths:
  - ".chezmoidata/packages.toml"
  - ".chezmoidata/profiles.toml"
  - ".chezmoidata/uv_tools.toml"
  - ".chezmoidata.toml"
  - "run_onchange_01-update-packages.sh.tmpl"
  - "run_onchange_03-install-packages.sh.tmpl"
  - "**/.mcp.json"
---
# Package & MCP Server Registries

Repo-specific registries backing package and MCP server management.
(Split out of the global `dependency-management.md` rule, which keeps the
cross-project tool-installation and `mise exec` guidance.)

## Homebrew Package Profiles

Packages are managed through `.chezmoidata/packages.toml` with profile activation in `.chezmoidata/profiles.toml`:

- `core` — Always installed
- `dev` — Development tools (default: enabled)
- `infra` — Infrastructure tools (terraform, kubectl, helm)
- `gui` — GUI applications (cask installs)
- Enable/disable profiles by toggling flags in `profiles.toml`

## MCP Server Management

- Registry of available servers in `.chezmoidata.toml` under `[mcp_servers]`
- `enabled = true` selects which servers `cleanup-mcp-servers.sh` removes; it does not turn a server on
- Servers are installed per-project into that project's `.mcp.json`
- `env_vars` names the secrets a server needs; they come from the OS keychain, not the environment. Wrap the server: `fnox exec --only VAR1,VAR2 --replace -- <command> <args>`, or for HTTP servers `"headersHelper": "fnox-mcp-header HEADER VAR"` (ADR-0026). A `${VAR}` reference has nothing to expand
- Use `/configure-mcp` to install servers into a project; `./cleanup-mcp-servers.sh` to remove them (run only when no Claude sessions are active)
