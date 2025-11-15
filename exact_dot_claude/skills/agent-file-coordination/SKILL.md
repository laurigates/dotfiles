# Agent File Coordination

## Description

File-based context sharing and coordination structures for multi-agent workflows. Provides standardized directory organization, file formats, and templates for transparent agent coordination and human inspection.

## When to Use

Automatically apply this skill when:
- Setting up multi-agent workflows
- Reading/writing agent context files
- Monitoring agent progress
- Debugging agent coordination
- Sharing data between agents
- Maintaining workflow transparency

## Directory Organization

### Standard Structure
```
~/.claude/
├── tasks/              # Workflow coordination
│   ├── current-workflow.md      # Active workflow status
│   ├── agent-queue.md           # Agent scheduling & dependencies
│   └── inter-agent-context.json # Structured cross-agent data
│
├── docs/               # Agent outputs & results
│   ├── {agent}-output.md        # Standardized agent results
│   └── agent-output-template.md # Template for consistency
│
└── status/             # Real-time progress
    └── {agent}-progress.md      # Live status updates
```

## File Formats and Purposes

### current-workflow.md

**Purpose**: Workflow overview and status tracking

**Format**:
```markdown
# Current Workflow: {Workflow Name}

**Workflow ID**: {unique-id}
**Started**: {timestamp}
**Type**: api_development|fullstack|infrastructure|quality_review
**Status**: IN_PROGRESS|COMPLETED|BLOCKED

## Objective
{Clear description of what this workflow aims to achieve}

## Tech Stack
- Language: {Python|JavaScript|Rust|Go}
- Framework: {FastAPI|React|Axum|Gin}
- Database: {PostgreSQL|MongoDB|Redis}

## Progress
- ✅ Research and planning
- ✅ Repository setup
- 🔄 Implementation (60%)
- ⏳ Testing
- ⏳ Documentation

## Success Criteria
- [ ] All endpoints implemented
- [ ] 90% test coverage achieved
- [ ] Documentation complete
- [ ] Security review passed
```

### agent-queue.md

**Purpose**: Agent scheduling and dependency tracking

**Format**:
```markdown
# Agent Queue

**Last Updated**: {timestamp}

## Active Agent
- **Name**: python-developer
- **Started**: {timestamp}
- **Task**: Implementing authentication endpoints

## Completed Agents
1. ✅ research-assistant (30 min) - Requirements gathering
2. ✅ git-expert (10 min) - Repository setup

## Pending Agents
1. ⏳ test-architect - Create test suite
   - **Dependencies**: python-developer
   - **Estimated Duration**: 45 min

2. ⏳ security-auditor - Review implementation
   - **Dependencies**: python-developer, test-architect
   - **Estimated Duration**: 30 min

## Dependencies Graph
```
research-assistant → python-developer → test-architect
                                     ↘
                                       security-auditor
                                     ↗
```
```

### inter-agent-context.json

**Purpose**: Shared structured data for agent coordination

**Schema**:
```json
{
  "workflow_type": "api_development|fullstack|infrastructure|quality_review",

  "project_context": {
    "name": "User Authentication API",
    "type": "REST API",
    "tech_stack": {
      "language": "Python",
      "framework": "FastAPI",
      "database": "PostgreSQL",
      "testing": "pytest"
    },
    "repository": "https://github.com/org/repo"
  },

  "shared_requirements": {
    "authentication": "JWT",
    "api_standards": "RESTful",
    "security_level": "Production",
    "test_coverage": 90,
    "response_time_ms": 200
  },

  "coordination_rules": {
    "code_style": "Black",
    "git_workflow": "Feature branches",
    "documentation": "Inline + README",
    "commit_convention": "conventional"
  },

  "integration_contracts": {
    "api_endpoints": {
      "/auth/login": {"method": "POST", "returns": "JWT token"},
      "/auth/refresh": {"method": "POST", "returns": "JWT token"},
      "/auth/logout": {"method": "POST", "returns": "success"}
    },
    "error_format": {
      "type": "object",
      "properties": {
        "error": "string",
        "message": "string",
        "code": "number"
      }
    }
  },

  "decisions_made": {
    "database": "PostgreSQL chosen for ACID compliance",
    "auth": "JWT over sessions for stateless scaling",
    "testing": "pytest with 90% coverage requirement"
  }
}
```

### {agent}-output.md

**Purpose**: Standardized agent results for downstream consumption

**Template**:
```markdown
# {Agent Name} Output

**Agent**: {agent-name}
**Completed**: {timestamp}
**Duration**: {duration in minutes}
**Status**: SUCCESS|PARTIAL|FAILED

## Objective
{What this agent was asked to accomplish}

## Accomplishments
- {Specific deliverable 1}
- {Specific deliverable 2}
- {Feature implemented}

## Decisions Made
Key technical decisions affecting downstream work:
- **Technology**: {Choice and rationale}
- **Architecture**: {Pattern chosen}
- **Implementation**: {Approach taken}

## Artifacts Created
Files, directories, and resources produced:
- `/src/api/auth.py` - Authentication implementation
- `/tests/test_auth.py` - Test suite
- `/docs/auth.md` - API documentation

## Known Issues
Problems requiring attention:
- **Performance**: {Issue description}
- **Edge Case**: {Unhandled scenario}
- **TODO**: {Incomplete items}

## Metrics
- Lines of code: {count}
- Test coverage: {percentage}
- Files created: {count}
- Files modified: {count}

## Handoff Notes
Critical information for next agent:
- Environment variables required: `JWT_SECRET`, `DATABASE_URL`
- Dependencies installed: `pip install -r requirements.txt`
- Tests status: All passing except {specific test}

## Context for Next Agent
{Specific guidance based on agent type}
Example: "Security auditor: Focus on /src/api/auth.py lines 45-78"
```

### {agent}-progress.md

**Purpose**: Real-time progress updates

**Format**:
```markdown
# {Agent Name} Progress

**Status**: STARTING|IN_PROGRESS|COMPLETED|BLOCKED
**Current Step**: {Current activity}
**Started**: {timestamp}
**Last Updated**: {timestamp}
**Progress**: {percentage}%

## Current Activity
{Detailed description of what's happening now}

## Completed Steps
- ✅ Read workflow context
- ✅ Review previous agent outputs
- ✅ Set up development environment
- ✅ Implement core functionality

## In Progress
- 🔄 Writing unit tests (60%)

## Next Steps
- ⏳ Integration tests
- ⏳ Documentation
- ⏳ Final validation

## Blockers
{Any issues preventing progress}

## Estimated Time Remaining
{X} minutes
```

## Reading Context Protocol

Before starting work, agents MUST read in order:

1. **Workflow Status**
   ```bash
   cat ~/.claude/tasks/current-workflow.md
   ```
   - Understand overall objective
   - See tech stack requirements
   - Review progress

2. **Agent Queue**
   ```bash
   cat ~/.claude/tasks/agent-queue.md
   ```
   - Identify dependencies
   - Know position in workflow
   - Understand what's next

3. **Shared Context**
   ```bash
   cat ~/.claude/tasks/inter-agent-context.json | jq
   ```
   - Get project requirements
   - Review technical standards
   - Understand contracts

4. **Dependency Outputs**
   ```bash
   cat ~/.claude/docs/{dependency-agent}-output.md
   ```
   - Read outputs from prerequisites
   - Understand decisions made
   - Build on previous work

## Writing Output Protocol

### During Execution

Update progress file every 5-10 minutes:
```bash
cat > ~/.claude/status/{agent}-progress.md <<EOF
# {Agent Name} Progress

**Status**: IN_PROGRESS
**Current Step**: Implementing authentication
**Started**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Last Updated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Progress**: 40%

## Current Activity
Writing JWT token generation logic
...
EOF
```

### After Completion

Write comprehensive output:
```bash
cat > ~/.claude/docs/{agent}-output.md <<EOF
# {Agent Name} Output

**Agent**: {agent-name}
**Completed**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Status**: SUCCESS
...
EOF
```

## Human Inspection Commands

Quick monitoring of agent activity:

```bash
# Overall workflow status
cat ~/.claude/tasks/current-workflow.md

# Agent scheduling
cat ~/.claude/tasks/agent-queue.md

# Shared context (formatted)
cat ~/.claude/tasks/inter-agent-context.json | jq '.'

# Specific agent output
cat ~/.claude/docs/python-developer-output.md

# Live progress
cat ~/.claude/status/security-auditor-progress.md

# All agent outputs
ls -la ~/.claude/docs/*-output.md

# Watch progress in real-time
watch -n 5 'cat ~/.claude/status/*-progress.md'

# Check for blockers
grep -l "BLOCKED" ~/.claude/status/*-progress.md

# View all completed agents
grep -l "SUCCESS" ~/.claude/docs/*-output.md
```

## File Management Best Practices

### Initialize Workflow

```bash
# Create directories
mkdir -p ~/.claude/{tasks,docs,status}

# Initialize workflow file
cat > ~/.claude/tasks/current-workflow.md <<EOF
# Current Workflow: {Name}
...
EOF

# Create shared context
cat > ~/.claude/tasks/inter-agent-context.json <<EOF
{
  "workflow_type": "api_development",
  ...
}
EOF
```

### Clean Up After Workflow

```bash
# Archive completed workflow
mkdir -p ~/.claude/archive/$(date +%Y%m%d)
mv ~/.claude/docs/* ~/.claude/archive/$(date +%Y%m%d)/
mv ~/.claude/status/* ~/.claude/archive/$(date +%Y%m%d)/

# Reset for next workflow
rm -f ~/.claude/tasks/current-workflow.md
rm -f ~/.claude/tasks/agent-queue.md
echo '{}' > ~/.claude/tasks/inter-agent-context.json
```

## Best Practices

1. **Always read context first** - Never skip context reading
2. **Update progress frequently** - Every major step
3. **Write comprehensive outputs** - Include all decisions
4. **Use structured JSON** - For machine-readable data
5. **Include metrics** - Measurable outcomes
6. **Document blockers** - Immediately when encountered
7. **Clean file names** - Use consistent naming

## Common Pitfalls

- ❌ Not reading previous agent outputs
- ❌ Forgetting to update progress files
- ❌ Writing vague output descriptions
- ❌ Missing handoff notes for next agent
- ❌ Not documenting technical decisions
- ❌ Inconsistent file naming
- ❌ Not cleaning up after workflow

## Examples

### Example 1: Agent Reading Context

```bash
# Python Developer agent starting
# 1. Read workflow
cat ~/.claude/tasks/current-workflow.md
# Learn: Building REST API with FastAPI

# 2. Read queue
cat ~/.claude/tasks/agent-queue.md
# Learn: research-assistant completed, I'm active

# 3. Read shared context
cat ~/.claude/tasks/inter-agent-context.json | jq '.project_context'
# Learn: PostgreSQL database, JWT auth required

# 4. Read dependency output
cat ~/.claude/docs/research-assistant-output.md
# Learn: Requirements gathered, architecture decided

# Ready to start with full context
```

### Example 2: Updating Progress

```bash
# During implementation
cat > ~/.claude/status/python-developer-progress.md <<EOF
# Python Developer Progress

**Status**: IN_PROGRESS
**Current Step**: Implementing authentication endpoints
**Started**: 2025-01-15T10:00:00Z
**Last Updated**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Progress**: 60%

## Current Activity
Adding JWT token validation middleware

## Completed Steps
- ✅ Database models created
- ✅ User registration endpoint
- ✅ Password hashing implemented

## In Progress
- 🔄 JWT token generation (80%)

## Next Steps
- ⏳ Login endpoint
- ⏳ Token refresh logic
EOF
```

## Integration with Other Skills

- **agent-coordination-patterns**: Uses these files for coordination
- **graphiti-episode-storage**: Store file-based coordination episodes
- **git-commit-workflow**: Commit agent outputs to version control

## References

- Related Skills: `agent-coordination-patterns`
- Related Commands: Multi-agent workflow commands
- Replaces: `agent-context-management` (file structure sections)
