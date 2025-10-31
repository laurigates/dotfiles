# Knowledge Graph Integration Patterns

## Description

Proven patterns for using Graphiti Memory to store execution history, learn from past work, and provide audit trails. This skill enables Claude to build institutional knowledge across sessions, recognize patterns, and improve over time.

## When to Use

Automatically apply this skill when:
- Starting tasks similar to previous work
- Need to learn from past successes/failures
- Tracking patterns across sessions
- Error analysis and resolution
- Building knowledge over time
- Need audit trails for compliance
- Analyzing trends in development work

## Core Concept: Episodes and Facts

**Episodes**: Discrete events or pieces of information
- Agent executions
- Workflow completions
- Error resolutions
- Decision rationales

**Facts**: Relationships between entities extracted from episodes
- "Agent X solved problem Y using approach Z"
- "Configuration A causes error B"
- "Pattern C appears in successful projects"

## Episode Storage Patterns

### Pattern 1: Agent Execution Episodes

Store each agent execution for learning and audit:

```python
mcp__graphiti-memory__add_memory(
    name=f"Agent Execution: {agent_name} - {task_summary}",
    episode_body=json.dumps({
        "agent": agent_name,
        "timestamp": datetime.now().isoformat(),
        "task_description": user_request,
        "context_provided": {
            "tech_stack": ["FastAPI", "PostgreSQL"],
            "constraints": ["Must support async", "90% test coverage"]
        },
        "approach_taken": [
            "Researched FastAPI async patterns",
            "Implemented connection pooling",
            "Added pytest-asyncio for testing"
        ],
        "outcome": "SUCCESS|PARTIAL|FAILED",
        "deliverables": [
            "API endpoints in /src/api/",
            "Tests in /tests/",
            "Documentation in /docs/"
        ],
        "lessons_learned": [
            "Async context managers critical for DB connections",
            "pytest-asyncio fixtures simplify testing"
        ],
        "time_spent_minutes": 45,
        "challenges_encountered": [
            "Initial connection pool configuration incorrect"
        ]
    }),
    source="json",
    source_description=f"Agent execution: {agent_name}",
    group_id=f"{agent_name}_executions"
)
```

**When to use**: After every significant agent execution
**Value**: Learn from similar tasks, avoid past mistakes

### Pattern 2: Error Resolution Episodes

Document how errors were resolved:

```python
mcp__graphiti-memory__add_memory(
    name=f"Error Resolved: {error_type} - {solution_summary}",
    episode_body=json.dumps({
        "error_type": "DatabaseConnectionError",
        "context": {
            "tech_stack": ["PostgreSQL", "SQLAlchemy"],
            "environment": "Development"
        },
        "symptoms": [
            "Connection timeouts after 30 seconds",
            "Error: 'pool exhausted'"
        ],
        "root_cause": "Connection pool size too small for async workload",
        "solution_applied": "Increased pool_size to 20, overflow to 10",
        "verification": "No timeouts after load testing",
        "similar_to": "Connection pooling issues seen in project X",
        "prevention": "Always configure pool_size based on expected concurrency"
    }),
    source="json",
    source_description="Error resolution",
    group_id="error_resolutions"
)
```

**When to use**: After resolving non-trivial errors
**Value**: Build error knowledge base, faster future resolution

### Pattern 3: Workflow Execution Episodes

Store complete multi-agent workflow results:

```python
mcp__graphiti-memory__add_memory(
    name=f"Workflow: {workflow_type} - {project_name}",
    episode_body=json.dumps({
        "workflow_type": "api_development",
        "project_name": "User Auth API",
        "duration_minutes": 180,
        "agents_involved": [
            "research-assistant",
            "python-developer",
            "security-auditor",
            "test-architect"
        ],
        "execution_sequence": [
            {"agent": "research-assistant", "duration": 30, "outcome": "success"},
            {"agent": "python-developer", "duration": 90, "outcome": "success"},
            {"agent": "security-auditor", "duration": 45, "outcome": "issues_found"},
            {"agent": "python-developer", "duration": 15, "outcome": "fixes_applied"}
        ],
        "overall_outcome": "SUCCESS",
        "quality_metrics": {
            "test_coverage": "94%",
            "security_issues": "0 high, 2 low",
            "performance": "avg 120ms response time"
        },
        "lessons_learned": [
            "Security audit early prevents rework",
            "Parallel testing during implementation saves time"
        ]
    }),
    source="json",
    source_description="Multi-agent workflow completion",
    group_id="workflow_executions"
)
```

**When to use**: After completing multi-step workflows
**Value**: Optimize workflow patterns, estimate future timelines

### Pattern 4: Decision Rationale Episodes

Document why important decisions were made:

```python
mcp__graphiti-memory__add_memory(
    name=f"Decision: {decision_topic} - {choice_made}",
    episode_body=json.dumps({
        "decision_topic": "API Framework Selection",
        "context": {
            "project_type": "REST API with async I/O",
            "team_expertise": "Python",
            "requirements": ["High performance", "Modern async support"]
        },
        "options_considered": [
            {"option": "Flask", "pros": ["Simple", "Mature"], "cons": ["No async support"]},
            {"option": "FastAPI", "pros": ["Async", "Modern", "Auto docs"], "cons": ["Newer"]},
            {"option": "Django", "pros": ["Full-featured"], "cons": ["Heavy", "Not async-first"]}
        ],
        "decision_made": "FastAPI",
        "rationale": [
            "Async support critical for I/O-heavy workload",
            "Auto OpenAPI docs reduce maintenance",
            "Growing community and adoption"
        ],
        "outcome_months_later": "Excellent performance, team productive"
    }),
    source="json",
    source_description="Technical decision rationale",
    group_id="technical_decisions"
)
```

**When to use**: After making significant technical decisions
**Value**: Remember why decisions were made, inform future choices

## Group ID Conventions

Organize episodes with consistent group IDs:

**By Domain**:
- `python_development` - Python-related tasks
- `nodejs_development` - Node.js/TypeScript tasks
- `rust_development` - Rust programming tasks
- `infrastructure` - DevOps, containers, Kubernetes
- `git_operations` - Git and GitHub operations

**By Activity Type**:
- `agent_executions` - General agent work
- `error_resolutions` - Problem solving
- `workflow_executions` - Multi-step workflows
- `technical_decisions` - Architecture and tech choices
- `code_reviews` - Review findings and improvements

**By Project**:
- `project_auth_api` - Specific project work
- `project_frontend_app` - Another project
- `migration_postgres_to_mongo` - Migration project

**Best Practice**: Use descriptive, consistent group IDs for easy searching

## Memory Retrieval Patterns

### Pattern 1: Search for Similar Past Work

Before starting, search for similar tasks:

```python
# Search for similar operations
mcp__graphiti-memory__search_memory_facts(
    query="FastAPI async database connection setup with PostgreSQL",
    group_ids=["python_development", "agent_executions"],
    max_facts=5
)

# Use results to:
# - Understand approach that worked before
# - Avoid past mistakes
# - Estimate time based on previous similar work
```

### Pattern 2: Search for Error Patterns

When encountering errors, search knowledge base:

```python
# Search for similar errors
mcp__graphiti-memory__search_memory_facts(
    query="PostgreSQL connection pool exhausted timeout",
    group_ids=["error_resolutions"],
    max_facts=3
)

# Use results to:
# - Apply known solutions
# - Avoid trying failed approaches
# - Understand root causes faster
```

### Pattern 3: Search for Node Summaries

Get comprehensive view of entity relationships:

```python
# Search for patterns across entity relationships
mcp__graphiti-memory__search_memory_nodes(
    query="FastAPI performance optimization techniques",
    group_ids=["python_development"],
    max_nodes=5
)

# Use results to:
# - See all optimization patterns discovered
# - Understand relationships between techniques
# - Apply holistic approach
```

### Pattern 4: Search Around Known Good Examples

When you know a specific successful case:

```python
# Search centered on a known good execution
mcp__graphiti-memory__search_memory_facts(
    query="async testing patterns",
    center_node_uuid="<uuid_of_successful_project>",
    max_facts=10
)

# Use results to:
# - Find related successful patterns
# - See what worked in conjunction
# - Build on proven approaches
```

## Learning from History

### Before Starting Work

**Ask**: "Have I done something like this before?"

```
1. Search for similar tasks in relevant group_ids
2. Review past approaches and outcomes
3. Note lessons learned from previous work
4. Apply proven patterns
5. Avoid approaches that failed before
```

### During Work

**Ask**: "Am I encountering a known problem?"

```
1. When error occurs, search error_resolutions
2. Check if similar issue solved before
3. Apply known solutions first
4. Try new approaches if no match
5. Document new resolution for future
```

### After Completing Work

**Ask**: "What should I remember for next time?"

```
1. Store execution episode with approach taken
2. Document lessons learned
3. Note what worked well
4. Record challenges and how overcome
5. Update workflow patterns if improved
```

## Quality Guidelines

### What to Store

✅ **Store**:
- Agent executions with approach and outcome
- Error resolutions with root cause and fix
- Workflow completions with metrics
- Technical decisions with rationale
- Patterns that emerge from work
- Lessons learned from successes and failures

❌ **Don't Store**:
- Trivial operations (single file edits)
- Duplicate information already stored
- Secrets or sensitive data
- Excessively verbose logs
- Work-in-progress (wait for completion)

### Episode Quality

**Good Episode** (specific, actionable):
```json
{
  "task": "Implement JWT authentication for FastAPI",
  "approach": ["Used PyJWT library", "Added middleware decorator"],
  "outcome": "SUCCESS",
  "lessons": "HTTP-only cookies more secure than localStorage"
}
```

**Poor Episode** (vague, unusable):
```json
{
  "task": "Did some auth stuff",
  "approach": ["Used library"],
  "outcome": "It worked"
}
```

## Integration with Other Skills

- **Multi-Agent Workflows**: Store workflow execution patterns for optimization
- **Agent Context Management**: Store agent coordination patterns that work well
- **All Development Skills**: Store language-specific patterns and solutions

## Best Practices

1. **Store after completion** - Wait until work succeeds before storing
2. **Be specific** - Generic episodes aren't useful for learning
3. **Include context** - Tech stack, constraints, requirements
4. **Document outcomes** - Success/failure with metrics
5. **Capture lessons** - What would you do differently?
6. **Use consistent group IDs** - Makes searching effective
7. **Search before starting** - Learn from past work
8. **Update over time** - Add "outcome_months_later" insights

## Common Pitfalls

- ❌ Storing episodes without outcomes (premature storage)
- ❌ Vague descriptions that don't help future work
- ❌ Forgetting to search before starting similar tasks
- ❌ Inconsistent group_ids making search ineffective
- ❌ Storing failures without documenting what to avoid
- ❌ Not capturing "why" for decisions
- ❌ Overly verbose episodes (should be concise summaries)

## Examples

### Learning from Past API Work

```
User: "Build a REST API with authentication"

Claude:
1. Searches: "REST API authentication implementation"
2. Finds: Past FastAPI + JWT work with 94% success rate
3. Reviews: Lessons learned about async patterns
4. Applies: Proven approach from past work
5. Avoids: Connection pool issues documented before
6. Completes: Successfully using historical knowledge
7. Stores: New episode with any improvements made
```

### Resolving Known Error

```
User reports: "Getting database connection timeouts"

Claude:
1. Searches: "database connection timeout errors"
2. Finds: Similar PostgreSQL pool exhaustion from before
3. Applies: Known solution (increase pool_size)
4. Verifies: Issue resolved
5. Updates: Episode if solution evolved
```

## References

- Related Skills: `multi-agent-workflows`, `agent-context-management`
- MCP Server: `graphiti-memory` (configured in settings.json)
- Related Commands: None directly, but all commands benefit from historical knowledge
