# Claude Agent SDK Use Cases

Comprehensive collection of Agent SDK use cases for automating development workflows, infrastructure operations, and productivity tools.

## Overview

The Claude Agent SDK enables programmatic access to Claude Code's capabilities through TypeScript/Python APIs. This document outlines high-impact use cases specifically designed for your dotfiles setup.

**Key SDK Features**:
- Context management with automatic token budget optimization
- Rich tool ecosystem (file ops, code execution, web search, MCP integration)
- Fine-grained permissions and security controls
- Subagent delegation for specialized tasks
- Hooks for intercepting and modifying behavior
- Production-ready error handling and session management

## Use Case Categories

1. [Infrastructure & Operations](#1-infrastructure--operations)
2. [Development Workflow Automation](#2-development-workflow-automation)
3. [Productivity & Optimization](#3-productivity--optimization)
4. [Multi-Repository Management](#4-multi-repository-management)

---

## 1. Infrastructure & Operations

### 1.1 ArgoCD Monitoring Agent ✅ IMPLEMENTED

**Status**: ✅ Complete - Available at `~/.local/bin/argocd-monitor`

**Purpose**: Automated ArgoCD event monitoring with AI-powered root cause analysis

**Features**:
- Watches application health and sync status
- Analyzes events using Claude Agent SDK
- Creates GitHub issues for persistent problems
- Telegram notifications for critical issues
- Runs as systemd service (continuous or timer-based)

**Usage**:
```bash
# One-time run
argocd-monitor --once

# Continuous monitoring
systemctl --user enable --now argocd-monitor.timer

# Dry run (analyze without creating issues)
argocd-monitor --once --dry-run
```

**Implementation**: See `exact_dot_local/exact_bin/executable_argocd-monitor`

**Related Skill**: `argocd-investigation`

---

### 1.2 Infrastructure Drift Detector

**Status**: 💡 Proposed

**Purpose**: Monitor infrastructure configurations and detect drift between desired (Terraform) and actual (cloud) state

**Features**:
- Compares Terraform state with actual infrastructure
- Integrates with ArgoCD for GitOps validation
- Checks Sentry for deployment-related errors
- Creates GitHub issues for critical drift
- Suggests remediation steps

**Implementation Approach**:

```python
# ~/.local/bin/infra-drift-check
from claude_agent_sdk import query, ClaudeAgentOptions
import os

async def detect_drift():
    """Monitor infrastructure drift across Terraform, ArgoCD, and cloud providers"""

    async for msg in query(
        prompt="""
        Check for infrastructure drift:
        1. Use argocd-mcp to query production application states
        2. Compare against Terraform configs in ~/repos/infrastructure
        3. Check Sentry for recent deployment errors
        4. Generate drift report with recommended fixes
        5. For critical drifts, create GitHub issues automatically

        Priority levels:
        - Critical: Security groups changed, IAM policies modified
        - High: Resource counts mismatch, configuration drift
        - Medium: Tag changes, non-critical attributes
        - Low: Metadata differences
        """,
        options=ClaudeAgentOptions(
            allowed_tools=[
                "Read", "Grep", "Bash",
                "mcp__argocd__*",
                "mcp__sentry__*",
                "mcp__github__create_issue"
            ],
            mcp_servers={
                "argocd-mcp": {
                    "command": "bunx",
                    "args": ["-y", "argocd-mcp@latest", "stdio"],
                    "env": {
                        "ARGOCD_SERVER": os.getenv("ARGOCD_SERVER"),
                        "ARGOCD_AUTH_TOKEN": os.getenv("ARGOCD_AUTH_TOKEN")
                    }
                },
                "sentry": {
                    "transport": "http",
                    "command": "https://mcp.sentry.dev/mcp"
                },
                "github": {
                    "command": "go",
                    "args": ["run", "github.com/github/github-mcp-server/cmd/github-mcp-server@latest", "stdio"],
                    "env": {"GITHUB_TOKEN": os.getenv("GITHUB_TOKEN")}
                }
            },
            system_prompt="""You are an infrastructure SRE specializing in drift detection.
            Analyze differences between desired and actual state.
            Focus on security-critical changes and actionable drift."""
        )
    ):
        if msg.type == "result":
            # Send alerts via telegram
            send_alert(msg.result)

# Run as cron: 0 */6 * * * ~/.local/bin/infra-drift-check
```

**Deployment**:
- Systemd timer: Every 6 hours
- Runs in background with low priority
- Alerts sent via telegram for critical drift

**Configuration**:
```json
{
  "terraform_dir": "~/repos/infrastructure",
  "argocd_apps": ["production/*"],
  "sentry_projects": ["backend", "frontend"],
  "github_repo": "your-org/infrastructure",
  "alert_priorities": ["critical", "high"]
}
```

---

### 1.3 Kubernetes Cluster Health Monitor

**Status**: 💡 Proposed

**Purpose**: Proactive monitoring of Kubernetes cluster health with predictive issue detection

**Features**:
- Monitors node health, resource utilization
- Detects pod evictions, node pressure
- Analyzes certificate expiration
- Tracks PVC usage and approaching limits
- Predicts resource exhaustion

**Implementation Approach**:

```python
# ~/.local/bin/k8s-health-monitor
async def monitor_cluster_health():
    """Monitor K8s cluster health and predict issues before they occur"""

    async for msg in query(
        prompt="""
        Analyze Kubernetes cluster health:

        1. Node Health:
           - Check node conditions (Ready, MemoryPressure, DiskPressure)
           - Verify kubelet and container runtime health
           - Check node resource utilization trends

        2. Pod Issues:
           - Detect pods in CrashLoopBackOff
           - Find pods with repeated restarts
           - Check pod evictions (OOMKilled, DiskPressure)

        3. Resource Constraints:
           - PVCs approaching capacity
           - Nodes approaching resource limits
           - Namespace quotas near exhaustion

        4. Certificate Health:
           - Check certificate expiration dates
           - Verify webhook configurations

        5. Network Health:
           - Check CoreDNS health
           - Verify service endpoints
           - Test cluster networking

        Create issues for:
        - Critical: Nodes down, control plane issues
        - High: Resource exhaustion imminent (<7 days)
        - Medium: Degraded performance, warnings
        """,
        options=ClaudeAgentOptions(
            allowed_tools=["Bash", "mcp__github__create_issue"],
            permission_mode="plan",
            system_prompt="You are a K8s SRE specializing in predictive monitoring."
        )
    ):
        # Process results
        pass
```

---

## 2. Development Workflow Automation

### 2.1 Smart Commit Message Generator

**Status**: 💡 Proposed (High Priority)

**Purpose**: Generate perfect conventional commit messages from staged changes

**Features**:
- Analyzes git diff to understand changes
- Generates conventional commit messages
- Detects breaking changes automatically
- Identifies related issues from commit history
- Follows release-please conventions

**Implementation Approach**:

```typescript
// ~/.claude/hooks/pre-bash-git-commit.ts
import { query } from "@anthropic-ai/claude-agent-sdk";
import { exec } from "child_process";

export async function preGitCommitHook() {
  // Get staged changes
  const diff = await execPromise("git diff --staged");
  const recentCommits = await execPromise("git log --oneline -10");

  // Generate conventional commit message
  const result = query({
    prompt: `Analyze this git diff and generate a conventional commit message:

    ${diff}

    Recent commit history for context:
    ${recentCommits}

    Use git-commit-workflow skill patterns.
    Follow the release-please conventions from this repo.

    Consider:
    - Scope based on changed files
    - Breaking changes detection (! suffix)
    - Related issue numbers (search recent commits for patterns)
    - Type: feat, fix, chore, docs, style, refactor, test

    Return ONLY the commit message in this format:
    type(scope): subject

    Optional body explaining why (not what)

    Optional footer with breaking changes or issue refs

    Examples:
    feat(auth): add OAuth2 support
    fix(api): handle timeout edge case
    feat(api)!: redesign authentication

    BREAKING CHANGE: Auth endpoint now requires OAuth2.
    `,
    options: {
      allowedTools: ["Bash"],
      permissionMode: "plan",
      model: "haiku"  // Fast for frequent operation
    }
  });

  for await (const msg of result) {
    if (msg.type === "result") {
      console.log(`\n🤖 Suggested commit message:\n`);
      console.log(msg.result);
      console.log(`\nUse this? (y/n): `);
      // Interactive prompt to use or edit
      return msg.result;
    }
  }
}
```

**Integration**:
- Hook into git commit workflow
- Can be enabled via `.claude/settings.json` hooks
- Falls back to manual commit if hook fails

---

### 2.2 Blueprint-to-Code Automation

**Status**: 💡 Proposed

**Purpose**: Turn PRDs (Product Requirements Documents) into working code automatically

**Features**:
- Extends existing `/blueprint:generate-skills` command
- Orchestrates multi-agent workflows
- Generates code following architecture patterns
- Creates comprehensive tests
- Generates PR with all changes

**Implementation Approach**:

```typescript
// ~/.local/bin/blueprint-execute
import { query } from "@anthropic-ai/claude-agent-sdk";

async function executeBlueprint(prdPath: string) {
  // Phase 1: Generate project-specific skills
  await query({
    prompt: `/blueprint:generate-skills`,
    options: {
      allowedTools: ["Read", "Write", "Glob"],
      settingSources: ["user", "project"]  // Load .claude/ config
    }
  });

  // Phase 2: Multi-agent orchestration
  const result = query({
    prompt: `
    Read the PRD at ${prdPath} and generated skills.

    Use the multi-agent-workflows skill to orchestrate:

    1. research-documentation agent: Analyze requirements thoroughly
    2. git-operations agent: Create feature branch (feat/<feature-name>)
    3. service-design agent: Design architecture following patterns skill
    4. Implementation:
       - Use architecture-patterns skill for structure
       - Use implementation-guides skill for step-by-step
       - Follow testing-strategies skill for TDD
    5. test-architecture agent: Generate comprehensive test suite
    6. code-review agent: Review implementation quality
    7. Create PR using git-branch-pr-workflow skill

    Stream progress updates as you work.
    `,
    options: {
      allowedTools: ["Task", "Read", "Write", "Edit", "Bash"],
      permissionMode: "acceptEdits",
      includePartialMessages: true,  // Real-time progress
      system_prompt: "You are a senior full-stack developer following TDD practices."
    }
  });

  for await (const msg of result) {
    if (msg.type === "partial_assistant") {
      // Update status bar in real-time
      updateStatusBar(msg.content);
    }
  }
}
```

**Workflow**:
```bash
# 1. Write PRD
vim .claude/blueprints/prds/user-authentication.md

# 2. Execute blueprint
blueprint-execute .claude/blueprints/prds/user-authentication.md

# 3. Review generated PR
gh pr view
```

---

### 2.3 PR Review Agent

**Status**: 💡 Proposed

**Purpose**: Automated code review with context-aware suggestions

**Features**:
- Reviews PRs against codebase standards
- Checks for security vulnerabilities
- Verifies test coverage
- Suggests improvements
- Posts review as GitHub comment

**Implementation Approach**:

```python
# GitHub Actions integration (already have .github/workflows/claude-code-review.yml)
# Extend with more sophisticated analysis

async def review_pr(pr_number: int):
    """Comprehensive PR review using multiple perspectives"""

    async for msg in query(
        prompt=f"""
        Review PR #{pr_number} using multiple agents:

        1. security-audit agent: Check for security issues
        2. code-review agent: Review code quality
        3. test-architecture agent: Verify test coverage
        4. documentation agent: Check docs are updated

        For each issue found, provide:
        - Severity (critical/high/medium/low)
        - File and line number
        - Explanation of the issue
        - Suggested fix

        Use gh pr comment to post the review.
        """,
        options=ClaudeAgentOptions(
            allowed_tools=["Task", "Read", "Grep", "Bash"],
            mcp_servers={
                "github": {...}
            }
        )
    ):
        # Process review
        pass
```

---

## 3. Productivity & Optimization

### 3.1 Dotfiles Maintenance Autopilot

**Status**: 💡 Proposed (High Priority)

**Purpose**: Automated weekly maintenance of dotfiles repository

**Features**:
- Checks for deprecated packages
- Updates security vulnerabilities
- Reviews unused skills
- Validates configurations
- Generates maintenance report

**Implementation Approach**:

```python
# ~/.local/bin/dotfiles-autopilot
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions

async def autopilot():
    """Weekly automated dotfiles maintenance"""

    options = ClaudeAgentOptions(
        allowed_tools=["Read", "Edit", "Bash", "Grep"],
        permission_mode="plan",  # Read-only analysis first
        cwd="/home/user/dotfiles",
        system_prompt="You are a dotfiles maintenance expert. Use the chezmoi-expert and shell-expert skills."
    )

    async with ClaudeSDKClient(options=options) as client:
        # Weekly maintenance tasks
        await client.query("""
        Perform weekly dotfiles maintenance:

        1. Security Review:
           - Check for deprecated packages in .chezmoidata.toml
           - Scan for known vulnerabilities in installed tools
           - Review mise.lock for security updates

        2. Performance Analysis:
           - Identify unused skills (check session logs)
           - Find slow-starting tools
           - Suggest optimization opportunities

        3. Configuration Health:
           - Validate all SKILL.md frontmatter
           - Check for broken symlinks
           - Verify systemd services are running

        4. Cleanup Suggestions:
           - Identify duplicate functionality
           - Find unused MCP servers
           - Suggest skills to archive

        5. Update Recommendations:
           - List tools with available updates
           - Prioritize security updates
           - Suggest new tools based on usage patterns

        Generate a markdown report with:
        - Summary of health status
        - Critical items (action required)
        - Recommendations (nice to have)
        - Statistics (skill usage, package count)
        """)

        async for msg in client.receive_response():
            if msg.type == "result":
                # Send report via telegram
                report = msg.result
                send_to_telegram(f"📊 Dotfiles Maintenance Report\n\n{report}")

                # Save report
                with open(Path.home() / ".dotfiles-maintenance-report.md", "w") as f:
                    f.write(report)

# Run weekly via systemd timer or cron
# 0 9 * * 1 ~/.local/bin/dotfiles-autopilot
```

**Deployment**:
- Systemd timer: Every Monday 9 AM
- Report sent via telegram
- Can run in interactive mode for immediate fixes

---

### 3.2 Skill Performance Analytics

**Status**: 💡 Proposed

**Purpose**: Data-driven skill curation and optimization

**Features**:
- Tracks skill invocation frequency
- Measures success rates
- Identifies unused skills
- Suggests skill improvements
- Recommends new skills based on usage patterns

**Implementation Approach**:

```python
# ~/.local/bin/skill-analytics
from claude_agent_sdk import query
from pathlib import Path
import json

async def analyze_skill_usage():
    """Analyze skill usage patterns and effectiveness"""

    skills_dir = Path.home() / ".claude/skills"
    session_logs = Path.home() / ".claude/session-env"

    async for msg in query(
        prompt=f"""
        Analyze skill usage patterns from session logs:

        Skills directory: {skills_dir}
        Session logs: {session_logs}

        Tasks:
        1. Parse session logs to extract skill invocations
        2. Calculate invocation frequency (last 30 days)
        3. Measure success rate (tasks completed vs failed)
        4. Identify skills never used (candidates for archival)
        5. Detect common failure patterns per skill
        6. Analyze correlation between skills (often used together)

        Generate report with:

        ## Top 10 Most Valuable Skills
        (by usage × success rate)

        ## Unused Skills (90+ days)
        (candidates for archival)

        ## Skills with High Failure Rate
        (need improvement)

        ## Recommended New Skills
        (based on common manual tasks)

        ## Skill Correlation Matrix
        (skills often used together)

        ## Optimization Opportunities
        (merge similar skills, split complex ones)
        """,
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Grep", "Bash"],
            permission_mode="plan",
            system_prompt="You are a data analyst specializing in developer productivity."
        )
    ):
        if msg.type == "result":
            # Save report for review
            report_path = Path.home() / ".dotfiles/docs/skill-analytics-report.md"
            with open(report_path, "w") as f:
                f.write(msg.result)

            print(f"Report saved to: {report_path}")

# Run monthly
# 0 10 1 * * ~/.local/bin/skill-analytics
```

---

### 3.3 Session Resume System

**Status**: 💡 Proposed (High Priority)

**Purpose**: Never lose context between sessions - automatic task recovery

**Features**:
- Detects incomplete tasks from previous session
- Resumes with full context
- Suggests next steps
- Maintains task continuity

**Implementation Approach**:

```typescript
// ~/.claude/hooks/session-start.ts
import { ClaudeSDKClient } from "@anthropic-ai/claude-agent-sdk";
import { readFileSync, existsSync } from "fs";
import { join } from "path";

export async function sessionStartHook() {
  const sessionDir = `${process.env.HOME}/.claude/session-env`;
  const lastSessionFile = join(sessionDir, "last-session.json");

  if (!existsSync(lastSessionFile)) {
    return;  // No previous session
  }

  const lastSession = JSON.parse(readFileSync(lastSessionFile, "utf8"));

  if (lastSession.incomplete_tasks?.length > 0) {
    console.log("\n📋 Previous session had incomplete tasks:\n");
    lastSession.incomplete_tasks.forEach((task, i) => {
      console.log(`${i + 1}. ${task.description}`);
    });

    // Auto-resume with context
    const client = new ClaudeSDKClient({
      allowedTools: ["Read", "TodoWrite"],
      permissionMode: "plan"
    });

    await client.query(`
      Previous session context:
      - Working directory: ${lastSession.cwd}
      - Last command: ${lastSession.last_command}
      - Incomplete tasks:
        ${lastSession.incomplete_tasks.map(t => `- ${t.description}`).join('\n        ')}

      Current context:
      - Working directory: ${process.cwd()}
      - Time since last session: ${timeSince(lastSession.timestamp)}

      Should we resume these tasks? If yes:
      1. Use TodoWrite to restore the todo list
      2. Suggest next steps based on context
      3. Check if environment has changed (git status, package updates)
    `);

    for await (const msg of client.receive_response()) {
      console.log(msg);
    }
  }
}

// Also implement SessionStop hook to save state
export async function sessionStopHook() {
  // Save current todo list, working directory, last command
  // Store in ~/.claude/session-env/last-session.json
}
```

**Integration**:
- Enable in `.claude/settings.json` hooks
- Runs automatically on session start/stop
- Graceful fallback if hooks fail

---

## 4. Multi-Repository Management

### 4.1 Multi-Repo Feature Orchestrator

**Status**: 💡 Proposed

**Purpose**: Coordinate feature implementation across multiple microservices

**Features**:
- Synchronizes changes across repos
- Maintains consistent API contracts
- Creates PRs in all affected repos
- Ensures integration tests pass

**Implementation Approach**:

```python
# ~/.local/bin/multi-repo-feature
from claude_agent_sdk import query, ClaudeAgentOptions

async def orchestrate_feature(repos: list[str], feature: str):
    """Coordinate feature implementation across microservices"""

    # Phase 1: Research across all repos
    research_results = []
    for repo in repos:
        async for msg in query(
            prompt=f"""
            Analyze {repo} to determine changes needed for: {feature}

            1. Identify affected components
            2. List required API changes
            3. Determine database migrations needed
            4. Estimate test changes
            5. Check for breaking changes
            """,
            options=ClaudeAgentOptions(
                cwd=repo,
                allowed_tools=["Read", "Grep", "Glob"],
                system_prompt="Use research-documentation agent patterns"
            )
        ):
            if msg.type == "result":
                research_results.append({
                    "repo": repo,
                    "analysis": msg.result
                })

    # Phase 2: Generate API contract
    async for msg in query(
        prompt=f"""
        Based on research results: {research_results}

        Generate OpenAPI spec for {feature} that:
        1. Defines shared data models
        2. Specifies endpoints needed
        3. Documents request/response formats
        4. Includes error responses

        Save as .api-contract/{feature}.yaml
        """,
        options=ClaudeAgentOptions(
            allowed_tools=["Write"]
        )
    ):
        pass

    # Phase 3: Implement in parallel
    for repo in repos:
        async for msg in query(
            prompt=f"""
            Implement {feature} in {repo}.

            Context from other repos: {research_results}
            API contract: .api-contract/{feature}.yaml

            Steps:
            1. Use git-branch-pr-workflow skill to create feature branch
            2. Implement changes following architecture patterns
            3. Write tests following testing strategies
            4. Create PR with reference to API contract

            Ensure backward compatibility during transition.
            """,
            options=ClaudeAgentOptions(
                cwd=repo,
                allowed_tools=["Read", "Edit", "Write", "Bash"],
                permission_mode="acceptEdits"
            )
        ):
            print(f"{repo}: {msg}")

    print("\n✅ Feature implemented across all repos")
    print("📋 Review PRs and coordinate merge order")
```

**Usage**:
```bash
# Implement feature across microservices
multi-repo-feature \
  --repos backend,frontend,api-gateway \
  --feature "user-preferences-v2"
```

---

### 4.2 Cross-Repo Dependency Analyzer

**Status**: 💡 Proposed

**Purpose**: Track dependencies and compatibility across repositories

**Features**:
- Maps dependencies between repos
- Detects version mismatches
- Identifies breaking changes
- Suggests coordinated updates

---

## Implementation Priorities

### Phase 1: High-Impact Quick Wins (1-2 weeks)
1. ✅ **ArgoCD Monitoring Agent** - COMPLETE
2. **Session Resume System** - Improve context continuity
3. **Smart Commit Messages** - Better git workflow
4. **Dotfiles Autopilot** - Reduce maintenance burden

### Phase 2: Development Workflow (2-4 weeks)
5. **Blueprint-to-Code** - Accelerate feature development
6. **PR Review Agent** - Improve code quality
7. **Skill Analytics** - Optimize dotfiles

### Phase 3: Infrastructure (4-6 weeks)
8. **Infrastructure Drift Detector** - Proactive monitoring
9. **K8s Health Monitor** - Predictive alerts
10. **Multi-Repo Orchestrator** - Scale across services

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    User's Dotfiles                       │
│                                                          │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Skills      │  │   Agents     │  │   Commands   │ │
│  │   (33 total)  │  │   (15 total) │  │   (20+ total)│ │
│  └───────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Agent SDK Scripts                     │  │
│  │  - argocd-monitor (✅ implemented)                │  │
│  │  - dotfiles-autopilot                            │  │
│  │  - skill-analytics                               │  │
│  │  - multi-repo-feature                            │  │
│  │  - infra-drift-check                             │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Systemd Services                      │  │
│  │  - argocd-monitor.timer (every 5 min)            │  │
│  │  - dotfiles-autopilot.timer (weekly)             │  │
│  │  - skill-analytics.timer (monthly)               │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
         ┌────────────────────────────────┐
         │   Claude Agent SDK             │
         │   - Context management         │
         │   - Tool orchestration         │
         │   - Permission system          │
         │   - MCP integration            │
         └────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    ┌────▼─────┐    ┌────▼─────┐    ┌────▼─────┐
    │ ArgoCD   │    │ GitHub   │    │ Sentry   │
    │ MCP      │    │ MCP      │    │ MCP      │
    └──────────┘    └──────────┘    └──────────┘
```

---

## Configuration Management

All Agent SDK scripts support configuration via:

1. **Environment Variables** (highest priority)
   ```bash
   export ARGOCD_SERVER="argocd.example.com"
   export GITHUB_TOKEN="ghp_..."
   ```

2. **Config Files** (`.chezmoidata.toml`)
   ```toml
   [argocd_monitor]
   enabled = true
   poll_interval = 300
   ```

3. **Per-Script Config** (`~/.config/<script>/config.json`)
   ```json
   {
     "github_repo": "org/repo",
     "issue_labels": ["auto-detected"]
   }
   ```

---

## Security Considerations

**Secrets Management**:
- Never hardcode tokens in scripts
- Use environment files (`.env`) excluded from git
- Store in `~/.api_tokens` or `~/.config/<tool>/env`
- Use read-only tokens when possible

**Permission Scoping**:
- Use `permission_mode="plan"` for read-only analysis
- Use `permission_mode="acceptEdits"` for automated changes
- Set `allowed_tools` to minimum required
- Review generated changes before commit

**Rate Limiting**:
- Configure polling intervals appropriately
- Use exponential backoff for retries
- Cache results when possible
- Monitor API usage

---

## Monitoring & Observability

**Logging**:
- All scripts log to `~/.config/<script>/monitor.log`
- Systemd journal for service output
- Structured logging for analysis

**Metrics**:
- Track script execution duration
- Monitor success/failure rates
- Count API calls and token usage
- Measure issue creation rate

**Alerting**:
- Critical: Script failures, API errors
- High: Resource constraints, rate limits
- Medium: Warnings, degraded performance
- Low: Informational, statistics

---

## Next Steps

1. **Review** this document and prioritize use cases
2. **Install** Claude Agent SDK: `uv tool install claude-agent-sdk`
3. **Test** existing ArgoCD monitor
4. **Implement** high-priority use cases from Phase 1
5. **Iterate** based on real-world usage

---

## Resources

**Documentation**:
- [Agent SDK Overview](https://docs.claude.com/en/docs/agent-sdk/overview)
- [TypeScript SDK Reference](https://docs.claude.com/en/docs/agent-sdk/typescript)
- [Python SDK Reference](https://docs.claude.com/en/docs/agent-sdk/python)

**Examples**:
- ArgoCD Monitor: `exact_dot_local/exact_bin/executable_argocd-monitor`
- Investigation Skill: `exact_dot_claude/skills/argocd-investigation/`
- GitHub Actions Review: `.github/workflows/claude-code-review.yml`

**Community**:
- Claude Code GitHub: https://github.com/anthropics/claude-code
- Agent SDK Examples: https://github.com/anthropics/claude-agent-sdk-examples
