# Chezmoi Conventions

Derived from git history patterns (1404 commits, 2018–2026).

## File Naming Prefixes

| Prefix | Meaning | Example |
|--------|---------|---------|
| `dot_` | Creates `.filename` target | `dot_zshrc.tmpl` → `~/.zshrc` |
| `private_` | Mode 0600 (owner-only) | `private_dot_config/` |
| `exact_` | Remove orphaned files in directory | `exact_dot_claude/` |
| `.tmpl` suffix | Chezmoi template with Go text/template syntax | `dot_zshrc.tmpl` |

## Template Conventions

- Use `{{ .chezmoi.os }}` for platform branching, not runtime detection
- Use `.chezmoidata.toml` and `.chezmoidata/` for structured template data
- Keep templates readable: extract complex logic to helper templates or scripts
- Template variables for lists (packages, completions, MCP servers) go in `.chezmoidata/`

## Directory Semantics

- `exact_dot_claude/` — Orphaned files auto-removed on `chezmoi apply`; critical for keeping `.claude/` clean
- `private_dot_config/` — Secret-adjacent configs; mode 0600
- Never create a `.claude/` directory in the chezmoi source — it's gitignored and used as a runtime directory

## Source vs Target

- **Always edit** source files at `~/.local/share/chezmoi/`
- **Never edit** target files directly (e.g., `~/.zshrc`)
- After modifying `exact_dot_claude/rules/`, run `chezmoi apply --force ~/.claude`
- Use `chezmoi diff` to preview changes before applying

## Script Conventions

- `run_onchange_*` scripts execute when their template hash changes
- `run_once_*` scripts execute only on first apply
- Scripts should be idempotent — safe to re-run

## Deprecation Patterns

From commit history: promptly replace deprecated tools and APIs:
- `docker-compose` → `docker compose` (CLI v2)
- `vim.loop` → `vim.uv` (Neovim API)
- `detect-secrets` → `gitleaks` (secret scanning)
- `curl|sh` → setup actions (CI security)
