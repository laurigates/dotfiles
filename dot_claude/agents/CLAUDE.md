# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **specialized agent definition repository** for Claude Code, containing 24 expert agent configurations that define specialized roles for different development tasks. Each agent is a self-contained expert system with specific tools, capabilities, and workflows designed to handle particular domains of software development.

## Core Architecture

### Agent-Based System Structure
- **Agent Files**: Each `.md` file defines a specialized agent with YAML frontmatter metadata
- **Standardized Format**: All agents follow consistent structure:
  - YAML frontmatter (`name`, `color`, `description`, `tools`)
  - Role definition and core expertise
  - Key capabilities and workflow processes
  - Best practices and priority areas

### Agent Behavioral Principles
- **Single Responsibility**: Each agent has one clearly defined domain of expertise
- **Task Execution Only**: Agents execute their specific task and report results back to main agent
- **No Orchestration**: Agents do NOT manage workflows or coordinate other agents (main agent handles this)
- **No Development Loops**: Agents do NOT initiate their own development cycles or multi-step workflows
- **Clear Boundaries**: Agents stay within their domain and do not overstep into other areas
- **Report and Return**: After task completion, agents report findings/results for main agent decision-making
- **Tool Minimalism**: Agents have access only to tools necessary for their specific domain

### Agent Categories
1. **Development Languages**: `python-developer.md`, `nodejs-developer.md`, `embedded-expert.md`
2. **Infrastructure**: `container-maestro.md`, `k8s-captain.md`, `infra-sculptor.md`, `pipeline-engineer.md`
3. **Code Quality**: `code-analysis-expert.md`, `code-reviewer.md`, `test-architect.md`, `security-auditor.md`
4. **Tools & Environment**: `git-expert.md`, `neovim-expert.md`, `dotfiles-manager.md`, `makefile-expert.md`
5. **Documentation**: `docs-expert.md`, `digital-scribe.md`, `research-assistant.md`
6. **Orchestration**: `devloop-orchestrator.md`, `service-design-expert.md`, `memory-keeper.md`

## Development Workflows

### Core Philosophy
- **Test-Driven Development (TDD)**: RED-GREEN-REFACTOR cycles enforced across all agents
- **Modern Package Management**: Fast, reliable package managers (uv for Python, Bun for JS)
- **Agent Delegation**: All tasks delegated to appropriate specialized agents
- **Quality First**: Comprehensive testing, linting, and security scanning

### Technology Stack Standards
- **Python**: uv (package management), ruff (linting/formatting), pytest, type hints
- **JavaScript/TypeScript**: Bun runtime, Vite build tool, Vue 3, Pinia state management
- **Containers**: Docker, Kubernetes, Skaffold-based workflows
- **CI/CD**: GitHub Actions, automated deployment pipelines
- **Development Environment**: Neovim, Fish shell, chezmoi dotfiles management

## Agent Development Commands

### Creating/Modifying Agents
```bash
# Agent files follow naming pattern: {role}-{specialization}.md
# Each agent must include:
# - YAML frontmatter with name, color, description, tools
# - Clear role definition and expertise areas
# - Specific workflows and best practices
```

### Validation and Testing
```bash
# Validate YAML frontmatter syntax
yamllint *.md

# Check agent definitions for completeness
# Ensure all agents have required frontmatter fields:
# - name, color, description, tools
```

## Integration Points

### MCP (Model Context Protocol)
- **Context7**: Documentation lookup and library resolution
- **Graphiti Memory**: Knowledge persistence and retrieval
- **GitHub API**: Repository operations and workflow management
- **LSP Integration**: Language server protocol for code analysis
- **Playwright**: Browser automation for testing

### Tool Ecosystem
- **Security**: Automated vulnerability scanning, secret management
- **Performance**: Build optimization, caching strategies, parallel execution
- **Cross-Platform**: macOS/Linux compatibility with platform-aware configurations
- **Automation**: CI/CD pipelines, automated testing, deployment orchestration

## Agent Architecture Patterns

### Specialized Domain Expertise
- **Security Auditor**: Vulnerability scanning, dependency audits, compliance validation
- **Container Maestro**: Docker optimization, 12-factor principles, orchestration
- **Code Analysis Expert**: Semantic search, LSP capabilities, deep code understanding
- **Memory Keeper**: Knowledge graph management, institutional knowledge preservation

### Workflow Integration
- **Development Loop**: Code → Test → Review → Deploy cycles
- **Quality Gates**: Automated linting, type checking, security scanning
- **Knowledge Management**: Persistent memory across sessions and projects

## File Structure Conventions

### Agent Definition Format
```yaml
---
name: "Agent Name"
color: "#hexcolor"
description: "Brief agent description"
tools: ["tool1", "tool2", "tool3"]
---

# Agent Role Definition
## Core Expertise
## Key Capabilities
## Workflow Processes
## Best Practices
```

### Agent Size Constraints
- **Maximum 50 lines per agent** (including YAML frontmatter)
- **Clarity over comprehensiveness** - too many rules confuse Claude about priorities
- **Essential guidance only** - avoid bloating context with unnecessary detail
- **Core tools only** - minimize tool access to prevent decision paralysis

### Tool Integration Standards
- Each agent specifies exact tool list in frontmatter
- Tool capabilities align with agent's domain expertise
- Cross-agent tool sharing for collaboration workflows

## Quality Assurance

### Multi-Layer Testing Strategy
- **Unit Testing**: pytest (Python), Vitest (JavaScript), language-specific frameworks
- **Integration Testing**: TestContainers, service mocks, API testing
- **End-to-End Testing**: Playwright, Cypress, browser automation
- **Security Testing**: Automated vulnerability scanning, dependency auditing

### Agent Validation
- YAML frontmatter syntax validation
- Tool capability verification
- Domain expertise coverage analysis
- Workflow process completeness
