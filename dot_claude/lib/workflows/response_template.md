# Agent Response Template v2.0

This template ensures transparency and accountability in all agent interactions.

## Response Structure

### 1. Agent Identification
```yaml
agent: "agent-name"
timestamp: "2025-01-16T10:30:00Z"
session_id: "unique-session-identifier"
```

### 2. Input Transparency
```yaml
input_received: |
  Exact verbatim input from main agent.
  No paraphrasing or interpretation.
  Preserve formatting and context.
```

### 3. Expectation Setting
```yaml
expected_outcome: |
  Clear statement of what was requested.
  Success criteria defined.
  Measurable objectives listed.
```

### 4. Execution Logging
```yaml
actions_taken:
  - step: 1
    action: "Specific action description"
    tool_used: "tool-name"
    result: "Exact outcome"
    timestamp: "2025-01-16T10:31:00Z"
  - step: 2
    action: "Next action description"
    tool_used: "tool-name"
    result: "Exact outcome"
    timestamp: "2025-01-16T10:32:00Z"
```

### 5. Outcome Verification
```yaml
actual_outcome: |
  What was actually achieved.
  Concrete deliverables produced.
  Files modified, commands run, etc.

verification_status: "MATCH|PARTIAL|MISMATCH"
verification_details: |
  Explanation of verification status.
  Specific differences if PARTIAL/MISMATCH.
  Evidence supporting the assessment.
```

### 6. Quality Metrics
```yaml
confidence_score: 0.95  # 0.0 to 1.0
quality_indicators:
  - completeness: "HIGH|MEDIUM|LOW"
  - accuracy: "HIGH|MEDIUM|LOW"
  - efficiency: "HIGH|MEDIUM|LOW"
```

### 7. Issue Reporting
```yaml
issues_encountered:
  - type: "ERROR|WARNING|INFO"
    description: "Detailed issue description"
    resolution: "How it was handled"
    impact: "Effect on final outcome"
```

### 8. Recommendations
```yaml
recommendations:
  - category: "IMPROVEMENT|WARNING|FOLLOW_UP"
    description: "Specific recommendation"
    priority: "HIGH|MEDIUM|LOW"
    rationale: "Why this is recommended"
```

### 9. Full Output Preservation
```yaml
full_output: |
  Complete unfiltered output from all tools used.
  Preserve all stdout, stderr, logs.
  Include debugging information.
  No summarization or interpretation.
```

## Usage Instructions

1. **Copy this template** for each agent response
2. **Fill ALL sections** - use "N/A" if not applicable
3. **Preserve exact tool outputs** in full_output
4. **Use structured data** where possible (YAML/JSON)
5. **Include timestamps** for audit trails
6. **Be precise** - avoid vague language

## Memory Integration

Each response should also trigger a Graphiti Memory storage:
```python
mcp__graphiti-memory__add_memory(
    name=f"Agent Execution: {agent_name}",
    episode_body=json.dumps(response_data),
    source="json",
    source_description="Agent execution log",
    group_id="agent_executions"
)
```

### 10. File-Based Context Operations
```yaml
context_files:
  read:
    - ".claude/tasks/current-workflow.md"
    - ".claude/tasks/agent-queue.md"
    - ".claude/tasks/inter-agent-context.json"
    - ".claude/docs/git-expert-output.md"
  updated:
    - ".claude/status/agent-name-progress.md"
    - ".claude/tasks/inter-agent-context.json"
  created:
    - ".claude/docs/agent-name-output.md"

file_operations:
  progress_file: ".claude/status/agent-name-progress.md"
  output_file: ".claude/docs/agent-name-output.md"
  context_updates: |
    Updated shared context with:
    - New configuration values
    - Environment setup details
    - Dependencies installed
    - Files created/modified
```

## Validation Checklist

- [ ] All required fields completed
- [ ] Verification status accurate
- [ ] Full tool outputs preserved
- [ ] Issues documented with resolutions
- [ ] Recommendations include rationale
- [ ] Memory entry created for persistence
- [ ] **Context files read** before execution
- [ ] **Progress file updated** during execution
- [ ] **Output file created** with standardized format
- [ ] **Inter-agent context updated** with shared data
