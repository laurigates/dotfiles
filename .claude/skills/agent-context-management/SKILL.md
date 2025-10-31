# Agent Context Management

## Description

Best practices for agent context sharing and coordination in multi-agent workflows. This skill ensures agents have necessary context from previous work, can communicate findings to downstream agents, and maintain transparency throughout execution.

## When to Use

Automatically apply this skill when:
- Delegating work to specialized agents
- Need to maintain context across agent handoffs
- Building multi-step workflows with checkpoints
- Multiple agents working on the same project
- Need to inspect or debug agent operations
- Coordinating parallel agent tracks that must merge

## Core Principle: Hybrid Context Sharing

Two complementary layers work together:

**1. Transparency Layer** (File-Based)
- Human-inspectable files
- Real-time progress visibility
- Easy debugging and inspection
- Clear agent coordination

**2. Intelligence Layer** (Knowledge Graph)
- Historical learning
- Pattern recognition
- Cross-session persistence
- Audit trails

## File-Based Context Structure

### Directory Organization
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

### File Purposes

**`current-workflow.md`** - Workflow overview
- Workflow ID and objective
- Overall progress (completed/in-progress/pending steps)
- Tech stack and requirements
- Success criteria

**`agent-queue.md`** - Agent scheduling
- List of agents in execution order
- Dependencies between agents
- Current active agent
- Waiting agents

**`inter-agent-context.json`** - Shared structured data
- Project-wide requirements
- Coordination rules
- Shared decisions
- Technical constraints

**`{agent}-output.md`** - Agent results
- What the agent accomplished
- Decisions made
- Artifacts created
- Handoff notes for next agent

**`{agent}-progress.md`** - Live updates
- Current step
- Status (starting/in-progress/completed/blocked)
- Timestamp
- Details

## Agent Integration Protocol

### Phase 1: Pre-Execution Context Reading

Before starting work, agents MUST read:

1. **Workflow Status** (`current-workflow.md`)
   - Understand overall objective
   - See completed steps
   - Know position in workflow

2. **Agent Queue** (`agent-queue.md`)
   - Identify dependencies
   - Know which agents completed before
   - Understand who comes next

3. **Shared Context** (`inter-agent-context.json`)
   - Project-wide requirements
   - Technical standards
   - Coordination rules

4. **Dependency Outputs** (`{dependency-agent}-output.md`)
   - Read outputs from prerequisite agents
   - Understand decisions already made
   - Build on previous work

**Example Context Reading**:
```
User delegates to python-developer agent:

1. Read current-workflow.md → Learn this is API project
2. Read agent-queue.md → See research-assistant and git-expert completed
3. Read inter-agent-context.json → Tech stack is FastAPI + PostgreSQL
4. Read research-assistant-output.md → Requirements and architecture decisions
5. Read git-expert-output.md → Repository structure and setup
6. Begin implementation with full context
```

### Phase 2: Progress Reporting During Execution

Continuously update progress file:

**`{agent}-progress.md` format**:
```markdown
# {Agent Name} Progress

**Status**: IN_PROGRESS
**Current Step**: Implementing authentication endpoints
**Started**: 2025-01-15T14:30:00Z
**Last Updated**: 2025-01-15T14:35:00Z

## Current Activity
Writing JWT token generation and validation logic.

## Completed
- ✅ Database models created
- ✅ User registration endpoint
- ✅ Password hashing setup

## Next Steps
- ⏳ Login endpoint
- ⏳ Token refresh logic
- ⏳ Protected route middleware
```

### Phase 3: Post-Execution Output Writing

Write standardized results for downstream agents:

**`{agent}-output.md` format**:
```markdown
# {Agent Name} Output

**Agent**: {agent-name}
**Completed**: {timestamp}
**Status**: SUCCESS|PARTIAL|FAILED

## Objective
What this agent was asked to accomplish.

## Accomplishments
- Specific deliverables created
- Problems solved
- Features implemented

## Decisions Made
Key technical decisions that affect downstream work:
- Technology choices
- Architecture patterns
- Implementation approaches

## Artifacts Created
Files, directories, resources produced:
- `/src/api/` - API implementation
- `/tests/` - Test suite
- `/docs/api.md` - API documentation

## Known Issues
Problems encountered that need attention:
- Performance bottleneck in X
- Edge case Y not yet handled

## Handoff Notes
What the next agent needs to know:
- Dependencies installed
- Environment variables required
- Tests currently failing (if any)

## Context for Next Agent
Specific guidance for downstream agents:
- "Security auditor: Focus on auth flow in /src/api/auth.py"
- "Test architect: Database fixtures available in /tests/fixtures/"
```

## Coordination Patterns

### Sequential Coordination
Agents work one after another, each building on previous work.

**Pattern**:
```
Agent A completes → Writes output
  ↓
Agent B reads A's output → Starts work → Writes output
  ↓
Agent C reads A's and B's outputs → Starts work
```

**When to use**: Clear dependencies, each step requires previous completion

**Example**: Research → Implementation → Testing

### Parallel Coordination
Multiple agents work simultaneously on independent tasks.

**Pattern**:
```
Agent A starts → Works independently → Writes output
Agent B starts → Works independently → Writes output
  ↓
Agent C reads both A and B → Integration work
```

**When to use**: Independent work streams, no direct dependencies

**Example**: Backend + Frontend development in parallel

### Iterative Coordination
Agent revisits work based on feedback from other agents.

**Pattern**:
```
Agent A → Agent B reviews → Issues found
  ↓
Agent A reads feedback → Refines work → Agent B re-reviews
```

**When to use**: Quality improvement cycles, refinement needed

**Example**: Implementation → Code Review → Refinement

## Shared Context Structure

### inter-agent-context.json Schema

```json
{
  "workflow_type": "api_development|fullstack|infrastructure|quality_review",

  "project_context": {
    "name": "Project Name",
    "type": "REST API|Web App|Infrastructure|Library",
    "tech_stack": {
      "language": "Python|JavaScript|Rust|Go",
      "framework": "FastAPI|React|Axum|Gin",
      "database": "PostgreSQL|MongoDB|Redis",
      "testing": "pytest|Jest|cargo test"
    }
  },

  "shared_requirements": {
    "authentication": "JWT|OAuth|Session",
    "api_standards": "RESTful|GraphQL|gRPC",
    "security_level": "Development|Production|High-Security",
    "test_coverage": "Minimum percentage required",
    "performance": "Response time targets"
  },

  "coordination_rules": {
    "code_style": "Black|Prettier|rustfmt",
    "git_workflow": "Feature branches|Trunk-based",
    "documentation": "Inline|External|Both",
    "security": "Secrets handling approach"
  },

  "integration_requirements": {
    "api_contract": "How APIs are defined",
    "data_formats": "JSON|Protobuf|etc",
    "error_handling": "Error response format",
    "versioning": "API versioning strategy"
  }
}
```

## Human Inspection

Quick commands to monitor agent activity:

```bash
# Workflow overview
cat ~/.claude/tasks/current-workflow.md

# See agent queue
cat ~/.claude/tasks/agent-queue.md

# Check specific agent output
cat ~/.claude/docs/python-developer-output.md

# Monitor live progress
cat ~/.claude/status/security-auditor-progress.md

# View shared context
cat ~/.claude/tasks/inter-agent-context.json | jq
```

## Best Practices

### 1. Always Read Context First
Never start work without reading:
- Workflow status
- Agent queue
- Shared context
- Dependency outputs

### 2. Update Progress Frequently
Update progress file at each major step:
- Starting new phase
- Completing subtask
- Encountering blocker
- Finishing work

### 3. Write Comprehensive Outputs
Include in output:
- What was accomplished
- Decisions made
- Issues encountered
- Handoff notes for next agent

### 4. Use Structured Data
Store machine-readable data in JSON for:
- Configuration
- Requirements
- Standards
- Integration contracts

### 5. Maintain Transparency
All agent operations should be human-inspectable:
- Files use markdown for readability
- Progress updates in real-time
- Clear naming conventions

## Integration with Other Skills

- **Multi-Agent Workflows**: Defines how agents coordinate in complex workflows
- **Knowledge Graph Patterns**: Stores execution history for learning
- **Git Workflow**: Ensures proper version control during agent work

## Common Pitfalls

- ❌ Starting work without reading context
- ❌ Not updating progress during execution
- ❌ Writing vague or incomplete outputs
- ❌ Forgetting handoff notes for next agent
- ❌ Not documenting decisions made
- ❌ Assuming next agent has context you had

## Examples

### Sequential Agent Handoff
```
Research Assistant:
- Reads: current-workflow.md
- Writes: research-assistant-output.md with requirements

Python Developer:
- Reads: research-assistant-output.md
- Understands requirements and decisions
- Implements accordingly
- Writes: python-developer-output.md with implementation notes

Security Auditor:
- Reads: python-developer-output.md
- Knows what to audit and where
- Focuses review on auth implementation
- Writes: security-auditor-output.md with findings
```

### Parallel Agent Coordination
```
Backend Developer:
- Reads: shared API contract from inter-agent-context.json
- Implements API
- Writes: backend-output.md

Frontend Developer (parallel):
- Reads: same API contract
- Implements UI calling that contract
- Writes: frontend-output.md

Integration Tester:
- Reads: Both outputs
- Tests contract adherence
- Verifies integration works
```

## References

- Related Skills: `multi-agent-workflows`, `knowledge-graph-patterns`
- Related Agents: All specialized agents
- Related Commands: `/git:smartcommit` for committing agent outputs
