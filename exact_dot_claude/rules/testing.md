# Testing Requirements

## Test Tiers

| Tier | Command | When |
|------|---------|------|
| Lint | `mise run lint` or `just lint` | After every change |
| Shell | `mise run lint:shell` | After modifying shell scripts |
| Lua | `mise run lint:lua` | After modifying Neovim config |
| Actions | `mise run lint:actions` | After modifying workflows |
| Full | `mise run test` | Before committing |
| Docker | `mise run test:docker` | For environment changes |

## Linting Standards

- Shell scripts: shellcheck with `.shellcheckrc` config
- Lua (Neovim): luacheck with `.luacheckrc` config
- GitHub Actions: actionlint
- Lua formatting: stylua with `.stylua.toml`
- Secrets: gitleaks with `.gitleaks.toml`
- Pre-commit: `pre-commit run --all-files`

## Coverage Expectations

Shell scripts and config files — focus on linting compliance and smoke test passing rather than unit coverage.
