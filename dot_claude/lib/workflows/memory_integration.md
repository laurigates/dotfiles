# Graphiti Memory Integration for Agent Tracking

This document outlines how to use Graphiti Memory for persistent agent execution tracking and audit trails.

## Overview

Graphiti Memory provides a knowledge graph for storing and retrieving agent execution history, enabling:
- **Audit Trails**: Complete history of agent interactions
- **Pattern Recognition**: Learn from past executions
- **Context Persistence**: Maintain knowledge across sessions
- **Error Analysis**: Track and analyze failure patterns

## Memory Storage Pattern

### 1. Agent Execution Episodes
Store each agent execution as an episode:

```python
mcp__graphiti-memory__add_memory(
    name=f"Agent Execution: {agent_name} - {task_summary}",
    episode_body=json.dumps({
        "agent": agent_name,
        "timestamp": datetime.now().isoformat(),
        "input_received": input_data,
        "expected_outcome": expected_result,
        "actions_taken": action_list,
        "actual_outcome": final_result,
        "verification_status": "MATCH|PARTIAL|MISMATCH",
        "confidence_score": 0.95,
        "issues_encountered": issues_list,
        "full_output": complete_output
    }),
    source="json",
    source_description=f"Agent execution log for {agent_name}",
    group_id=f"{agent_name}_executions"
)
```

### 2. Group ID Conventions
Use consistent group IDs for organization:
- `git_operations` - All Git/GitHub operations
- `python_development` - Python-related tasks
- `nodejs_development` - Node.js/TypeScript tasks
- `agent_executions` - General agent execution logs
- `error_tracking` - Failed operations and resolutions

### 3. Execution Context Storage
Store broader context for complex workflows:

```python
mcp__graphiti-memory__add_memory(
    name=f"Workflow Context: {workflow_name}",
    episode_body=json.dumps({
        "workflow_id": workflow_id,
        "main_objective": primary_goal,
        "agents_involved": [agent_names],
        "execution_sequence": step_by_step_log,
        "overall_status": "SUCCESS|PARTIAL|FAILED",
        "lessons_learned": insights_list
    }),
    source="json",
    source_description="Multi-agent workflow execution",
    group_id="workflow_executions"
)
```

## Memory Retrieval Patterns

### 1. Search Past Executions
Find similar past operations:

```python
# Search for similar agent operations
mcp__graphiti-memory__search_memory_facts(
    query="python project setup with uv and pytest",
    group_ids=["python_development"],
    max_facts=5
)

# Search for error patterns
mcp__graphiti-memory__search_memory_nodes(
    query="dependency conflict resolution",
    max_nodes=10
)
```

### 2. Agent Performance Analysis
Query agent success rates and patterns:

```python
# Get recent executions for an agent
mcp__graphiti-memory__get_episodes(
    group_id="git_operations",
    last_n=20
)

# Search for failed operations
mcp__graphiti-memory__search_memory_facts(
    query="verification_status MISMATCH git operations",
    group_ids=["git_operations"]
)
```

## Main Agent Integration

### Pre-Delegation Memory Check
Before delegating to a subagent:

```python
# Search for similar past tasks
relevant_history = mcp__graphiti-memory__search_memory_facts(
    query=f"{task_description} {agent_name}",
    group_ids=[f"{agent_name}_executions"],
    max_facts=3
)

# Use insights to improve delegation prompt
if relevant_history:
    enhanced_prompt = f"""
    {original_prompt}

    CONTEXT FROM PAST EXECUTIONS:
    {format_history_insights(relevant_history)}

    Pay special attention to any patterns or issues from previous similar tasks.
    """
```

### Post-Execution Storage
After receiving subagent response:

```python
# Store the complete interaction
execution_memory = {
    "delegation_timestamp": start_time,
    "completion_timestamp": end_time,
    "main_agent_prompt": delegation_prompt,
    "subagent_response": complete_response,
    "verification_performed": verification_results,
    "user_satisfaction": feedback_score,
    "follow_up_actions": next_steps
}

mcp__graphiti-memory__add_memory(
    name=f"Delegation: {agent_name} - {timestamp}",
    episode_body=json.dumps(execution_memory),
    source="json",
    source_description="Main agent delegation record",
    group_id="delegation_history"
)
```

## Error Recovery Integration

### Failure Pattern Recognition
When agents report failures:

```python
# Search for similar failure patterns
failure_patterns = mcp__graphiti-memory__search_memory_facts(
    query=f"error {error_type} {agent_name}",
    group_ids=[f"{agent_name}_executions", "error_tracking"]
)

# Identify recovery strategies
for pattern in failure_patterns:
    if pattern.resolution_successful:
        suggested_recovery = pattern.resolution_strategy
```

### Knowledge Accumulation
Build institutional knowledge:

```python
# Store successful problem resolution
mcp__graphiti-memory__add_memory(
    name=f"Resolution Pattern: {error_type}",
    episode_body=json.dumps({
        "problem_description": error_details,
        "context": execution_context,
        "resolution_steps": solution_steps,
        "success_indicators": verification_points,
        "applicable_agents": [agent_names],
        "confidence_score": 0.9
    }),
    source="json",
    source_description="Successful error resolution pattern",
    group_id="resolution_patterns"
)
```

## Usage Guidelines

### 1. Storage Frequency
- **Always**: Store agent executions that modify system state
- **Selective**: Store read-only operations that provide valuable insights
- **Aggregate**: Combine multiple small operations into single memory entries

### 2. Data Quality
- **Structured**: Use JSON format for queryable data
- **Complete**: Include all relevant execution details
- **Contextual**: Provide enough context for future retrieval

### 3. Privacy & Security
- **Sanitize**: Remove sensitive data (secrets, personal info)
- **Classify**: Use appropriate group IDs for access control
- **Expire**: Consider retention policies for old data

## Performance Optimization

### 1. Batch Operations
Store multiple related operations together:

```python
batch_memory = {
    "batch_id": batch_identifier,
    "operations": [operation_list],
    "summary": aggregate_results
}
```

### 2. Strategic Querying
- Use specific group IDs to limit search scope
- Include relevant keywords in memory names
- Structure JSON for efficient fact extraction

### 3. Memory Cleanup
Periodically clean old or irrelevant memories:

```python
# Remove outdated execution logs
old_episodes = mcp__graphiti-memory__get_episodes(
    group_id="agent_executions",
    last_n=1000  # Get large batch for filtering
)

# Delete entries older than retention period
for episode in old_episodes:
    if is_older_than_retention_period(episode):
        mcp__graphiti-memory__delete_episode(episode.uuid)
```

This integration provides the foundation for building self-improving agent systems that learn from experience and maintain institutional knowledge.
