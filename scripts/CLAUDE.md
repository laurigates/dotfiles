# CLAUDE.md - Maintenance Scripts

Utility scripts for Claude Code infrastructure automation.

## Scripts

| Script | Purpose |
|--------|---------|
| `generate-claude-completion.sh` | Generate zsh completions for Claude CLI from `--help` output → `dot_zfunc/_claude` |
| `generate-claude-completion-simple.sh` | Simplified fallback completion generator with hardcoded lists |
| `migrate-command-namespaces.sh` | Migrate commands from flat structure to namespace hierarchy (supports `--dry-run`) |
| `update-command-references.sh` | Update markdown references after namespace migration (supports `--dry-run`) |
| `audit-secrets-baseline.py` | Audit secrets baseline file |
| `audit-secrets-selective.py` | Selective secrets audit |
| `smoke-test-docker.sh` | Docker-based smoke tests for dotfiles |

All shell scripts support `--help`. Run `shellcheck scripts/*.sh` to lint.
