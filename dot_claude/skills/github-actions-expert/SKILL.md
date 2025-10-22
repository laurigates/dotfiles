---
name: GitHub Actions Expert
description: Expert knowledge for creating and managing Claude Code GitHub Actions workflows, including MCP server configuration, tool permissions, authentication methods, and automation patterns. Automatically assists with CI/CD pipeline design, security best practices, and troubleshooting.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch, mcp__github
---

# GitHub Actions Expert

Expert knowledge for designing and implementing GitHub Actions workflows that integrate Claude Code for automated code assistance, PR reviews, and issue triage.

## Core Expertise

**Claude Code Action Architecture**
- GitHub Actions workflow design for Claude Code integration
- MCP (Model Context Protocol) server configuration and permissions
- Authentication methods (Anthropic API, AWS Bedrock, Google Vertex AI)
- Tool access control and security boundaries

**Automation Patterns**
- Issue triage and automated responses
- Pull request reviews with inline comments
- CI failure auto-fix workflows
- Custom trigger configurations and event handling

**Security & Best Practices**
- Secrets management and secure credential handling
- Permission scoping and least-privilege access
- Prompt injection prevention
- Commit signing and audit trails

## Essential Workflow Template

```yaml
name: Claude Code

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]

jobs:
  claude:
    if: |
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
      (github.event_name == 'issues' && contains(github.event.issue.body, '@claude'))
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      issues: write
      id-token: write
      actions: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@v5
        with:
          fetch-depth: 1

      - name: Run Claude Code
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

## MCP Server Configuration

### Single MCP Server (Node.js)
```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    claude_args: |
      --mcp-config '{"mcpServers":{"github":{"command":"node","args":["/path/to/server.js"]}}}'
```

### Multiple MCP Servers with Secrets
```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    claude_args: |
      --mcp-config '{
        "mcpServers": {
          "github": {
            "command": "node",
            "args": ["./github-mcp/dist/index.js"],
            "env": {"GITHUB_TOKEN": "${{ secrets.GITHUB_TOKEN }}"}
          },
          "postgres": {
            "command": "uvx",
            "args": ["mcp-server-postgres", "--connection-string", "${{ secrets.DB_URL }}"]
          }
        }
      }'
```

## Tool Access Control

### Allow Specific Bash Commands
```yaml
claude_args: |
  --allowedTools 'Bash(npm:*)' 'Bash(pytest:*)' 'Bash(cargo:*)'
```

### Enable GitHub Actions Access
```yaml
permissions:
  actions: read  # Required for CI/CD tools

claude_args: |
  --allowedTools 'Bash(gh run:*)' 'Bash(gh workflow:*)'
```

### Block Dangerous Operations
```yaml
claude_args: |
  --allowedTools 'Bash(docker build:*)'
  --disallowedTools 'Bash(docker push:*)' 'Bash(rm -rf:*)'
```

## Authentication Methods

### Anthropic Direct API
```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

### AWS Bedrock
```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: us-east-1

- uses: anthropics/claude-code-action@v1
  with:
    claude_args: --bedrock-region us-east-1
```

### Google Vertex AI
```yaml
- uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_CREDENTIALS }}

- uses: anthropics/claude-code-action@v1
  with:
    claude_args: |
      --vertex-project-id ${{ secrets.GCP_PROJECT_ID }}
      --vertex-region us-central1
```

## Security Best Practices

### Critical Rules
- **NEVER hardcode credentials** - Always use `${{ secrets.SECRET_NAME }}`
- **Minimal permissions** - Grant only required permissions
- **Validate external inputs** - Sanitize content from untrusted sources
- **Enable commit signing** - Automatic with `contents: write` permission
- **Review generated code** - Always review before merging

### Secure Configuration
```yaml
permissions:
  contents: write        # Required for code changes
  pull-requests: write   # Required for PR operations
  issues: write          # Required for issue operations
  id-token: write        # Required for OIDC
  actions: read          # Only if CI/CD access needed
  # Never grant more than necessary
```

## Quick Setup

1. **Install Claude GitHub App**: https://github.com/apps/claude
2. **Add API Key**: Repository Settings → Secrets → `ANTHROPIC_API_KEY`
3. **Create Workflow**: `.github/workflows/claude.yml` (use template above)
4. **Test**: Create issue and comment `@claude Hello!`
5. **(Optional)** Add `CLAUDE.md` in repo root for project standards

## Common Patterns

### CI Failure Auto-Fix
```yaml
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]

jobs:
  auto-fix:
    if: github.event.workflow_run.conclusion == 'failure'
    # ... use claude-code-action to analyze and fix
```

### Path-Filtered PR Review
```yaml
on:
  pull_request:
    paths:
      - 'backend/**'
      - 'api/**'
```

### Custom Trigger Phrase
```yaml
if: contains(github.event.comment.body, '/claude-review')
# with:
#   trigger_phrase: "/claude-review"
```

## Troubleshooting

### Workflow Not Triggering
- Check trigger conditions in `if:` clause
- Verify permissions (contents, pull-requests, issues)
- Check GitHub App installation

### MCP Server Errors
- Verify server command and args
- Check environment variables exist
- Test server locally first

### Authentication Failures
- Verify secret name matches workflow
- Check API key format (starts with `sk-ant-api03-`)
- Ensure secret exists in repository settings

For detailed reference documentation and advanced patterns, see REFERENCE.md.
