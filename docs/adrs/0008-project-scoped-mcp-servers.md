# ADR-0008: Project-Scoped MCP Servers

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

MCP (Model Context Protocol) servers extend Claude Code with specialized capabilities:
- `github` - GitHub API integration for issues, PRs, repos
- `context7` - Documentation lookup and context management
- `playwright` - Browser automation and testing
- `vectorcode` - Semantic code search using embeddings
- `sequential-thinking` - Enhanced reasoning for complex tasks

### The User-Scoped Problem

Initially, MCP servers were configured in the user-scoped settings file:

```
~/.claude/settings.json
  └── mcpServers: { github, playwright, vectorcode, ... }
```

**Problems with user-scoped configuration:**

1. **Context bloat** - All MCP tools loaded in every repository
   - Working on a simple script? Still loading Kubernetes, Playwright, Sentry tools
   - Token usage increases with unnecessary tool descriptions

2. **Hidden dependencies** - Team can't see what MCP servers a project needs
   - "Why doesn't this work?" → Missing MCP server not in user settings
   - Onboarding requires manual MCP configuration

3. **Environment pollution** - Irrelevant tools appear in suggestions
   - "Add a test" → Playwright suggestions in a CLI tool project
   - Cognitive load from filtering irrelevant options

4. **No reproducibility** - Each developer configures differently
   - Different MCP servers = different Claude behavior
   - Hard to debug team-wide issues

### MCP Server Categories

Analysis revealed distinct server categories:

| Category | Examples | Scope |
|----------|----------|-------|
| **Version Control** | github | Most projects |
| **Documentation** | context7 | Research-heavy projects |
| **Testing** | playwright | Web projects |
| **Search** | vectorcode | Large codebases |
| **Infrastructure** | argocd-mcp, sentry | DevOps projects |
| **Productivity** | podio-mcp | Specific workflows |
| **AI** | sequential-thinking, pal | Complex reasoning |

Not every project needs every server.

## Decision

**Manage MCP servers per-project** via `.mcp.json` in project root, with a favorites registry in `.chezmoidata.toml` for easy installation.

### Project-Scoped Configuration

Each project declares its MCP dependencies:

```json
// .mcp.json (in project root, committed to git)
{
  "mcpServers": {
    "github": {
      "command": "go",
      "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"]
    },
    "context7": {
      "command": "bunx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

**Benefits:**
- Team shares the same MCP configuration via git
- Only relevant servers loaded per project
- Clear project dependencies
- Reproducible across developers

### Favorites Registry

Maintain curated MCP server configurations in `.chezmoidata.toml`:

```toml
[mcp_servers.github]
  enabled = false  # Disabled by default
  scope = "project"
  command = "go"
  args = ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"]
  description = "GitHub API integration"
  category = "vcs"
  env_vars = ["GITHUB_TOKEN"]

[mcp_servers.playwright]
  enabled = false
  scope = "project"
  command = "bunx"
  args = ["-y", "@playwright/mcp@latest"]
  description = "Browser automation and testing"
  category = "testing"
```

**Why disabled by default?**
- Avoids bloating every project's context
- Forces explicit decision about which servers to enable
- Registry serves as documentation, not auto-installation

### Installation Workflow

**Interactive (recommended):**
```bash
/configure:mcp  # Claude command for guided installation
```

**Manual:**
1. Check available servers in `.chezmoidata.toml`
2. Copy configuration to project's `.mcp.json`
3. Set required environment variables

### Intelligent Suggestions

The **mcp-management skill** suggests servers based on project structure:

| Project Signal | Suggested Server |
|----------------|------------------|
| `.github/` directory | github |
| `playwright.config.*` | playwright |
| Large codebase (>1000 files) | vectorcode |
| `.argocd/` or ArgoCD refs | argocd-mcp |
| `sentry.client.config.*` | sentry |

### Environment Variables

Servers requiring API tokens reference environment variables:

```json
{
  "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
}
```

**Token storage:**
- `~/.api_tokens` - Sourced by shell (gitignored)
- Project `.env` - Local overrides (gitignored)

**Never hardcode tokens in `.mcp.json`**

## Consequences

### Positive

1. **Clean context** - Only relevant MCP tools per project
2. **Team alignment** - Shared configuration via git
3. **Explicit dependencies** - Clear what a project needs
4. **Reduced confusion** - No irrelevant tool suggestions
5. **Faster startup** - Fewer servers to initialize

### Negative

1. **Initial setup** - Must configure `.mcp.json` per project
2. **Duplication** - Similar configs across related projects
3. **Discovery** - New developers must know about registry
4. **Maintenance** - Update configs when servers change

### Migration Path

**From user-scoped to project-scoped:**

1. Identify which MCP servers current project actually uses
2. Create `.mcp.json` with only needed servers
3. Remove servers from `~/.claude/settings.json` (optional)
4. Commit `.mcp.json` to git

### Server Selection Guide

| Project Type | Recommended Servers |
|--------------|---------------------|
| **CLI Tool** | github |
| **Web App** | github, playwright |
| **Large Monorepo** | github, vectorcode |
| **DevOps/Infrastructure** | github, argocd-mcp, context7 |
| **Research/Documentation** | github, context7 |
| **Complex Reasoning** | sequential-thinking |

## Alternatives Considered

### Keep User-Scoped Only
Continue with all servers in `~/.claude/settings.json`.

**Rejected because**: Context bloat, no team sharing, hidden dependencies.

### Workspace-Level Configuration
Configure at IDE/editor workspace level.

**Rejected because**: Not portable across editors; Claude Code uses `.mcp.json`.

### Auto-Detection Only
Automatically enable servers based on project structure.

**Rejected because**: May enable unwanted servers; explicit configuration preferred.

### Monorepo-Wide Configuration
Single config for entire monorepo.

**Rejected because**: Different packages may need different servers; too coarse-grained.

## Related Decisions

- ADR-0002: Unified Tool Version Management (similar project-scoped philosophy)
- ADR-0006: Documentation-First Development (context7 for research)
- ADR-0004: Subagent-First Delegation (agents may use MCP servers)

## References

- Project MCP config: `.mcp.json`
- Favorites registry: `.chezmoidata.toml` (`[mcp_servers]` section)
- MCP management skill: `exact_dot_claude/skills/mcp-management/`
- Installation command: `/configure:mcp`
