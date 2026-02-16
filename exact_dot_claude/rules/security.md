# Security

## API Token Management

- API tokens stored in `~/.api_tokens` (not in repo)
- Private files use `private_` prefix in chezmoi
- Keep secrets out of version control
- Use environment variable references like `${GITHUB_TOKEN}` in configuration

## MCP Server Security

- Use environment variable references for all tokens in `.mcp.json`
- Prefer project-scoped MCP servers for focused context
