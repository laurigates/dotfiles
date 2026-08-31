---
created: 2026-07-19
modified: 2026-08-31
reviewed: 2026-08-31
paths:
  - ".chezmoidata/packages.toml"
  - ".chezmoidata/profiles.toml"
  - ".chezmoidata/uv_tools.toml"
  - ".chezmoidata.toml"
  - "Brewfile"
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
- Enable/disable per server — `enabled = true/false`
- Servers are installed per-project into that project's `.mcp.json`
- Use `/configure:mcp` to install servers into a project; `./cleanup-mcp-servers.sh` to remove them (run only when no Claude sessions are active)
