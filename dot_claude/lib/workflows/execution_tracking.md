# Execution Tracking & Audit Trail System

This document defines the systematic approach for tracking all agent executions and maintaining comprehensive audit trails.

## Tracking Framework

### 1. Execution Lifecycle
Every agent execution follows this tracked lifecycle:

```yaml
PHASES:
  1. Pre-Delegation: Record intent, expectations, context
  2. Delegation: Log exact prompt sent to subagent
  3. Execution: Monitor subagent actions in real-time
  4. Response: Capture complete subagent output
  5. Verification: Compare expected vs actual outcomes
  6. Storage: Persist execution data for audit
  7. Learning: Extract insights for future improvements
```

### 2. Mandatory Tracking Fields
Every execution must log these core fields:

```json
{
  "execution_id": "uuid-v4",
  "session_id": "main-session-uuid",
  "timestamp_start": "2025-01-16T10:30:00.000Z",
  "timestamp_end": "2025-01-16T10:32:15.234Z",
  "duration_ms": 135234,
  "main_agent_context": {
    "user_request": "original user request",
    "main_agent_reasoning": "why this agent was selected",
    "expected_outcome": "specific success criteria",
    "risk_assessment": "potential failure modes"
  },
  "agent_metadata": {
    "name": "agent-name",
    "version": "v2.0",
    "tools_available": ["tool1", "tool2"],
    "configuration": "agent-specific config"
  },
  "delegation": {
    "prompt_sent": "exact prompt to subagent",
    "prompt_length": 1234,
    "context_provided": "background information",
    "instructions": "specific task directives"
  },
  "execution": {
    "actions_taken": [
      {
        "sequence": 1,
        "tool": "tool-name",
        "action": "description",
        "input": "tool input",
        "output": "tool output",
        "timestamp": "timestamp",
        "success": true,
        "error": null
      }
    ],
    "real_time_status": "monitoring updates",
    "resource_usage": "cpu/memory metrics if available"
  },
  "output": {
    "raw_response": "complete unfiltered subagent output",
    "structured_data": "parsed response data",
    "files_modified": ["list of changed files"],
    "commands_executed": ["bash commands run"],
    "api_calls_made": ["external API interactions"]
  },
  "verification": {
    "status": "MATCH|PARTIAL|MISMATCH|ERROR",
    "expected_vs_actual": "comparison details",
    "success_criteria_met": ["which criteria passed"],
    "success_criteria_failed": ["which criteria failed"],
    "confidence_score": 0.95,
    "manual_verification_required": false
  },
  "quality_metrics": {
    "completeness": "HIGH|MEDIUM|LOW",
    "accuracy": "HIGH|MEDIUM|LOW",
    "efficiency": "HIGH|MEDIUM|LOW",
    "adherence_to_standards": "compliance score"
  },
  "issues": [
    {
      "type": "ERROR|WARNING|INFO",
      "description": "issue description",
      "impact": "effect on outcome",
      "resolution": "how it was handled",
      "prevention": "how to avoid in future"
    }
  ],
  "learning": {
    "insights_gained": ["what was learned"],
    "process_improvements": ["suggested optimizations"],
    "agent_performance": "assessment of agent capability",
    "recommendation_for_future": "guidance for similar tasks"
  }
}
```

## Implementation Patterns

### 1. Pre-Delegation Tracking
Before calling any subagent:

```python
execution_context = {
    "execution_id": str(uuid.uuid4()),
    "session_id": current_session_id,
    "timestamp_start": datetime.now().isoformat(),
    "user_request": original_user_input,
    "selected_agent": agent_name,
    "selection_reasoning": reasoning_for_choice,
    "expected_outcome": success_criteria,
    "risk_factors": identified_risks
}

# Store initial context
mcp__graphiti-memory__add_memory(
    name=f"Execution Start: {execution_context['execution_id']}",
    episode_body=json.dumps(execution_context),
    source="json",
    source_description="Pre-delegation execution context",
    group_id="execution_tracking"
)
```

### 2. Real-Time Monitoring
During subagent execution (conceptual - actual implementation depends on framework):

```python
def monitor_subagent_execution(agent_response_stream):
    execution_log = []

    for action in agent_response_stream:
        action_record = {
            "timestamp": datetime.now().isoformat(),
            "action_type": action.type,
            "tool_used": action.tool,
            "input": action.input,
            "output": action.output,
            "success": action.success,
            "error": action.error if action.error else None
        }
        execution_log.append(action_record)

        # Store periodic updates for long-running operations
        if len(execution_log) % 10 == 0:
            update_execution_progress(execution_id, execution_log)

    return execution_log
```

### 3. Post-Execution Analysis
After subagent completes:

```python
def complete_execution_tracking(execution_id, subagent_response):
    # Load initial context
    initial_context = get_execution_context(execution_id)

    # Perform verification
    verification_result = verify_execution_outcome(
        expected=initial_context['expected_outcome'],
        actual=subagent_response['actual_outcome'],
        actions=subagent_response['actions_taken']
    )

    # Calculate quality metrics
    quality_assessment = assess_execution_quality(
        response=subagent_response,
        standards=get_quality_standards()
    )

    # Extract learning insights
    insights = extract_learning_insights(
        execution_data=subagent_response,
        verification=verification_result,
        historical_data=get_similar_executions(execution_id)
    )

    # Store complete execution record
    complete_record = {
        **initial_context,
        "timestamp_end": datetime.now().isoformat(),
        "subagent_response": subagent_response,
        "verification": verification_result,
        "quality_metrics": quality_assessment,
        "learning_insights": insights
    }

    mcp__graphiti-memory__add_memory(
        name=f"Execution Complete: {execution_id}",
        episode_body=json.dumps(complete_record),
        source="json",
        source_description="Complete execution record",
        group_id="execution_tracking"
    )
```

## Audit Trail Queries

### 1. Performance Analytics
Query execution performance patterns:

```python
# Find slowest operations
slow_executions = mcp__graphiti-memory__search_memory_facts(
    query="duration_ms > 300000",  # > 5 minutes
    group_ids=["execution_tracking"]
)

# Analyze success rates by agent
success_rates = analyze_agent_success_rates()

# Identify common failure patterns
failure_patterns = mcp__graphiti-memory__search_memory_facts(
    query="verification status ERROR MISMATCH",
    group_ids=["execution_tracking"]
)
```

### 2. Quality Assurance
Track quality metrics over time:

```python
# Find quality degradation trends
quality_trends = mcp__graphiti-memory__search_memory_facts(
    query="quality_metrics completeness LOW accuracy LOW",
    group_ids=["execution_tracking"]
)

# Identify high-performing executions for analysis
high_quality = mcp__graphiti-memory__search_memory_facts(
    query="quality_metrics completeness HIGH accuracy HIGH efficiency HIGH",
    group_ids=["execution_tracking"]
)
```

### 3. Security Auditing
Track security-sensitive operations:

```python
# Find executions that modified security-critical files
security_changes = mcp__graphiti-memory__search_memory_facts(
    query="files_modified secrets auth credentials config",
    group_ids=["execution_tracking"]
)

# Track API credential usage
api_usage = mcp__graphiti-memory__search_memory_facts(
    query="api_calls_made github aws gcp",
    group_ids=["execution_tracking"]
)
```

## Reporting & Dashboards

### 1. Daily Execution Summary
Generate daily summaries:

```python
def generate_daily_execution_report(date):
    executions = get_executions_by_date(date)

    summary = {
        "total_executions": len(executions),
        "success_rate": calculate_success_rate(executions),
        "average_duration": calculate_avg_duration(executions),
        "agents_used": get_agent_usage_stats(executions),
        "quality_scores": get_quality_distribution(executions),
        "top_issues": get_most_common_issues(executions),
        "improvement_opportunities": identify_improvements(executions)
    }

    return summary
```

### 2. Agent Performance Metrics
Track individual agent performance:

```python
def agent_performance_report(agent_name, time_period):
    agent_executions = get_agent_executions(agent_name, time_period)

    return {
        "execution_count": len(agent_executions),
        "success_rate": calculate_success_rate(agent_executions),
        "average_quality_score": calculate_avg_quality(agent_executions),
        "common_failure_modes": analyze_failures(agent_executions),
        "performance_trend": calculate_trend(agent_executions),
        "recommendations": generate_agent_recommendations(agent_executions)
    }
```

## Data Retention & Cleanup

### 1. Retention Policy
Define data retention rules:

```yaml
RETENTION_POLICY:
  execution_tracking:
    successful_executions: 90_days
    failed_executions: 180_days
    high_quality_executions: 365_days
    security_relevant: 2_years

  cleanup_schedule:
    daily: remove_temp_logs
    weekly: archive_old_executions
    monthly: generate_summary_reports
    quarterly: full_audit_review
```

### 2. Automated Cleanup
Implement automated data management:

```python
def cleanup_old_executions():
    cutoff_date = datetime.now() - timedelta(days=90)
    old_executions = get_executions_before_date(cutoff_date)

    for execution in old_executions:
        if should_archive(execution):
            archive_execution(execution)
        else:
            delete_execution(execution)
```

This tracking system provides comprehensive oversight of all agent operations while enabling continuous improvement through data-driven insights.
