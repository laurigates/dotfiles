# Blueprint Development

**Blueprint Development** is a PRD-driven methodology for AI-native projects that generates project-specific skills and commands, automates work-order creation, and enforces Test-Driven Development (TDD) throughout the development lifecycle.

## Philosophy

Traditional development requires developers to maintain mental models of:
- Project architecture and patterns
- Testing strategies and conventions
- Implementation approaches
- Quality standards and review criteria

Blueprint Development **codifies these mental models** as machine-readable artifacts:
- **Skills** define autonomous capabilities Claude discovers based on context
- **Commands** provide explicit workflow control points
- **PRDs** specify what to build
- **Work-orders** package isolated tasks with minimal context for subagent execution

The result is a **self-documenting development environment** where process, standards, and context are first-class citizens.

## Core Concepts

### PRD-First
Every project starts with Product Requirements Documents that specify:
- What to build and why
- Success criteria and constraints
- Technical decisions and trade-offs
- TDD requirements

### Generated Skills
From PRDs, generate project-specific skills in four domains:

1. **Architecture Patterns** - How code is structured, organized, and modularized
2. **Testing Strategies** - TDD workflows, mocking patterns, coverage requirements
3. **Implementation Guides** - How to implement specific feature types (APIs, UI, etc.)
4. **Quality Standards** - Code review criteria, performance baselines, security patterns

These skills are **automatically discovered** by Claude when working on relevant tasks.

### Workflow Commands
Generate commands that automate workflow steps:
- Initialize Blueprint Development in a project
- Generate skills and commands from PRDs
- Continue work where you left off
- Create isolated work-orders for subagent tasks
- Run test → fix → refactor loops

### Automated Work-Orders
Work-orders are **automatically generated** task packages with:
- Specific objective
- Minimal required context (only relevant files/info)
- TDD requirements (tests first, then implementation)
- Success criteria

Work-orders enable **isolated subagent execution** - hand a work-order to a subagent with exactly the context it needs, no more, no less.

## Quick Start

### 1. Write PRDs
Create `.claude/blueprints/prds/` in your project and write requirement documents.

See [prd-template.md](prd-template.md) for structure.

### 2. Generate Skills & Commands
```bash
# In your project directory
/blueprint:generate-skills
/blueprint:generate-commands
```

This analyzes PRDs and creates project-specific skills and commands in `.claude/`.

### 3. Start Development
```bash
/project:continue
```

Claude analyzes project state (git status, PRDs, work-orders) and continues where you left off.

### 4. Test-Driven Development
All generated skills enforce TDD:
1. **RED** - Write failing test
2. **GREEN** - Minimal implementation to pass
3. **REFACTOR** - Improve while keeping tests green

Use `/project:test-loop` to start automated test → fix cycles.

### 5. Work-Order Generation
```bash
/blueprint:work-order
```

Generates isolated task package for subagent execution with minimal context.

## Project Structure

```
project-root/
├── .claude/
│   ├── blueprints/
│   │   ├── prds/                  # Product Requirements Documents
│   │   │   ├── feature-1.md
│   │   │   └── feature-2.md
│   │   ├── work-overview.md       # Auto-generated project overview
│   │   └── work-orders/           # Auto-generated task packages
│   │       ├── 001-setup-auth.md
│   │       └── 002-implement-api.md
│   ├── skills/                    # Project-specific skills (generated)
│   │   ├── architecture-patterns/
│   │   ├── testing-strategies/
│   │   ├── implementation-guides/
│   │   └── quality-standards/
│   └── commands/                  # Project-specific commands (generated)
│       ├── continue.md
│       └── test-loop.md
```

## Workflow

See [workflow.md](workflow.md) for complete workflow documentation.

### Phase 1: Planning
1. Write PRDs defining features, architecture, and technical decisions
2. Run `/blueprint:generate-skills` to create project-specific skills
3. Run `/blueprint:generate-commands` to create workflow commands
4. Review generated artifacts and refine as needed

### Phase 2: Development
1. Run `/project:continue` to analyze state and resume work
2. Claude automatically discovers and applies project-specific skills
3. Follow TDD workflow (tests first, then implementation)
4. Use `/blueprint:work-order` to create isolated tasks for subagents
5. Commit incrementally with conventional commits

### Phase 3: Iteration
1. Project state tracked in git, PRDs, and work-overview
2. `/project:continue` picks up where you left off
3. Skills evolve as patterns emerge (update skill definitions)
4. Work-orders document completed and pending tasks

## Benefits

### For Solo Developers
- **Context persistence** - Project state and patterns codified, not just in your head
- **Consistent patterns** - Skills enforce standards automatically
- **Rapid context switching** - `/project:continue` quickly resumes any project

### For Teams
- **Onboarding** - New contributors read skills to understand "how we build"
- **Code review** - Quality standards codified in skills, applied automatically
- **Knowledge sharing** - Skills document tribal knowledge explicitly

### For AI-Native Development
- **Autonomous discovery** - Claude finds relevant skills without explicit invocation
- **Isolated execution** - Work-orders enable clean subagent task delegation
- **Self-documentation** - Process and standards are machine-readable

## Advanced Usage

### Evolving Skills
As patterns emerge during development, update skill definitions:
```bash
# Edit skill to refine architectural pattern
vim .claude/skills/architecture-patterns/SKILL.md

# Skills are immediately available (no build/reload needed)
```

### Custom Work-Order Templates
Create custom work-order templates for specific task types:
- API endpoint implementation
- UI component development
- Database migration
- Performance optimization

### Integration with CI/CD
Use Blueprint Development in CI:
- Generate work-orders from failed CI runs
- Use project skills in automated code review
- Enforce TDD in pre-commit hooks

## Templates

- [PRD Template](prd-template.md) - Structure for Product Requirements Documents
- [Work-Order Template](work-order-template.md) - Structure for isolated task packages

## Commands

See `.claude/commands/` for available commands:
- `/blueprint:init` - Initialize Blueprint Development in a project
- `/blueprint:generate-skills` - Generate skills from PRDs
- `/blueprint:generate-commands` - Generate commands from PRDs
- `/blueprint:work-order` - Create isolated work-order
- `/project:continue` - Analyze state and continue work
- `/project:test-loop` - Start TDD test → fix cycle

## Skills

The `blueprint-development` meta-skill teaches Claude how to generate project-specific skills. See `.claude/skills/blueprint-development/` for details.

## Further Reading

- [Complete Workflow Guide](workflow.md)
- [Claude Code Skills Documentation](https://docs.claude.com/en/docs/claude-code/customization/skills)
- [Claude Code Commands Documentation](https://docs.claude.com/en/docs/claude-code/customization/commands)
