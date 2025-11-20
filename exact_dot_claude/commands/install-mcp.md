---
description: "Install MCP servers for this project from favorites registry"
allowed_tools: [Bash, Write, Read, Edit, AskUserQuestion]
---

Install Model Context Protocol (MCP) servers for this project.

**Available MCP Servers** (from dotfiles favorites registry):

**Memory & Knowledge:**
- `graphiti-memory` - Graph-based memory and knowledge management
- `context7` - Upstash context management

**Search & Code:**
- `vectorcode` - Semantic code search using embeddings

**Testing & Automation:**
- `playwright` - Browser automation and testing

**Version Control:**
- `github` - GitHub API integration (issues, PRs, repos)

**Productivity:**
- `zen-mcp-server` - Zen productivity and focus tools
- `podio-mcp` - Podio project management integration

**Infrastructure & Monitoring:**
- `argocd-mcp` - ArgoCD GitOps deployment management
- `sentry` - Sentry error tracking and monitoring

**AI Enhancement:**
- `sequential-thinking` - Enhanced reasoning with sequential thinking

**Steps**:

1. **Check current MCP configuration**:
   - Look for `.mcp.json` in project root
   - If exists, read current configuration
   - Show currently installed servers

2. **Ask user which servers to install**:
   - Use AskUserQuestion tool to ask which servers to add
   - Support multiple selections (comma-separated or list)
   - Show descriptions and categories to help decision

3. **Create/update `.mcp.json`**:
   - If file doesn't exist, create new configuration
   - If file exists, merge new servers with existing ones
   - Use proper JSON structure with mcpServers object

4. **Handle environment variables**:
   - For servers requiring env vars (github, podio-mcp, argocd-mcp), note required variables
   - Remind user to set them in project `.env` or `~/.api_tokens`
   - Example:
     - `github`: Requires `GITHUB_TOKEN`
     - `podio-mcp`: Requires `PODIO_CLIENT_ID`, `PODIO_CLIENT_SECRET`, `PODIO_APP_ID`, `PODIO_APP_TOKEN`
     - `argocd-mcp`: Requires `ARGOCD_SERVER`, `ARGOCD_AUTH_TOKEN`

5. **MCP Server Configurations**:

   ```json
   {
     "graphiti-memory": {
       "command": "npx",
       "args": ["-y", "@getzep/graphiti-mcp-server"],
       "env": { "GRAPHITI_API_KEY": "${GRAPHITI_API_KEY}" }
     },
     "vectorcode": {
       "command": "uvx",
       "args": ["vectorcode-mcp"],
       "env": { "VECTORCODE_INDEX_PATH": "${HOME}/.vectorcode" }
     },
     "zen-mcp-server": {
       "command": "uvx",
       "args": ["--from", "git+https://github.com/BeehiveInnovations/zen-mcp-server.git", "zen-mcp-server"]
     },
     "playwright": {
       "command": "bunx",
       "args": ["-y", "@playwright/mcp@latest"]
     },
     "context7": {
       "command": "bunx",
       "args": ["-y", "@upstash/context7-mcp"]
     },
     "github": {
       "command": "go",
       "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"],
       "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
     },
     "podio-mcp": {
       "command": "bunx",
       "args": ["https://github.com/ForumViriumHelsinki/podio-mcp"],
       "env": {
         "PODIO_CLIENT_ID": "${PODIO_CLIENT_ID}",
         "PODIO_CLIENT_SECRET": "${PODIO_CLIENT_SECRET}",
         "PODIO_APP_ID": "${PODIO_APP_ID}",
         "PODIO_APP_TOKEN": "${PODIO_APP_TOKEN}"
       }
     },
     "argocd-mcp": {
       "command": "bunx",
       "args": ["-y", "argocd-mcp@latest", "stdio"],
       "env": {
         "ARGOCD_SERVER": "${ARGOCD_SERVER}",
         "ARGOCD_AUTH_TOKEN": "${ARGOCD_AUTH_TOKEN}"
       }
     },
     "sequential-thinking": {
       "command": "npx",
       "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
     }
   }
   ```

6. **Add to .gitignore (optional)**:
   - Ask if user wants to add `.mcp.json` to `.gitignore`
   - Personal projects → recommend ignoring (keep API configs local via .gitignore)
   - Team projects → recommend committing (share MCP setup)

7. **Report installation**:
   ```
   ✅ MCP servers configured!

   Added to .mcp.json:
   - github (requires GITHUB_TOKEN)
   - vectorcode
   - playwright

   Next steps:
   1. Restart Claude Code to load new MCP servers
   2. Set required environment variables in ~/.api_tokens or project .env
   3. Verify servers with: ls ~/.claude/mcp-servers/

   Tip: Run this command again to add more servers anytime.
   ```

**Important Notes**:
- MCP servers are project-scoped (only available in this repo)
- To install globally, manually edit `~/.claude/settings.json`
- Server configurations are maintained in your dotfiles `.chezmoidata.toml`
- See `~/.local/share/chezmoi/.chezmoidata.toml` for full registry
