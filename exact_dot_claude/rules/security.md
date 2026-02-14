# Security

## API Token Management

- API tokens stored in `~/.api_tokens` (not in repo)
- Private files use `private_` prefix in chezmoi
- No secrets committed to version control
- Use environment variable references like `${GITHUB_TOKEN}` in configuration

## MCP Server Security

- Never hardcode tokens in `.mcp.json`
- Always use environment variable references
- Project-scoped MCP servers over user-scoped to avoid context bloat
