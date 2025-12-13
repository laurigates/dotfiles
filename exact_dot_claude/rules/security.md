# Security

## API Token Management

- API tokens stored in `~/.api_tokens` (not in repo)
- Private files use `private_` prefix in chezmoi
- No secrets committed to version control
- Use environment variable references like `${GITHUB_TOKEN}` in configuration

## Secret Scanning

### Pre-commit Hooks

- **detect-secrets** pre-commit hook prevents accidental secret commits
- **TruffleHog** scans for leaked credentials in git history
- Both tools run automatically on commit via pre-commit hooks

### Manual Scanning

```bash
# Scan for new secrets
detect-secrets scan --baseline .secrets.baseline

# Review flagged secrets
detect-secrets audit .secrets.baseline

# Run via pre-commit
pre-commit run detect-secrets --all-files
```

## Git Workflow Security

- Run security checks before staging files
- Never commit files that likely contain secrets (.env, credentials.json, etc.)
- Warn if specifically requested to commit sensitive files

## MCP Server Security

- Never hardcode tokens in `.mcp.json`
- Always use environment variable references
- Project-scoped MCP servers over user-scoped to avoid context bloat
