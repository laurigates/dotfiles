# Claude Code Skills Refactoring Plan

## Objective

Split large monolithic skills into smaller, focused units for better context efficiency and precision.

## Refactoring Strategy

### Phase 1: Knowledge Graph Skills (426 lines → 3 skills)

#### 1.1 Create: `graphiti-episode-storage`
**Size**: ~150 lines
**Description**: Patterns for storing episodes in Graphiti Memory including agent executions, error resolutions, workflows, and decisions.

**Content**:
- Episode storage patterns (agent execution, error resolution, workflow, decision rationale)
- Episode quality guidelines
- What to store vs. what not to store
- JSON schema examples

**When to Use**:
- After completing agent work
- After resolving errors
- After workflow completion
- After making technical decisions

#### 1.2 Create: `graphiti-memory-retrieval`
**Size**: ~100 lines
**Description**: Techniques for searching and retrieving information from Graphiti Memory.

**Content**:
- Search patterns (facts, nodes, centered search)
- Query construction
- Group ID filtering
- Result interpretation

**When to Use**:
- Before starting similar work
- When encountering errors
- Looking for past patterns
- Finding proven solutions

#### 1.3 Create: `graphiti-learning-workflows`
**Size**: ~150 lines
**Description**: Workflows for learning from historical data and building institutional knowledge.

**Content**:
- Learning from history workflows
- Before/during/after work patterns
- Group ID conventions
- Integration with other skills
- Common pitfalls

**When to Use**:
- Building knowledge over time
- Analyzing trends
- Improving from past work
- Creating audit trails

**Migration**:
- Deprecate `knowledge-graph-patterns`
- Add deprecation notice pointing to new skills
- Update cross-references in other skills

---

### Phase 2: Git Workflow Skills (403 lines → 3 skills)

#### 2.1 Create: `git-commit-workflow`
**Size**: ~180 lines
**Description**: Commit practices including frequency, messages, staging, and history management.

**Content**:
- Commit frequency best practices
- Commit message formats (conventional commits)
- Explicit staging patterns
- Interactive staging
- Amending commits
- Stashing changes

**When to Use**:
- Making commits
- Writing commit messages
- Managing work in progress

#### 2.2 Create: `git-security-checks`
**Size**: ~120 lines
**Description**: Security validation and pre-commit checks for safe commits.

**Content**:
- Secret scanning with detect-secrets
- Pre-commit hook execution
- Security checklist
- Language-specific linting
- Validation workflow sequence

**When to Use**:
- Before every commit
- During security audits
- Setting up new projects

#### 2.3 Create: `git-branch-pr-workflow`
**Size**: ~100 lines
**Description**: Branch management, PR creation, and collaboration workflows.

**Content**:
- Branch naming conventions
- Starting new work workflow
- PR preparation
- Branch management
- Conflict resolution
- Recovery patterns

**When to Use**:
- Creating feature branches
- Preparing pull requests
- Managing branches
- Resolving conflicts

**Migration**:
- Deprecate `git-workflow`
- Split content by workflow stage
- Update CLAUDE.md references

---

### Phase 3: Agent Coordination Skills (402 lines → 2 skills)

#### 3.1 Create: `agent-file-coordination`
**Size**: ~250 lines
**Description**: File-based context sharing and coordination structures for multi-agent workflows.

**Content**:
- Directory organization (~/.claude/tasks, docs, status)
- File purposes and formats
- current-workflow.md structure
- agent-queue.md format
- inter-agent-context.json schema
- agent-output.md template
- progress reporting format
- Human inspection commands

**When to Use**:
- Setting up multi-agent workflows
- Reading/writing agent context
- Monitoring agent progress
- Debugging agent coordination

#### 3.2 Create: `agent-coordination-patterns`
**Size**: ~150 lines
**Description**: Coordination patterns for sequential, parallel, and iterative agent workflows.

**Content**:
- Sequential coordination pattern
- Parallel coordination pattern
- Iterative coordination pattern
- Integration protocol (3 phases)
- Best practices
- Common pitfalls
- Examples

**When to Use**:
- Designing multi-agent workflows
- Coordinating agent handoffs
- Planning agent dependencies
- Integrating agent outputs

**Migration**:
- Deprecate `agent-context-management`
- Keep file structures in file-coordination
- Keep patterns in coordination-patterns

---

### Phase 4: GitHub Actions Security Skills (393 lines → 2 skills)

#### 4.1 Create: `github-actions-authentication`
**Size**: ~200 lines
**Description**: Authentication strategies for GitHub Actions including OIDC, tokens, and cloud provider integration.

**Content**:
- OIDC authentication patterns
- Token management (GITHUB_TOKEN, PAT, App)
- AWS authentication (OIDC, Bedrock)
- Google Cloud authentication (Vertex AI)
- Anthropic API integration
- Permission scoping

**When to Use**:
- Setting up GitHub Actions authentication
- Integrating with cloud providers
- Configuring Claude Code in CI/CD
- Managing secrets and tokens

#### 4.2 Create: `github-actions-secrets`
**Size**: ~190 lines
**Description**: Secrets management, environment variables, and security best practices for GitHub Actions.

**Content**:
- Secrets storage (repository, environment, organization)
- Environment variable patterns
- Security best practices
- Secret rotation
- Least privilege principles
- Audit and compliance

**When to Use**:
- Managing GitHub Actions secrets
- Securing CI/CD pipelines
- Implementing secret rotation
- Auditing secret usage

**Migration**:
- Deprecate `github-actions-auth-security`
- Split by authentication vs. secrets management

---

### Phase 5: Code Search Skills (352 lines → 2 skills)

#### 5.1 Create: `rg-search-basics`
**Size**: ~180 lines
**Description**: Essential ripgrep patterns for common code search tasks.

**Content**:
- Basic search patterns
- File type filtering
- Glob patterns
- Case sensitivity
- Context lines (-A, -B, -C)
- Common use cases
- Quick reference

**When to Use**:
- Basic code searches
- Finding function definitions
- Searching specific file types
- Common search scenarios

#### 5.2 Create: `rg-advanced-search`
**Size**: ~170 lines
**Description**: Advanced ripgrep techniques including regex, multiline, and performance optimization.

**Content**:
- Complex regex patterns
- Multiline matching
- Lookahead/lookbehind
- Performance optimization
- Inverse matching
- Replace patterns
- Integration with other tools

**When to Use**:
- Complex search patterns
- Multiline code blocks
- Performance-critical searches
- Advanced filtering

**Migration**:
- Deprecate `rg-code-search`
- Split by complexity level

---

## Implementation Plan

### Step 1: Create New Skill Directories
```bash
# Phase 1: Knowledge Graph
mkdir -p .claude/skills/graphiti-episode-storage
mkdir -p .claude/skills/graphiti-memory-retrieval
mkdir -p .claude/skills/graphiti-learning-workflows

# Phase 2: Git Workflow
mkdir -p .claude/skills/git-commit-workflow
mkdir -p .claude/skills/git-security-checks
mkdir -p .claude/skills/git-branch-pr-workflow

# Phase 3: Agent Coordination
mkdir -p .claude/skills/agent-file-coordination
mkdir -p .claude/skills/agent-coordination-patterns

# Phase 4: GitHub Actions
mkdir -p .claude/skills/github-actions-authentication
mkdir -p .claude/skills/github-actions-secrets

# Phase 5: Code Search
mkdir -p .claude/skills/rg-search-basics
mkdir -p .claude/skills/rg-advanced-search
```

### Step 2: Extract and Refactor Content
For each new skill:
1. Copy relevant sections from source skill
2. Remove duplication
3. Add focused "When to Use" section
4. Update cross-references
5. Create SKILL.md with proper frontmatter

### Step 3: Add Deprecation Notices
Update deprecated skills:
```markdown
---
name: Old Skill Name
deprecated: true
replacement: ["new-skill-1", "new-skill-2", "new-skill-3"]
---

# [DEPRECATED] Old Skill Name

**This skill has been split into smaller, focused skills:**
- `new-skill-1` - Description
- `new-skill-2` - Description
- `new-skill-3` - Description

Please use the new skills for better context efficiency.
```

### Step 4: Update Cross-References
Files to update:
- `CLAUDE.md` - Update skill list and descriptions
- Other skills that reference deprecated skills
- Related slash commands

### Step 5: Testing
- Load skills and verify descriptions appear correctly
- Test skill activation with relevant prompts
- Verify cross-references work
- Check token usage improvements

### Step 6: Cleanup (After 1 week validation)
- Delete deprecated skill directories
- Update marketplace references if applicable

---

## Success Metrics

**Context Efficiency**:
- ✅ Individual skill loads < 200 lines
- ✅ More precise skill activation
- ✅ Reduced token usage per skill load

**Maintainability**:
- ✅ Single responsibility per skill
- ✅ Clear skill boundaries
- ✅ Easy to update individual skills

**Discoverability**:
- ✅ Descriptive skill names
- ✅ Focused "When to Use" sections
- ✅ Clear relationship between related skills

---

## Rollout Schedule

### Week 1: Phase 1 (Knowledge Graph)
- Create 3 new skills
- Deprecate knowledge-graph-patterns
- Test and validate

### Week 2: Phase 2 (Git Workflow)
- Create 3 new skills
- Deprecate git-workflow
- Update CLAUDE.md references

### Week 3: Phase 3 (Agent Coordination)
- Create 2 new skills
- Deprecate agent-context-management
- Test multi-agent workflows

### Week 4: Phase 4-5 (GitHub Actions & Search)
- Create 4 new skills
- Deprecate source skills
- Final validation

### Week 5: Cleanup
- Remove deprecated skills
- Update all documentation
- Publish changes

---

## Risk Mitigation

**Backward Compatibility**:
- Keep deprecated skills for 1 week with notices
- Gradual rollout allows testing
- Easy rollback if issues found

**Cross-Reference Integrity**:
- Document all skill relationships
- Update all references before deprecation
- Test related workflows

**User Impact**:
- Transparent deprecation notices
- Clear migration paths
- Improved experience after migration

---

## Notes

- Smaller skills = better context efficiency
- Focused skills = more precise activation
- Single responsibility = easier maintenance
- Clear naming = better discoverability
