---
name: MCP Server Management
description: Intelligent MCP server installation and management. Suggests MCP servers based on project context and helps install them project-by-project. Use when configuring MCP servers or when project needs specific integrations.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion
---

# MCP Server Management

Expert knowledge for managing Model Context Protocol (MCP) servers on a project-by-project basis, with intelligent suggestions based on project context.

## Core Expertise

**MCP Server Selection**
- Project context analysis for MCP recommendations
- Category-based server grouping (memory, search, testing, infrastructure, etc.)
- Environment variable requirements detection
- Dependency and compatibility checking

**Installation & Configuration**
- Project-scoped `.mcp.json` creation and management
- User-scoped settings.json management (avoided by default)
- Environment variable setup and validation
- Multi-server coordination

**MCP Server Registry**
- Favorites registry in dotfiles `.chezmoidata.toml`
- Server descriptions, categories, and metadata
- Command configurations and arguments
- Required environment variables

## When to Suggest MCP Servers

### Project Context Indicators

**GitHub Integration** → Suggest `github` MCP
- Detects: `.github/` directory, GitHub Actions workflows, issue templates
- Use cases: PR management, issue tracking, repository operations
- Required: `GITHUB_TOKEN` environment variable

**Browser Testing/E2E** → Suggest `playwright` MCP
- Detects: `playwright.config.*`, E2E test files, browser automation code
- Use cases: Browser automation, visual testing, cross-browser testing
- No special env vars required

**Code Search/Navigation** → Suggest `vectorcode` MCP
- Detects: Large codebases (>100 files), complex directory structures
- Use cases: Semantic code search, concept-based discovery, architecture exploration
- Requires: Initial indexing with `vectorcode index`

**ArgoCD/GitOps** → Suggest `argocd-mcp` MCP
- Detects: ArgoCD application manifests, GitOps repository structure
- Use cases: Deployment management, sync status, rollback operations
- Required: `ARGOCD_SERVER`, `ARGOCD_AUTH_TOKEN` environment variables

**Error Tracking** → Suggest `sentry` MCP
- Detects: Sentry SDK imports, error tracking configuration
- Use cases: Error monitoring, performance tracking, release health
- Required: Sentry API credentials

**Project Management** → Suggest `podio-mcp` MCP
- Detects: Podio integration code, project tracking references
- Use cases: Task management, workflow automation, team coordination
- Required: `PODIO_CLIENT_ID`, `PODIO_CLIENT_SECRET`, `PODIO_APP_ID`, `PODIO_APP_TOKEN`

**Memory/Context** → Suggest `graphiti-memory` or `context7` MCP
- Detects: Long-running projects, complex state management
- Use cases: Persistent memory, context management, knowledge graphs
- Required: `GRAPHITI_API_KEY` (for graphiti-memory)

**Enhanced Reasoning** → Suggest `sequential-thinking` MCP
- Detects: Complex problem-solving tasks, architectural decisions
- Use cases: Step-by-step reasoning, complex analysis, decision trees
- No special env vars required

## MCP Server Categories

### Memory & Knowledge
- **graphiti-memory**: Graph-based memory and knowledge management
- **context7**: Upstash context management

### Search & Code
- **vectorcode**: Semantic code search using embeddings

### Testing & Automation
- **playwright**: Browser automation and testing

### Version Control
- **github**: GitHub API integration (issues, PRs, repos)

### Productivity
- **pal**: PAL (Provider Abstraction Layer) - Multi-provider LLM integration
- **podio-mcp**: Podio project management integration

### Infrastructure & Monitoring
- **argocd-mcp**: ArgoCD GitOps deployment management
- **sentry**: Sentry error tracking and monitoring

### AI Enhancement
- **sequential-thinking**: Enhanced reasoning with sequential thinking

## Installation Workflow

### 1. Analyze Project Context
```bash
# Check for project indicators
ls .github/ 2>/dev/null && echo "GitHub detected"
ls playwright.config.* 2>/dev/null && echo "Playwright detected"
find . -name "*.argo*.yaml" 2>/dev/null | head -1 && echo "ArgoCD detected"
```

### 2. Check Current MCP Configuration
```bash
# Check if .mcp.json exists
cat .mcp.json 2>/dev/null | jq '.mcpServers | keys'
```

### 3. Suggest Relevant Servers
Based on detected project patterns, suggest 2-4 most relevant MCP servers with clear rationale.

Example:
```
📦 Detected project patterns:
- GitHub Actions workflows (.github/workflows/)
- Browser testing setup (playwright.config.ts)
- Large codebase (500+ files)

💡 Suggested MCP servers:
1. github - Manage PRs and issues directly
2. playwright - Enhanced browser testing capabilities
3. vectorcode - Semantic code navigation

Would you like to install these? (Use /configure:mcp command)
```

### 4. Create/Update .mcp.json

**New installation:**
```json
{
  "mcpServers": {
    "github": {
      "command": "go",
      "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    },
    "playwright": {
      "command": "bunx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

**Merge with existing:**
```bash
# Read existing config
existing=$(cat .mcp.json)

# Merge new servers (preserve existing)
jq -s '.[0] * .[1]' <(echo "$existing") <(echo "$new_config") > .mcp.json
```

### 5. Environment Variable Setup

**Check for required env vars:**
```bash
# For github MCP
if ! env | grep -q "GITHUB_TOKEN"; then
  echo "⚠️  GITHUB_TOKEN not set. Add to ~/.api_tokens or project .env"
fi

# For argocd MCP
if ! env | grep -q "ARGOCD_SERVER"; then
  echo "⚠️  ARGOCD_SERVER and ARGOCD_AUTH_TOKEN required"
fi
```

**Recommend location:**
- Project-specific: Create `.env` file (add to .gitignore)
- Cross-project: Add to `~/.api_tokens`
- Team sharing: Use GitHub Secrets or vault

## MCP Server Configurations

### Complete Registry (from dotfiles)

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
  "pal": {
    "command": "uvx",
    "args": ["--from", "git+https://github.com/BeehiveInnovations/pal-mcp-server.git", "pal-mcp-server"]
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
  "sentry": {
    "command": "http",
    "args": [],
    "transport": "http",
    "url": "https://mcp.sentry.dev/mcp"
  },
  "sequential-thinking": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
  }
}
```

## Best Practices

### Project-Scoped by Default
✅ **DO**: Install MCP servers project-by-project in `.mcp.json`
- Avoids context bloat in repos where they're not needed
- Clear project dependencies
- Team-shareable configuration

❌ **DON'T**: Install MCP servers user-scoped in `~/.claude/settings.json`
- Bloats context in every repo
- Hidden dependencies
- Harder to share with team

### Environment Variable Security
✅ **DO**: Use environment variable references
```json
"env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
```

❌ **DON'T**: Hardcode secrets in `.mcp.json`
```json
"env": { "GITHUB_TOKEN": "ghp_actualtoken123" }  // Use environment variable reference instead
```

### Gitignore Strategy
- **Personal projects**: Add `.mcp.json` to `.gitignore` (local preferences)
- **Team projects**: Commit `.mcp.json` (shared tooling)
- **Always ignore**: `.env` files with actual secrets

### Minimal Installation
Only install MCP servers that provide clear value for the current project:
- 1-3 servers: Typical project needs
- 4-6 servers: Complex projects with multiple integrations
- 7+ servers: Consider if all are actually needed

## Troubleshooting

### MCP Server Not Loading
```bash
# Check Claude Code MCP status
claude mcp list

# Verify server command is accessible
which bunx  # for bunx-based servers
which uvx   # for uvx-based servers
which go    # for github server
```

### Environment Variables Not Found
```bash
# Check if env var is set
echo $GITHUB_TOKEN

# Load from .env file
source .env && echo $GITHUB_TOKEN

# Check Claude's env loading
grep -r "GITHUB_TOKEN" ~/.claude/
```

### Restart Required
After installing MCP servers:
1. Save `.mcp.json`
2. Exit Claude Code
3. Restart Claude Code in the project directory
4. Verify servers loaded: check available tools

## Commands Integration

Use `/configure:mcp` command for interactive installation:
- Shows all available servers from registry
- Guides through selection process
- Creates/updates `.mcp.json` automatically
- Validates environment variable requirements

## Examples

### GitHub Repository Project
```json
{
  "mcpServers": {
    "github": {
      "command": "go",
      "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

### E2E Testing Project
```json
{
  "mcpServers": {
    "playwright": {
      "command": "bunx",
      "args": ["-y", "@playwright/mcp@latest"]
    },
    "github": {
      "command": "go",
      "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

### Large Codebase Exploration
```json
{
  "mcpServers": {
    "vectorcode": {
      "command": "uvx",
      "args": ["vectorcode-mcp"],
      "env": { "VECTORCODE_INDEX_PATH": "${HOME}/.vectorcode" }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

### GitOps/Infrastructure Project
```json
{
  "mcpServers": {
    "argocd-mcp": {
      "command": "bunx",
      "args": ["-y", "argocd-mcp@latest", "stdio"],
      "env": {
        "ARGOCD_SERVER": "${ARGOCD_SERVER}",
        "ARGOCD_AUTH_TOKEN": "${ARGOCD_AUTH_TOKEN}"
      }
    },
    "github": {
      "command": "go",
      "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    },
    "sentry": {
      "command": "http",
      "args": [],
      "transport": "http",
      "url": "https://mcp.sentry.dev/mcp"
    }
  }
}
```

## References

- MCP registry: `~/.local/share/chezmoi/.chezmoidata.toml` (mcp_servers section)
- Installation command: `/configure:mcp`
- Claude Code MCP docs: https://docs.claude.com/claude-code/mcp
