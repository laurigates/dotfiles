# CLAUDE.md - Slash Commands

User-defined slash commands that extend Claude Code with custom workflows and automation.

## What are Slash Commands?

Slash commands are markdown files that expand into prompts when invoked with the `/` prefix. They provide:

- **Reusable workflows** - Complex multi-step procedures in a single command
- **Standardized processes** - Consistent approach to common tasks
- **Context-aware automation** - Commands can reference project state and structure
- **Composable operations** - Combine multiple tools and actions

## Directory Structure

Commands are organized by namespace for clarity and discoverability:

```
.claude/commands/
├── blueprint-*.md           # Blueprint Development methodology (root-level)
├── project-*.md             # Project-wide operations (root-level)
├── refactor.md              # Legacy refactor command (root-level)
├── code/                    # Code quality and review
├── meta/                    # Claude Code introspection and meta-config
├── configure/               # FVH infrastructure standards compliance
├── deploy/                  # Deployment operations
├── deps/                    # Dependency management
├── docs/                    # Documentation generation
├── git/                     # Git and GitHub operations
├── lint/                    # Linting and code quality checks
├── project/                 # Project setup and maintenance
├── sync/                    # Synchronization tasks
├── test/                    # Testing infrastructure
├── tools/                   # Tool initialization
└── workflow/                # Development workflows
```

## Namespace Reference

### Root-Level Commands (Uncategorized)

| Command | Purpose | Usage |
|---------|---------|-------|
| `/delegate` | Delegate tasks to specialized agents | Multi-task parallel execution with auto agent matching |
| `/blueprint-init` | Initialize Blueprint Development structure | Setting up new Blueprint project |
| `/blueprint-generate-commands` | Generate commands from PRDs | Creating workflow commands from requirements |
| `/blueprint-generate-skills` | Generate skills from PRDs | Creating project-specific skills |
| `/blueprint-work-order` | Create minimal work-order for subagent | Isolated task execution |
| `/project-continue` | Analyze project state and continue development | Resuming work after interruption |
| `/project-test-loop` | Run test → fix → refactor TDD loop | Test-driven development workflow |
| `/refactor` | Refactor code selection for quality | Legacy refactor command |
| `/handoffs` | List and manage @HANDOFF markers | Inter-agent communication tracking |

### `code:` - Code Quality and Review

| Command | Purpose | Usage |
|---------|---------|-------|
| `/code:antipatterns` | Analyze codebase for anti-patterns | ast-grep analysis, code smells, parallel agents |
| `/code:review` | Comprehensive code review with fixes | Quality analysis, security, performance |
| `/code:refactor` | Refactor following SOLID principles | Improving code quality and design |

### `meta:` - Claude Code Introspection

| Command | Purpose | Usage |
|---------|---------|-------|
| `/meta:assimilate` | Analyze and assimilate project configs | Understanding unfamiliar project setups |
| `/meta:audit` | Audit subagent configurations | Validating completeness and security |

### `configure:` - FVH Infrastructure Standards

| Command | Purpose | Usage |
|---------|---------|-------|
| `/configure:all` | Run all FVH compliance checks | Comprehensive infrastructure validation |
| `/configure:status` | Quick read-only compliance overview | Pre-flight check without modifications |
| `/configure:pre-commit` | Validate pre-commit hooks | Hook versions and configuration |
| `/configure:release-please` | Validate release automation | Workflow and config validation |
| `/configure:dockerfile` | Validate container configuration | Multi-stage builds, healthchecks |
| `/configure:skaffold` | Validate K8s development setup | Port forwarding, profiles |
| `/configure:workflows` | Validate GitHub Actions workflows | Action versions, permissions |
| `/configure:sentry` | Validate Sentry error tracking | SDK installation, configuration |

### `deploy:` - Deployment Operations

| Command | Purpose | Usage |
|---------|---------|-------|
| `/deploy:release` | Create and publish a release | Semantic versioning, changelog, tagging |
| `/deploy:handoff` | Generate deployment handoff docs | Production deployment documentation |

### `deps:` - Dependency Management

| Command | Purpose | Usage |
|---------|---------|-------|
| `/deps:install` | Universal dependency installer | Auto-detects package manager (npm, pip, cargo, etc.) |

### `docs:` - Documentation Generation

| Command | Purpose | Usage |
|---------|---------|-------|
| `/docs:generate` | Update docs from code annotations | API references, README, changelog |
| `/docs:build` | Set up documentation build system | Sphinx, MkDocs, Docusaurus, GitHub Pages |
| `/docs:sync` | Sync documentation with codebase | Update counts, lists, cross-references |
| `/docs:decommission` | Generate service decommission docs | Service shutdown documentation |
| `/docs:knowledge-graph` | Build knowledge graph from Obsidian vault | Comprehensive documentation analysis |

### `git:` - Git and GitHub Operations

| Command | Purpose | Usage |
|---------|---------|-------|
| `/git:commit` | Complete workflow from changes to PR | Analyze, commit, push, create PR |
| `/git:maintain` | Repository maintenance and cleanup | Prune, GC, verify, branch cleanup |
| `/git:issues` | Process multiple GitHub issues | Bulk issue processing |
| `/git:issue` | Process single GitHub issue with TDD | Fix issue with test-driven workflow |
| `/git:fix-pr` | Analyze and fix failing PR checks | CI/CD failure resolution |

### `lint:` - Linting and Code Quality

| Command | Purpose | Usage |
|---------|---------|-------|
| `/lint:check` | Universal linter auto-detection | Run appropriate linting tools |

### `project:` - Project Setup and Maintenance

| Command | Purpose | Usage |
|---------|---------|-------|
| `/project:new` | Initialize new project with dev environment | Python, Node, Go, generic setup |
| `/project:init` | Base project initialization | Foundation for language-specific setup |
| `/project:modernize` | Modernize to current standards | Security, 12-factor, best practices |
| `/project:modernize-exp` | Experimental modernization | Latest tooling (Python, Node) |

### `sync:` - Synchronization Tasks

| Command | Purpose | Usage |
|---------|---------|-------|
| `/sync:github-podio` | Bidirectional GitHub-Podio sync | Project management integration |
| `/sync:daily` | Daily catch-up aggregation | ADHD-friendly Obsidian summary |

### `test:` - Testing Infrastructure

| Command | Purpose | Usage |
|---------|---------|-------|
| `/test:quick` | Fast unit tests only | Rapid feedback (< 30s) |
| `/test:full` | Complete test suite | All tiers before commit/PR |
| `/test:consult` | Consult test-architecture agent | Strategy, coverage, frameworks |
| `/test:report` | Show test status from last run | Quick status without re-running |
| `/test:run` | Universal test runner auto-detection | Run appropriate testing framework |
| `/test:setup` | Configure comprehensive testing infrastructure | Coverage, CI/CD integration |

### `tools:` - Tool Initialization

| Command | Purpose | Usage |
|---------|---------|-------|
| `/tools:vectorcode` | Initialize VectorCode with auto-config | Semantic code search setup |

### `workflow:` - Development Workflows

| Command | Purpose | Usage |
|---------|---------|-------|
| `/workflow:dev` | Automated development loop with TDD | Issue creation, test-driven development |
| `/workflow:dev-zen` | AI-powered development with Zen MCP | Enhanced development loop |

## Command Anatomy

### Basic Structure

```markdown
---
description: Brief description shown in command list
---

# Command Title

Detailed instructions for Claude Code to follow when executing this command.

## Context

Describe when and why to use this command.

## Steps

1. First action to take
2. Second action to take
3. ...

## Expected Outcome

What should result from running this command.
```

### Frontmatter

Commands support YAML frontmatter for metadata:

```yaml
---
description: Short description (required)
tags: [optional, categorization, tags]
requires: [tools, dependencies, prerequisites]
---
```

### Parameter Placeholders

Commands can accept parameters:

```markdown
# /code:review [PATH]

Review code at the specified PATH.
If PATH is omitted, review current directory.
```

Parameters are referenced with:
- `[PARAM]` - Optional parameter
- `<PARAM>` - Required parameter
- `[--flag]` - Optional flag

### Command Composition

Commands can invoke other commands or tools:

```markdown
## Steps

1. Run `/git:commit --no-push` to commit changes
2. Use the `code-review` agent to analyze changes
3. Run `/test:run --coverage` to verify tests pass
4. Create PR with `/git:commit --pr`
```

## Creating New Commands

### Step 1: Choose Namespace

Determine the appropriate namespace:
- **code** - Code quality, review, refactoring
- **config** - Configuration management, settings
- **deploy** - Deployment, releases, handoff
- **docs** - Documentation generation
- **git** - Git operations, GitHub integration
- **project** - Project setup, maintenance
- **test** - Testing infrastructure
- **workflow** - Development automation

If no namespace fits, create as root-level command.

### Step 2: Create Command File

```bash
# For namespaced command
cd ~/.local/share/chezmoi/.claude/commands/namespace
vim new-command.md

# For root-level command
cd ~/.local/share/chezmoi/.claude/commands
vim new-command.md
```

### Step 3: Write Command Content

Use this template:

```markdown
---
description: Clear, concise description (50 chars max)
---

# /namespace:new-command [ARGS]

Detailed explanation of what this command does and when to use it.

## Usage

\`\`\`bash
/namespace:new-command [optional-arg] <required-arg>
\`\`\`

## Parameters

- `[optional-arg]` - Description of optional parameter
- `<required-arg>` - Description of required parameter

## Context

When should Claude use this command? What problem does it solve?

## Prerequisites

- Required tools or dependencies
- Expected project state
- Necessary permissions

## Steps

1. **Step 1** - First action to take
   - Sub-action detail
   - Expected outcome

2. **Step 2** - Second action to take
   - Sub-action detail
   - Expected outcome

3. **Step 3** - Final action
   - Verification steps
   - Success criteria

## Output

Describe what Claude should produce or report back to the user.

## Example

\`\`\`bash
# Example invocation
/namespace:new-command example-arg

# Expected output or behavior
...
\`\`\`

## Error Handling

- **Error condition 1** - How to handle or recover
- **Error condition 2** - Alternative approach

## See Also

- Related commands: `/related:command1`, `/related:command2`
- Relevant skills: `skill-name`
- Documentation: `docs/reference.md`
```

### Step 4: Test Command

Apply changes and test:

```bash
# Apply changes to ~/.claude
chezmoi apply -v ~/.claude  # Or use alias: ca-claude

# In Claude Code session
/namespace:new-command test-arg
```

### Step 5: Document and Commit

Update this CLAUDE.md with the new command, then commit:

```bash
git add .claude/commands/namespace/new-command.md
git add .claude/commands/CLAUDE.md
git commit -m "feat(commands): add /namespace:new-command"
```

## Modifying Existing Commands

### Edit in Source

```bash
cd ~/.local/share/chezmoi/.claude/commands
vim namespace/command.md
```

### Test Changes

Apply changes and test in Claude Code:

```bash
chezmoi apply -v ~/.claude  # Or use alias: ca-claude
```

### Commit Changes

```bash
git add .claude/commands/namespace/command.md
git commit -m "fix(commands): improve /namespace:command error handling"
```

## Command Naming Conventions

### Naming Rules

1. **Use kebab-case:** `multi-word-command.md` (not `MultiWordCommand.md`)
2. **Be descriptive:** `fix-pr.md` better than `fix.md`
3. **Avoid redundant namespace:** `git/commit.md` not `git/git-commit.md`
4. **Use verbs:** `review.md`, `deploy.md`, `generate.md`

### Invocation Format

Commands are invoked with namespace prefix:

```bash
# Namespaced command
/namespace:command

# Root-level command
/command

# With parameters
/namespace:command arg1 --flag arg2
```

### Legacy Commands

Some commands remain at root level for backward compatibility:
- `/blueprint-*` - Blueprint Development methodology
- `/project-continue` - Project state analysis
- `/project-test-loop` - TDD loop
- `/refactor` - Legacy refactor (prefer `/code:refactor`)

## Best Practices

### Command Design

1. **Single Responsibility** - Each command does one thing well
2. **Composable** - Commands can invoke other commands
3. **Idempotent** - Safe to run multiple times
4. **Fail Fast** - Validate prerequisites early
5. **Clear Output** - Describe what was done and next steps

### Documentation

1. **Clear description** - User sees this in command list
2. **Usage examples** - Show common invocations
3. **Prerequisites** - State dependencies upfront
4. **Error handling** - Guide recovery from failures
5. **Cross-references** - Link to related commands/skills

### Testing

1. **Test in isolation** - Run command standalone
2. **Test with parameters** - Verify argument handling
3. **Test error cases** - Ensure graceful failure
4. **Test composition** - Verify command chaining works

## Maintenance Scripts

Located in `scripts/`:

- **`migrate-command-namespaces.sh`** - Reorganize commands into namespaces
- **`update-command-references.sh`** - Update documentation references after migration

See `scripts/CLAUDE.md` for detailed usage.

## Integration with Skills

Commands often work with skills:

| Command | Invokes Skill | Purpose |
|---------|---------------|---------|
| `/git:commit` | `git-commit-workflow` | Conventional commits, staging |
| `/git:fix-pr` | `github-actions-inspection` | Analyze workflow failures |
| `/code:review` | `code-review` | Quality analysis |
| `/code:refactor` | `code-refactoring` | SOLID principles |
| `/test:run` | Language-specific testing skills | Framework detection |

Skills are auto-discovered and invoked based on context. Commands explicitly request skill usage.

## Troubleshooting

### Command Not Found

**Symptom:** `/namespace:command` shows "command not found"

**Solutions:**
1. Verify file exists in source: `ls ~/.local/share/chezmoi/exact_dot_claude/commands/namespace/command.md`
2. Apply changes: `chezmoi apply -v ~/.claude`
3. Verify target file: `ls ~/.claude/commands/namespace/command.md`
4. Restart Claude Code session

### Command Not Executing Correctly

**Symptom:** Command runs but doesn't follow instructions

**Solutions:**
1. Review command markdown for clarity
2. Ensure steps are unambiguous and actionable
3. Add more context or prerequisites
4. Test with simpler example first

### Parameters Not Recognized

**Symptom:** Command ignores provided arguments

**Solutions:**
1. Check parameter syntax in command markdown
2. Verify placeholder format: `[optional]` or `<required>`
3. Document parameter usage in command description

### Namespace Migration Issues

**Symptom:** Old command references still work but new namespace doesn't

**Solutions:**
1. Run `/scripts/update-command-references.sh` to update docs
2. Check for duplicate command files at old and new locations
3. Remove old command files after migration

## See Also

- **Root CLAUDE.md** - Overall repository guidance
- **`.claude/CLAUDE.md`** - High-level design and delegation strategy
- **`.claude/skills/CLAUDE.md`** - Skills system documentation
- **`scripts/CLAUDE.md`** - Maintenance scripts for command management
