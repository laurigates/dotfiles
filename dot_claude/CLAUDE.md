# CLAUDE.md

Claude Code configuration system managed by chezmoi for automated AI-assisted development workflows.

## Repository Overview

This is the chezmoi source directory for `~/.claude` - a sophisticated Claude Code configuration system that implements:

- **Multi-Agent Architecture**: 20+ specialized subagents for domain-specific tasks
- **Automated Development Workflows**: Complete CI/CD integration with intelligent issue resolution
- **Real-Time Integration**: Terminal and system-wide status monitoring
- **Persistent Memory**: Learning and context retention across sessions
- **Cross-Project Coordination**: Shared knowledge and task handoffs between agents

## Core Architecture

### Subagent Delegation System
- **Main Agent Protocol**: YAML frontmatter routing to specialized subagents
- **Context Detection**: Automatic role switching based on task tool invocation
- **Memory Integration**: Graphiti-based learning from past executions
- **Agent Ecosystem**: 20+ specialized agents covering all development domains

### Key Agents
- **git-expert**: Version control, GitHub operations, linear history workflows
- **python-developer**: Modern Python with uv, ruff, pytest, type hints
- **code-reviewer**: Comprehensive code analysis and quality assessment
- **security-auditor**: OWASP compliance, vulnerability scanning, threat modeling
- **devops-engineer**: Container orchestration, CI/CD, infrastructure as code
- **memory-keeper**: Knowledge graph management and cross-session learning

### Integration Systems
- **Hooks**: Real-time terminal integration (kitty tabs, SketchyBar)
- **Commands**: Pre-built workflows for common development patterns
- **Workflows**: Multi-agent coordination templates
- **Tasks**: Inter-agent context sharing and state management

## Essential Commands

### Development Workflows
```bash
# Apply configuration changes
chezmoi apply -v

# Automated development loop
/devloop                              # Continuous issue resolution
/devloop --max-cycles 3               # Limited cycle run
/devloop --focus bug                  # Bug-focused development

# Code quality workflows
/codereview                           # Comprehensive code review with fixes
/tdd                                  # Test-driven development setup
/refactor                             # Code refactoring analysis
```

### Agent Management
```bash
# Direct agent invocation (via Claude Code)
claude chat --agent git-expert
claude chat --agent python-developer
claude chat --agent security-auditor

# Command execution
claude chat --file commands/github/quickpr.md
claude chat --file commands/setup/init-project.md
```

### Status Monitoring
```bash
# Terminal integration (automatic)
kitty @ set-tab-title "repo | status"  # Dynamic tab titles
tail -f /tmp/claude_status_hub.log     # Activity monitoring

# SketchyBar integration (automatic)
sketchybar --trigger claude_status     # System-wide status updates
```

## Agent Structure

### Agent Definition Format
```yaml
---
name: agent-name
color: "#HEX_COLOR"
description: Agent purpose and capabilities
tools: [list of available MCP tools]
execution_log: true
---

<role>
Agent role definition
</role>

<core-expertise>
Domain-specific knowledge areas
</core-expertise>

<workflow>
Step-by-step execution process
</workflow>
```

### Memory-Enhanced Agents
All agents include:
- **Sequential Thinking**: `mcp__sequential-thinking__*` tools for structured reasoning
- **Memory Integration**: `mcp__graphiti-memory__*` tools for persistent learning
- **Context Awareness**: Access to past execution patterns and outcomes

## Configuration Management

### Settings Template (`settings.json.tmpl`)
- **Permissions**: Tool access control for security
- **Model Selection**: Dynamic model configuration with fallbacks
- **Hook Integration**: Event-driven terminal and system integration
- **State Preservation**: Existing configuration preservation during updates

### Hook System
- **UserPromptSubmit**: Pre-processing, status updates, context preparation
- **AssistantResponseStart**: Response initiation tracking, tab title updates
- **AssistantResponseComplete**: Completion processing, ready state indication

## Memory Integration

### Knowledge Graph Storage
```python
# Agent execution tracking
mcp__graphiti-memory__add_memory(
    name=f"Agent Execution: {agent_name}",
    episode_body=json.dumps({
        "agent": agent_name,
        "input_received": input_data,
        "actions_taken": action_list,
        "verification_status": "MATCH|PARTIAL|MISMATCH",
        "lessons_learned": insights_list
    }),
    source="json",
    group_id=f"{agent_name}_executions"
)
```

### Group ID Conventions
- `git_operations` - Version control operations
- `python_development` - Python project work
- `security_audits` - Security assessments
- `workflow_executions` - Multi-agent workflows
- `delegation_history` - Main agent delegation patterns

## Advanced Workflows

### DevLoop Automation
1. **Environment Assessment**: Test execution, failure analysis
2. **Issue Creation**: Automatic GitHub issue generation from failures
3. **Intelligent Selection**: Priority-based issue selection
4. **TDD Implementation**: Red-Green-Refactor cycle with CI integration
5. **PR Management**: Automated pull request creation and monitoring

### Multi-Agent Coordination
- **Context Sharing**: `tasks/inter-agent-context.json` for state handoffs
- **Workflow Templates**: `workflows/` directory with coordination patterns
- **Memory Synchronization**: Shared knowledge graphs across agents
- **Progress Tracking**: Real-time coordination through status systems

## Integration Points

### Terminal Integration (Kitty)
- **Dynamic Tab Titles**: Repository and status display
- **Central Hub**: Dedicated monitoring tab with activity feed
- **Real-Time Updates**: Hook-driven status propagation
- **Cross-Session Tracking**: Multi-repository activity monitoring

### System Integration
- **SketchyBar**: macOS status bar integration
- **Git Hooks**: Repository-aware status updates
- **Chezmoi**: Configuration template management
- **GitHub**: Issue/PR automation and CI/CD integration

### Documentation Integration
- **Context7**: Real-time documentation fetching for current tools/frameworks
- **Memory Graphs**: Persistent documentation and learning patterns
- **Agent Knowledge**: Domain-specific best practices and patterns

## Development Environment

### Tool Integration
- **GitHub MCP**: Repository operations, issue/PR management
- **Context7 MCP**: Current documentation and best practices
- **Graphiti Memory**: Persistent learning and context retention
- **Sequential Thinking**: Structured problem-solving and reasoning

### Platform Support
- **Cross-Platform**: macOS/Linux compatibility through chezmoi templates
- **Terminal Agnostic**: Kitty integration with fallback support
- **Tool Detection**: Automatic detection of project types and toolchains

## Security Considerations

### Permission Model
- **Tool Allowlists**: Explicit permission for sensitive operations
- **Context Isolation**: Agent-specific access controls
- **Memory Sanitization**: Automatic removal of sensitive data from persistent storage
- **Hook Security**: Sandboxed execution with timeout limits

### Data Privacy
- **Local Storage**: All memory and configuration stored locally
- **No External Transmission**: Memory graphs remain on local system
- **Sanitized Logging**: Sensitive data filtered from status logs
- **Secure Defaults**: Conservative permission model with explicit allowlists

## Debugging and Monitoring

### Status Monitoring
```bash
# Real-time activity monitoring
tail -f /tmp/claude_status_hub.log

# Agent execution logs (when enabled)
ls ~/.claude/logs/

# Memory graph inspection
claude chat --agent memory-keeper "show recent executions"
```

### Troubleshooting
```bash
# Hook execution verification
chmod +x ~/.claude/hooks/*.sh
~/.claude/hooks/user-prompt-submit.sh  # Test manually

# Kitty integration testing
kitty @ set-tab-title "test"

# Memory system health
claude chat --agent memory-keeper "graph health check"
```

## Customization

### Adding New Agents
1. Create `agents/new-agent.md` with proper frontmatter
2. Include required tool permissions in configuration
3. Add memory integration and sequential thinking tools
4. Test delegation from main agent

### Extending Workflows
1. Create command files in `commands/` hierarchy
2. Define multi-agent coordination in `workflows/`
3. Update task templates for context sharing
4. Test end-to-end execution flow

### Hook Customization
- Modify hook scripts for different terminal integrations
- Adjust status message formats and displays
- Add custom monitoring and alerting systems
- Integrate with additional development tools

## Key Files

### Core Configuration
- `settings.json.tmpl` - Main Claude Code configuration template
- `private_CLAUDE.md` - Global delegation protocol and development principles

### Agent Definitions
- `agents/*.md` - Individual agent configurations and capabilities
- `agents/dot_claude/settings.local.json` - Local agent overrides

### Automation
- `commands/**/*.md` - Reusable command templates and workflows
- `hooks/executable_*.sh` - Event-driven integration scripts
- `workflows/*.md` - Multi-agent coordination patterns

### Coordination
- `tasks/inter-agent-context.json` - Cross-agent state sharing
- `tasks/agent-queue.md` - Agent execution queue management
- `status/agent-progress-template.md` - Progress tracking templates

This system represents a comprehensive AI-assisted development environment that learns, adapts, and provides seamless integration across tools, projects, and development workflows.
