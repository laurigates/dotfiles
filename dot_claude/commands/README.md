# Claude Code Commands

This document provides a comprehensive overview of available slash commands and their integration with specialized agents. Commands can be invoked directly or called by agents using the SlashCommand tool for workflow automation.

## Command Categories

### 🚀 Project Initialization
- `/project:init <name> [type]` - Base project initialization
- `/setup:new-project [type]` - Language-specific project setup
- `/setup:release <version>` - Create and publish releases

### 🧪 Testing & Quality
- `/test:run [pattern]` - Universal test runner (auto-detects framework)
- `/tdd [--coverage]` - Test-driven development setup
- `/lint:check [--fix]` - Universal linter (auto-detects tools)
- `/refactor <code>` - Code quality improvements
- `/codereview [path]` - Comprehensive code review

### 📦 Dependencies
- `/deps:install [packages]` - Universal dependency installer
- `/chore:modernize` - Update dependencies and patterns

### 📝 Documentation
- `/docs:docs [--github-pages]` - Set up documentation system
- `/docs:update` - Update documentation from code
- `/build-knowledge-graph` - Build Obsidian vault graph

### 🔄 Git & GitHub
- `/git:smartcommit [branch]` - Create logical commits
- `/git:repo-maintenance` - Repository cleanup
- `/github:quickpr [title]` - Create pull request
- `/github:fix-pr <number>` - Fix failing PR checks
- `/github:process-issues` - Process multiple issues
- `/github:process-single-issue <num>` - Process single issue

### 🔧 Specialized Tools
- `/assimilate <path>` - Analyze project configurations
- `/disseminate` - Sync GitHub and Podio
- `/google-chat-format` - Format for Google Chat
- `/handoff <resource> <type>` - Generate handoff docs

### 🧪 Experimental
- `/experimental:devloop` - Automated development loop
- `/experimental:devloop-zen` - AI-powered dev loop
- `/experimental:modernize` - Experimental modernization

## Command-Agent Alignment

### Development Agents

| Agent | Common Commands |
|-------|-----------------|
| **python-development** | `/project:init python`, `/deps:install`, `/test:run`, `/lint:check`, `/tdd` |
| **nodejs-development** | `/project:init node`, `/deps:install`, `/test:run`, `/lint:check`, `/tdd` |
| **rust-development** | `/project:init rust`, `/deps:install`, `/test:run`, `/lint:check`, `/tdd` |
| **cpp-development** | `/project:init generic`, `/test:run`, `/lint:check`, `/tdd` |

### Infrastructure Agents

| Agent | Common Commands |
|-------|-----------------|
| **kubernetes-operations** | `/docs:docs`, `/git:smartcommit`, `/lint:check` |
| **terraform-infrastructure** | `/docs:update`, `/codereview`, `/git:smartcommit` |
| **container-development** | `/setup:new-project`, `/github:quickpr` |

### Quality Agents

| Agent | Common Commands |
|-------|-----------------|
| **code-review** | `/codereview`, `/refactor`, `/lint:check` |
| **security-audit** | `/codereview`, `/git:smartcommit` |
| **test-architecture** | `/tdd`, `/test:run` |

## SlashCommand Integration

### In Commands

Commands can call other commands using the SlashCommand tool:

```yaml
---
allowed-tools: SlashCommand, Read, Write
---
# Compose workflows by calling other commands
Use SlashCommand: `/test:run --coverage`
Use SlashCommand: `/lint:check --fix`
Use SlashCommand: `/git:smartcommit`
```

### In Agents

Agents include SlashCommand in their tools list to leverage commands:

```yaml
---
tools: [..., SlashCommand]
---
## Available Commands
- `/tdd` - Test-driven development
- `/refactor` - Code improvements
```

## Command Discovery Patterns

### By Project Type

**Python Projects:**
- Start: `/project:init <name> python`
- Develop: `/tdd`, `/test:run`, `/lint:check`
- Ship: `/git:smartcommit`, `/github:quickpr`

**Node.js Projects:**
- Start: `/project:init <name> node`
- Develop: `/tdd`, `/test:run`, `/lint:check`
- Ship: `/git:smartcommit`, `/github:quickpr`

**Rust Projects:**
- Start: `/project:init <name> rust`
- Develop: `/test:run`, `/lint:check`
- Ship: `/git:smartcommit`, `/github:quickpr`

### By Workflow

**Feature Development:**
1. `/github:process-single-issue <number>`
2. Implement with language agent
3. `/tdd` for test coverage
4. `/refactor` for code quality
5. `/git:smartcommit feat/<name>`
6. `/github:quickpr --issue <number>`

**Bug Fixing:**
1. `/github:process-single-issue <number>`
2. `/test:run` to reproduce
3. Fix with appropriate agent
4. `/test:run` to verify
5. `/git:smartcommit fix/<description>`
6. `/github:quickpr "Fix #<number>"`

**Code Quality:**
1. `/codereview` for analysis
2. `/refactor` for improvements
3. `/lint:check --fix`
4. `/test:run` to verify
5. `/git:smartcommit refactor/<area>`

## Best Practices

### Command Composition
- Chain simple commands for complex workflows
- Use SlashCommand tool in custom commands
- Pass data between commands via arguments

### Agent Integration
- Agents should delegate common tasks to commands
- Keep agent-specific logic in agents
- Use commands for standardized workflows

### Reusability
- Prefer existing commands over reimplementation
- Create new shared commands for repeated patterns
- Make commands language/tool agnostic when possible

## Creating New Commands

### Structure
```markdown
---
allowed-tools: [tools-needed, SlashCommand]
argument-hint: <required> [optional]
description: Brief description
---

# Command implementation
Use SlashCommand for composition
```

### Naming Convention
- Use namespace format: `/category:action`
- Examples: `/git:smartcommit`, `/docs:update`
- Keep names descriptive but concise

### Tool Permissions
- Limit to necessary tools only
- Include SlashCommand for composition
- Use pattern matching for Bash commands

## Command Maintenance

### Testing Commands
1. Test in isolation first
2. Test composition with other commands
3. Verify agent integration
4. Check cross-platform compatibility

### Updating Commands
1. Maintain backward compatibility
2. Document breaking changes
3. Update agent references
4. Test affected workflows

## Future Enhancements

### Planned Commands
- `/debug:analyze` - Universal debugger
- `/perf:profile` - Performance analysis
- `/deploy:k8s` - Kubernetes deployment
- `/monitor:setup` - Observability setup

### Integration Goals
- Automatic command discovery by agents
- Command dependency resolution
- Parallel command execution
- Command result caching

---

*Last updated: Command harmonization implementation*
*Total commands: 30+*
*Agents integrated: 20+*
