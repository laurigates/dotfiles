# CLAUDE.md - Maintenance Scripts

Utility scripts for Claude Code infrastructure automation.

## Scripts

| Script | Purpose |
|--------|---------|
| `generate-claude-completion.sh` | Generate zsh completions for Claude CLI from `--help` output → `dot_zfunc/_claude` |
| `generate-claude-completion-simple.sh` | Simplified fallback completion generator with hardcoded lists |
| `migrate-command-namespaces.sh` | Migrate commands from flat structure to namespace hierarchy (supports `--dry-run`) |
| `update-command-references.sh` | Update markdown references after namespace migration (supports `--dry-run`) |
| `smoke-test-docker.sh` | Docker-based smoke tests for dotfiles |
| `check-doc-references.py` | Flag docs that reference scripts/paths/links no longer in the repo (advisory pre-commit hook; strict via `mise run lint:docs`). See `.doc-reference-allow` for scoping and `scripts/tests/test-check-doc-references.sh` for the contract. |
| `claude-perms-sweep.py` | Ensure permission allow-rules exist in every repo's **committed** `.claude/settings.json` — the only place rules reach Claude Code web/remote. Discovers repos from GitHub (not local clones) and patches via the API, so dirty trees and feature-branch checkouts are untouched. Dry-run by default; driven by `just -g claude-perms-sweep <scope> <rules>`. |

All shell scripts support `--help`. Run `shellcheck scripts/*.sh` to lint.
