# Blueprint Development

**Blueprint Development** is a PRP-driven methodology for AI-native projects that generates project-specific skills and commands, automates work-order creation, and enforces Test-Driven Development (TDD) throughout the development lifecycle.

> **What's a PRP?** A PRP (Product Requirement Prompt) is PRD + Curated Codebase Intelligence + Implementation Blueprint + Validation Gates - the minimum viable packet an AI agent needs to deliver production code successfully on first attempt.

## Philosophy

Traditional development requires developers to maintain mental models of:
- Project architecture and patterns
- Testing strategies and conventions
- Implementation approaches
- Quality standards and review criteria

Blueprint Development **codifies these mental models** as machine-readable artifacts:
- **Skills** define autonomous capabilities Claude discovers based on context
- **Commands** provide explicit workflow control points
- **PRPs** specify what to build AND how to build it with curated context
- **ai_docs** provide curated library documentation optimized for AI
- **Work-orders** package isolated tasks with minimal context for subagent execution

> **Core Principle:** "Context is non-negotiable. LLM outputs are bounded by their context window; irrelevant or missing context literally squeezes out useful tokens."

The result is a **self-documenting development environment** where process, standards, and context are first-class citizens.

## Core Concepts

### PRP-First
Every project starts with Product Requirement Prompts that specify:
- **What** to build and **why** (from traditional PRDs)
- **How** to build it with curated context (AI-native addition)
- Success criteria and constraints
- Technical decisions and trade-offs
- TDD requirements
- **Validation gates** with executable commands
- **Known gotchas** with mitigations

### ai_docs - Curated Documentation
Curated library and project documentation optimized for AI agents:
- **< 200 lines** per entry (token-efficient)
- **Actionable** code snippets that can be directly used
- **Gotcha-aware** with documented pitfalls and solutions
- **Version-specific** tied to project dependencies

Located in `.claude/blueprints/ai_docs/`:
```
ai_docs/
├── libraries/          # Third-party library patterns
│   ├── redis-py.md
│   └── pydantic-v2.md
└── project/            # Project-specific patterns
    ├── patterns.md
    └── conventions.md
```

### Confidence Scoring
Every PRP and work-order includes a confidence score (1-10) assessing:
- **Context Completeness**: Are file paths, code snippets, versions explicit?
- **Implementation Clarity**: Is pseudocode clear, edge cases covered?
- **Gotchas Documented**: Are known pitfalls documented with mitigations?
- **Validation Coverage**: Are executable commands provided for all gates?

**Scoring Guide:**
- **9+**: Ready for isolated subagent execution
- **7-8**: Ready for execution with some discovery
- **< 7**: Needs more research/refinement

### Generated Skills
From PRPs, generate project-specific skills in four domains:

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

### 1. Write PRPs
Create PRPs (Product Requirement Prompts) with curated context:
```bash
/prp:create [feature-name]
```

This guides you through:
1. Researching the codebase for patterns
2. Curating library documentation to ai_docs
3. Documenting known gotchas
4. Creating validation gates with executable commands
5. Assessing confidence score

See [prp-template.md](prp-template.md) for structure.

### 2. Curate ai_docs (Optional)
```bash
/prp:curate-docs [library-name]
```

Creates curated documentation entries for frequently-used libraries.

### 3. Generate Skills & Commands
```bash
# In your project directory
/blueprint:generate-skills
/blueprint:generate-commands
```

This analyzes PRPs and creates project-specific skills and commands in `.claude/`.

### 4. Start Development
```bash
/project:continue
```

Claude analyzes project state (git status, PRPs, work-orders) and continues where you left off.

Or execute a specific PRP:
```bash
/prp:execute [feature-name]
```

### 5. Test-Driven Development
All generated skills enforce TDD:
1. **RED** - Write failing test
2. **GREEN** - Minimal implementation to pass
3. **REFACTOR** - Improve while keeping tests green

Use `/project:test-loop` to start automated test → fix cycles.

### 6. Work-Order Generation
```bash
/blueprint:work-order
```

Generates isolated task package for subagent execution with minimal context.

## Project Structure

```
project-root/
├── .claude/
│   ├── blueprints/
│   │   ├── prps/                  # Product Requirement Prompts
│   │   │   ├── feature-1.md
│   │   │   └── feature-2.md
│   │   ├── ai_docs/               # Curated documentation
│   │   │   ├── libraries/         # Third-party library patterns
│   │   │   │   └── redis-py.md
│   │   │   └── project/           # Project-specific patterns
│   │   │       └── patterns.md
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
1. Create PRPs with `/prp:create` - includes research and context curation
2. Curate ai_docs for key libraries with `/prp:curate-docs`
3. Run `/blueprint:generate-skills` to create project-specific skills
4. Run `/blueprint:generate-commands` to create workflow commands
5. Review confidence scores and refine if < 7

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

- [PRP Template](prp-template.md) - Structure for Product Requirement Prompts (recommended)
- [PRD Template](prd-template.md) - Structure for Product Requirements Documents (legacy)
- [Work-Order Template](work-order-template.md) - Structure for isolated task packages
- [ai_docs Template](ai_docs-template/README.md) - Structure for curated documentation

## Commands

See `.claude/commands/` for available commands:

**PRP Commands:**
- `/prp:create` - Create a PRP with systematic research and context curation
- `/prp:execute` - Execute a PRP with validation loop
- `/prp:curate-docs` - Curate library/project documentation for ai_docs

**Blueprint Commands:**
- `/blueprint:init` - Initialize Blueprint Development in a project
- `/blueprint:generate-skills` - Generate skills from PRPs
- `/blueprint:generate-commands` - Generate commands from PRPs
- `/blueprint:work-order` - Create isolated work-order

**Project Commands:**
- `/project:continue` - Analyze state and continue work
- `/project:test-loop` - Start TDD test → fix cycle

## Skills

**Core Skills:**
- `blueprint-development` - Generate project-specific skills from PRPs
- `confidence-scoring` - Assess PRP/work-order quality for execution readiness

See `.claude/skills/` for details.

## Further Reading

- [Complete Workflow Guide](workflow.md)
- [Claude Code Skills Documentation](https://docs.claude.com/en/docs/claude-code/customization/skills)
- [Claude Code Commands Documentation](https://docs.claude.com/en/docs/claude-code/customization/commands)
