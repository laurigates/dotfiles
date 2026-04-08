# ADR-0005: Namespace-Based Command Organization

## Status

Accepted

## Date

2024-12 (retroactively documented 2025-12)

## Context

The dotfiles repository contains **76 slash commands** - markdown files that expand into prompts when invoked with the `/` prefix. As the command collection grew, several problems emerged:

### The Flat Namespace Problem

Initially, all commands lived in a flat directory:

```
.claude/commands/
├── commit.md
├── review.md
├── test.md
├── deploy.md
├── lint.md
├── fix-pr.md
├── new-project.md
├── ...
└── (76 files)
```

**Problems:**

1. **Name collisions** - Multiple domains want "test", "review", "deploy"
2. **Discoverability** - Users can't find commands they don't know exist
3. **Cognitive load** - 76 flat commands overwhelm mental models
4. **Ambiguous scope** - `review.md` could be code review, PR review, or doc review

### Command Growth Trajectory

| Milestone | Commands | Organization |
|-----------|----------|--------------|
| Initial | ~10 | Flat directory |
| 6 months | ~30 | Flat, naming conflicts |
| 12 months | ~50 | Informal prefixes (git-*, test-*) |
| Current | 76+ | Namespace directories |

### User Discovery Challenge

Users invoke commands by memory or tab completion. Without organization:
- Can't remember exact command names
- Tab completion shows 76 options
- No logical grouping aids recall
- Related commands not co-located

### Comparison: Skills vs Commands

| Aspect | Skills | Commands |
|--------|--------|----------|
| Invocation | Automatic (Claude decides) | Explicit (user types `/`) |
| Discovery | Via description matching | Via `/` prefix + completion |
| Organization | Flat (100+ skills) | Namespaced (14 categories) |
| Naming | Must be globally unique | Scoped to namespace |

Skills work flat because Claude handles discovery. Commands need namespaces because humans handle discovery.

## Decision

**Organize commands into namespace directories** with colon-separated invocation syntax.

### Namespace Structure

```
.claude/commands/
├── blueprint-*.md           # Root-level: Blueprint methodology
├── project-*.md             # Root-level: Project operations
├── code/                    # Code quality and review
│   ├── antipatterns.md      # /code:antipatterns
│   ├── review.md            # /code:review
│   └── refactor.md          # /code:refactor
├── configure/               # Infrastructure standards
│   ├── all.md               # /configure:all
│   ├── linting.md           # /configure:linting
│   └── ...                  # 20+ configuration commands
├── deploy/                  # Deployment operations
├── deps/                    # Dependency management
├── docs/                    # Documentation generation
├── git/                     # Git and GitHub operations
├── lint/                    # Linting and quality checks
├── meta/                    # Claude Code introspection
├── project/                 # Project setup/maintenance
├── sync/                    # Synchronization tasks
├── test/                    # Testing infrastructure
├── tools/                   # Tool initialization
└── workflow/                # Development workflows
```

### Invocation Syntax

```bash
# Namespaced command
/namespace:command

# Root-level command (backward compatibility)
/command

# With parameters
/namespace:command arg1 --flag arg2
```

### 14 Namespaces Defined

| Namespace | Purpose | Example Commands |
|-----------|---------|------------------|
| `code` | Code quality, review | `antipatterns`, `review`, `refactor` |
| `configure` | Infrastructure standards | `all`, `linting`, `tests`, `mcp` |
| `deploy` | Deployment operations | `release`, `handoff` |
| `deps` | Dependency management | `install` |
| `docs` | Documentation | `generate`, `sync`, `decommission` |
| `git` | Git/GitHub operations | `commit`, `maintain`, `issues`, `fix-pr` |
| `lint` | Linting checks | `check` |
| `meta` | Claude introspection | `assimilate`, `audit` |
| `project` | Project setup | `new`, `init`, `modernize` |
| `sync` | Synchronization | `github-podio`, `daily` |
| `test` | Testing infrastructure | `quick`, `full`, `consult`, `setup` |
| `tools` | Tool initialization | `vectorcode` |
| `workflow` | Development automation | `dev`, `dev-zen` |
| (root) | Cross-cutting concerns | `delegate`, `blueprint-*`, `project-*` |

### Naming Conventions

1. **Use kebab-case**: `fix-pr.md` not `FixPR.md`
2. **Be descriptive**: `fix-pr.md` better than `fix.md`
3. **Avoid redundant namespace**: `git/commit.md` not `git/git-commit.md`
4. **Use verbs**: `review.md`, `deploy.md`, `generate.md`

### Migration Path

Legacy commands remain at root level for backward compatibility:
- `/blueprint-*` - Blueprint Development methodology
- `/project-continue` - Project state analysis
- `/project-test-loop` - TDD loop
- `/refactor` - Legacy (prefer `/code:refactor`)

## Consequences

### Positive

1. **Scoped naming** - `test/run.md` and `lint/check.md` don't conflict
2. **Logical grouping** - Related commands co-located
3. **Improved discovery** - Tab complete within namespace
4. **Scalable** - Can grow to 200+ commands without chaos
5. **Self-documenting** - Namespace reveals command purpose
6. **Reduced cognitive load** - 14 namespaces vs 76 flat commands

### Negative

1. **Longer invocation** - `/git:commit` vs `/commit`
2. **Learning curve** - Users must learn namespace structure
3. **Migration overhead** - Existing references need updating
4. **Potential namespace sprawl** - Could create too many namespaces

### Tab Completion Improvement

**Before (flat):**
```
/c<tab>
→ commit, code-review, configure-all, configure-linting, ...
```

**After (namespaced):**
```
/c<tab>
→ code:, configure:

/configure:<tab>
→ all, linting, tests, mcp, ...
```

### Command Counts by Namespace

| Namespace | Commands | Notes |
|-----------|----------|-------|
| `configure` | 22 | Infrastructure standards |
| `test` | 6 | Testing workflows |
| `git` | 5 | Git operations |
| `docs` | 4 | Documentation |
| `project` | 4 | Project setup |
| `code` | 3 | Code quality |
| `deploy` | 2 | Deployment |
| `sync` | 2 | Synchronization |
| `workflow` | 2 | Automation |
| `meta` | 2 | Introspection |
| Others | 1 each | Specialized |
| (root) | ~10 | Legacy/cross-cutting |

## Alternatives Considered

### Flat with Prefixes
Keep flat directory but use filename prefixes: `git-commit.md`, `test-run.md`.

**Rejected because**: Still clutters tab completion; doesn't provide directory grouping.

### Deep Nesting
Allow nested namespaces: `/configure:tests:coverage`.

**Rejected because**: Over-complicates invocation; two levels sufficient for 76 commands.

### Tag-Based Organization
Flat directory with YAML tags for categorization.

**Rejected because**: Doesn't improve tab completion; tags require tooling support.

### Automatic Namespace Inference
Infer namespace from command content.

**Rejected because**: Explicit directories are clearer; no magic behavior.

## Related Decisions

- ADR-0003: Skill Activation via Trigger Keywords (commands invoke skills)
- ADR-0004: Subagent-First Delegation Strategy (commands delegate to agents)
- ADR-0001: Chezmoi exact_ Directory Strategy (commands managed atomically)

## References

- Commands directory: `exact_dot_claude/commands/`
- Commands documentation: `exact_dot_claude/commands/CLAUDE.md`
- Migration script: `scripts/migrate-command-namespaces.sh`
