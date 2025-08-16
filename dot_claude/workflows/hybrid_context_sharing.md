# Hybrid Context Sharing System

This document describes our enhanced dual-layer approach to agent context sharing that addresses transparency, coordination, and historical intelligence needs.

## Architecture Overview

The system uses **two complementary layers**:

1. **Transparency Layer** (File-based) - For active workflows and human inspection
2. **Intelligence Layer** (Graphiti Memory) - For historical analysis and learning

This hybrid approach solves:
- ✅ **Transparency issues** (Reddit user complaints)
- ✅ **Inter-agent context sharing** (Jason Zhou's Twitter insights)
- ✅ **Historical intelligence** (Pattern recognition and learning)
- ✅ **Easy debugging** (Human-readable file inspection)

## File-Based Transparency Layer

### Directory Structure
```
.claude/
├── tasks/           # Workflow coordination
│   ├── current-workflow.md      # Main workflow status
│   ├── agent-queue.md           # Agent scheduling & dependencies
│   └── inter-agent-context.json # Structured cross-agent data
├── docs/            # Agent outputs & results
│   ├── agent-name-output.md     # Standardized agent results
│   └── agent-output-template.md # Template for consistency
└── status/          # Real-time progress
    └── agent-name-progress.md   # Live status updates
```

### Human Inspection Commands
```bash
# Quick workflow overview
cat .claude/tasks/current-workflow.md

# Check what agents are doing
cat .claude/tasks/agent-queue.md

# See specific agent results
cat .claude/docs/git-expert-output.md

# Monitor real-time progress
cat .claude/status/python-developer-progress.md

# Check inter-agent coordination
jq '.shared_knowledge' .claude/tasks/inter-agent-context.json
```

## Agent Integration Protocol

### 1. Pre-Execution Context Reading
Every agent MUST read these files before starting:

```python
def read_agent_context(agent_name):
    # Required context files
    workflow_status = read_file('.claude/tasks/current-workflow.md')
    agent_queue = read_file('.claude/tasks/agent-queue.md')
    shared_context = read_json('.claude/tasks/inter-agent-context.json')

    # Dependency outputs (based on agent queue)
    dependency_outputs = []
    for dep_agent in get_dependencies(agent_name):
        output_file = f'.claude/docs/{dep_agent}-output.md'
        dependency_outputs.append(read_file(output_file))

    return {
        'workflow': workflow_status,
        'coordination': shared_context,
        'dependencies': dependency_outputs
    }
```

### 2. Progress Reporting During Execution
Update progress file in real-time:

```python
def update_progress(agent_name, step, status, details):
    progress_file = f'.claude/status/{agent_name}-progress.md'
    update_progress_file(progress_file, {
        'current_step': step,
        'status': status,
        'details': details,
        'timestamp': datetime.now().isoformat()
    })
```

### 3. Post-Execution Output Writing
Write standardized results:

```python
def write_agent_output(agent_name, execution_data):
    # Main output documentation
    output_file = f'.claude/docs/{agent_name}-output.md'
    write_structured_output(output_file, execution_data)

    # Update shared context
    update_inter_agent_context(agent_name, execution_data)

    # Update workflow status
    update_workflow_progress(agent_name, 'COMPLETED')

    # Archive to Graphiti Memory
    archive_to_memory(execution_data)
```

## Graphiti Memory Intelligence Layer

### Purpose & Usage
While files provide **immediate transparency**, Graphiti Memory provides:
- **Historical pattern recognition**
- **Cross-project learning**
- **Performance analytics**
- **Long-term institutional knowledge**

### Auto-Archival Process
When workflows complete, file-based data is automatically archived:

```python
def archive_workflow_to_memory(workflow_id):
    # Collect all workflow files
    workflow_data = collect_workflow_files(workflow_id)

    # Store complete workflow
    mcp__graphiti-memory__add_memory(
        name=f"Workflow Complete: {workflow_id}",
        episode_body=json.dumps({
            'workflow_files': workflow_data,
            'performance_metrics': calculate_metrics(workflow_data),
            'agent_coordination': extract_coordination_patterns(workflow_data),
            'success_factors': identify_success_factors(workflow_data)
        }),
        source="json",
        source_description="Complete workflow execution archive",
        group_id="workflow_history"
    )
```

### Intelligence Queries
Use Graphiti Memory for insights:

```python
# Find similar past workflows
similar_workflows = mcp__graphiti-memory__search_memory_facts(
    query="user authentication API FastAPI SQLAlchemy",
    group_ids=["workflow_history"],
    max_facts=5
)

# Analyze agent performance patterns
performance_data = mcp__graphiti-memory__search_memory_facts(
    query="python-developer performance duration success_rate",
    group_ids=["agent_executions"]
)

# Learn from past failures
failure_patterns = mcp__graphiti-memory__search_memory_facts(
    query="workflow status FAILED resolution successful",
    group_ids=["workflow_history", "error_resolution"]
)
```

## Workflow Coordination Examples

### Example 1: Simple Linear Workflow
```markdown
# .claude/tasks/current-workflow.md
## Steps
1. ✅ research-assistant → requirements analysis
2. 🔄 git-expert → repository setup
3. ⏳ python-developer → API implementation
4. ⏳ test-architect → test suite creation
```

### Example 2: Parallel Agent Execution
```json
// .claude/tasks/inter-agent-context.json
{
  "parallel_execution": {
    "frontend_team": ["nodejs-developer", "service-design-expert"],
    "backend_team": ["python-developer", "security-auditor"],
    "coordination_point": "API specification completion"
  }
}
```

### Example 3: Complex Dependencies
```markdown
# .claude/tasks/agent-queue.md
## Dependencies Graph
- python-developer depends on: git-expert, research-assistant
- nodejs-developer depends on: python-developer (API spec)
- test-architect depends on: python-developer, nodejs-developer
- pipeline-engineer depends on: test-architect
```

## Error Handling & Recovery

### File-Based Error Detection
```bash
# Check for stuck agents
find .claude/status/ -name "*-progress.md" -mmin +10

# Identify failed workflows
grep -l "FAILED" .claude/tasks/current-workflow.md

# Find coordination conflicts
jq '.coordination_data.blocking_issues' .claude/tasks/inter-agent-context.json
```

### Automatic Recovery
```python
def detect_and_recover():
    # Check for stale progress files
    stale_agents = find_stale_progress_files()

    # Restart failed agents with context
    for agent in stale_agents:
        context = read_agent_context(agent.name)
        restart_agent_with_context(agent, context)

    # Update coordination status
    update_workflow_recovery_status()
```

## Performance Benefits

### 1. Immediate Transparency
- **No queries needed** - just `cat` files
- **Real-time visibility** - progress updates every 30 seconds
- **Easy debugging** - human-readable formats

### 2. Efficient Agent Coordination
- **Direct context sharing** - agents read each other's outputs
- **Dependency management** - clear prerequisite chains
- **Conflict prevention** - structured coordination protocol

### 3. Persistent Intelligence
- **Pattern recognition** - learn from past workflows
- **Performance optimization** - identify bottlenecks
- **Knowledge accumulation** - build institutional memory

## Migration Guide

### For Existing Agents
1. **Add context reading** before execution starts
2. **Add progress reporting** during execution
3. **Add output writing** after completion
4. **Test with pilot workflows** before full rollout

### For New Workflows
1. **Initialize workflow files** with templates
2. **Define agent dependencies** in queue file
3. **Monitor progress** through file inspection
4. **Archive results** to Graphiti Memory

## Monitoring & Maintenance

### Daily Operations
```bash
# Check active workflows
ls -la .claude/tasks/

# Monitor agent queue
cat .claude/tasks/agent-queue.md

# Review completed outputs
ls -la .claude/docs/
```

### Weekly Analysis
```python
# Generate workflow performance report
weekly_report = analyze_workflow_patterns(
    start_date="2025-01-09",
    end_date="2025-01-16"
)

# Identify optimization opportunities
optimizations = identify_bottlenecks(weekly_report)
```

### Cleanup & Archival
```bash
# Archive old workflows (automated)
./scripts/archive_old_workflows.sh

# Clean status files
find .claude/status/ -mtime +1 -delete

# Generate summary reports
./scripts/generate_weekly_summary.sh
```

This hybrid system provides the best of both worlds: **immediate transparency** through files and **long-term intelligence** through Graphiti Memory.
