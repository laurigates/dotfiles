# Auto-Sync Mechanism for Graphiti Memory

This document describes the automatic synchronization system that archives file-based workflow data to Graphiti Memory for long-term intelligence and analysis.

## Overview

The auto-sync mechanism bridges the **Transparency Layer** (files) and **Intelligence Layer** (Graphiti Memory) by:
- **Detecting workflow completion** through file monitoring
- **Collecting all workflow artifacts** (tasks, docs, status files)
- **Extracting structured insights** for pattern recognition
- **Archiving to Graphiti Memory** with proper organization
- **Cleaning up temporary files** to maintain file system hygiene

## Trigger Conditions

### Workflow Completion Detection
Monitor these indicators for auto-sync triggers:

1. **Workflow Status Change**:
   ```bash
   # Detect status change to COMPLETED in current-workflow.md
   grep -q "Status.*COMPLETED" .claude/tasks/current-workflow.md
   ```

2. **All Agents Completed**:
   ```bash
   # Check if all agents in queue are marked as COMPLETED
   grep -c "Status.*COMPLETED" .claude/tasks/agent-queue.md
   ```

3. **No Active Progress Files**:
   ```bash
   # Ensure no agents are currently running
   find .claude/status/ -name "*-progress.md" -mmin -5 | wc -l
   ```

4. **Manual Trigger**:
   ```bash
   # User can manually trigger sync
   touch .claude/tasks/trigger-sync
   ```

## Data Collection Process

### 1. Workflow Metadata Extraction
```python
def extract_workflow_metadata():
    # Parse current-workflow.md
    workflow_data = parse_markdown_file('.claude/tasks/current-workflow.md')

    return {
        'workflow_id': workflow_data.get('workflow_id'),
        'objective': workflow_data.get('main_objective'),
        'start_time': workflow_data.get('started'),
        'end_time': datetime.now().isoformat(),
        'total_steps': workflow_data.get('total_steps'),
        'completed_steps': workflow_data.get('completed'),
        'overall_success': determine_success_status(workflow_data),
        'technologies_used': extract_tech_stack(workflow_data)
    }
```

### 2. Agent Performance Data
```python
def collect_agent_performance():
    agent_data = []

    # Parse agent-queue.md for execution times
    queue_data = parse_markdown_file('.claude/tasks/agent-queue.md')

    # Collect individual agent outputs
    for output_file in glob('.claude/docs/*-output.md'):
        agent_name = extract_agent_name(output_file)
        agent_output = parse_agent_output(output_file)

        agent_data.append({
            'agent': agent_name,
            'start_time': agent_output.get('started'),
            'end_time': agent_output.get('completed'),
            'duration': calculate_duration(agent_output),
            'success_status': agent_output.get('status'),
            'files_modified': agent_output.get('files_created_modified'),
            'quality_metrics': agent_output.get('quality_verification'),
            'issues_encountered': agent_output.get('issues_encountered'),
            'confidence_score': agent_output.get('confidence_score')
        })

    return agent_data
```

### 3. Inter-Agent Context Analysis
```python
def analyze_inter_agent_context():
    context_data = read_json('.claude/tasks/inter-agent-context.json')

    return {
        'coordination_effectiveness': assess_coordination_quality(context_data),
        'context_sharing_success': measure_context_usage(context_data),
        'dependencies_met': verify_dependency_satisfaction(context_data),
        'shared_knowledge_evolution': track_knowledge_changes(context_data),
        'cross_agent_variables': extract_shared_variables(context_data)
    }
```

## Archival Structure in Graphiti Memory

### 1. Complete Workflow Archive
```python
def archive_complete_workflow(workflow_id):
    # Collect all workflow data
    workflow_metadata = extract_workflow_metadata()
    agent_performance = collect_agent_performance()
    context_analysis = analyze_inter_agent_context()
    file_artifacts = collect_file_artifacts()

    # Create comprehensive workflow record
    complete_workflow = {
        'metadata': workflow_metadata,
        'agent_performance': agent_performance,
        'context_analysis': context_analysis,
        'artifacts': file_artifacts,
        'performance_metrics': calculate_workflow_metrics(),
        'lessons_learned': extract_lessons_learned(),
        'success_factors': identify_success_factors(),
        'improvement_opportunities': identify_improvements()
    }

    # Store in Graphiti Memory
    mcp__graphiti-memory__add_memory(
        name=f"Workflow Archive: {workflow_id}",
        episode_body=json.dumps(complete_workflow),
        source="json",
        source_description="Complete workflow execution with performance analysis",
        group_id="workflow_archives"
    )
```

### 2. Agent Performance Patterns
```python
def archive_agent_patterns():
    for agent_data in agent_performance:
        # Extract patterns for each agent
        pattern_data = {
            'agent_name': agent_data['agent'],
            'performance_metrics': {
                'average_duration': agent_data['duration'],
                'success_rate': agent_data['success_status'],
                'quality_score': agent_data['quality_metrics']
            },
            'common_issues': agent_data['issues_encountered'],
            'optimal_conditions': identify_optimal_conditions(agent_data),
            'improvement_suggestions': generate_improvements(agent_data)
        }

        mcp__graphiti-memory__add_memory(
            name=f"Agent Pattern: {agent_data['agent']} - {workflow_id}",
            episode_body=json.dumps(pattern_data),
            source="json",
            source_description="Agent performance pattern analysis",
            group_id=f"{agent_data['agent']}_patterns"
        )
```

### 3. Cross-Workflow Learning
```python
def store_cross_workflow_insights():
    # Compare with previous similar workflows
    similar_workflows = mcp__graphiti-memory__search_memory_facts(
        query=f"workflow objective {workflow_metadata['objective']}",
        group_ids=["workflow_archives"],
        max_facts=5
    )

    # Extract comparative insights
    comparative_analysis = {
        'performance_comparison': compare_performance(similar_workflows),
        'approach_differences': analyze_approach_differences(similar_workflows),
        'success_factor_evolution': track_success_factors(similar_workflows),
        'efficiency_improvements': measure_efficiency_gains(similar_workflows)
    }

    mcp__graphiti-memory__add_memory(
        name=f"Cross-Workflow Learning: {workflow_id}",
        episode_body=json.dumps(comparative_analysis),
        source="json",
        source_description="Comparative analysis across similar workflows",
        group_id="workflow_learning"
    )
```

## Implementation Integration

### 1. Main Agent Integration
```python
# In main agent workflow completion handler
def on_workflow_complete(workflow_id):
    # Trigger auto-sync
    if detect_workflow_completion():
        auto_sync_to_memory(workflow_id)
        cleanup_workflow_files(workflow_id)
        generate_completion_summary(workflow_id)
```

### 2. File System Monitoring
```python
# Watch for completion indicators
def monitor_workflow_completion():
    # Use filesystem events or periodic checks
    for workflow_file in ['.claude/tasks/current-workflow.md']:
        if file_indicates_completion(workflow_file):
            workflow_id = extract_workflow_id(workflow_file)
            schedule_auto_sync(workflow_id)
```

### 3. Background Processing
```python
# Process sync in background to avoid blocking
async def background_sync_processor():
    while True:
        sync_queue = get_pending_syncs()
        for workflow_id in sync_queue:
            await async_sync_workflow(workflow_id)
        await asyncio.sleep(30)  # Check every 30 seconds
```

## Error Handling & Recovery

### 1. Sync Failure Recovery
```python
def handle_sync_failure(workflow_id, error):
    # Log failure details
    log_sync_error(workflow_id, error)

    # Preserve file artifacts
    backup_workflow_files(workflow_id)

    # Schedule retry
    schedule_sync_retry(workflow_id, delay_minutes=5)

    # Notify user if critical
    if is_critical_failure(error):
        notify_sync_failure(workflow_id, error)
```

### 2. Data Validation
```python
def validate_sync_data(workflow_data):
    # Check required fields
    required_fields = ['workflow_id', 'metadata', 'agent_performance']
    for field in required_fields:
        if field not in workflow_data:
            raise SyncValidationError(f"Missing required field: {field}")

    # Validate data integrity
    if not validate_timestamps(workflow_data):
        raise SyncValidationError("Invalid timestamp data")

    # Check file references
    validate_file_references(workflow_data)
```

### 3. Conflict Resolution
```python
def resolve_sync_conflicts(workflow_id):
    # Check for existing workflow data
    existing = mcp__graphiti-memory__search_memory_facts(
        query=f"workflow_id {workflow_id}",
        group_ids=["workflow_archives"]
    )

    if existing:
        # Compare and merge if necessary
        merged_data = merge_workflow_data(existing, new_data)
        update_existing_memory(existing.uuid, merged_data)
    else:
        # Store as new workflow
        store_new_workflow(workflow_id)
```

## File Cleanup Strategy

### 1. Post-Sync Cleanup
```python
def cleanup_after_sync(workflow_id):
    # Archive important files
    archive_workflow_files(workflow_id)

    # Clean temporary files
    remove_status_files()
    remove_old_progress_files()

    # Preserve key artifacts
    preserve_output_files(important_outputs=['final-summary.md'])

    # Update file system state
    mark_workflow_archived(workflow_id)
```

### 2. Retention Policies
```python
RETENTION_POLICY = {
    'workflow_files': {
        'current-workflow.md': 'archive_after_sync',
        'agent-queue.md': 'archive_after_sync',
        'inter-agent-context.json': 'archive_after_sync'
    },
    'output_files': {
        '*-output.md': 'keep_for_7_days',
        'final-summary.md': 'keep_for_30_days'
    },
    'status_files': {
        '*-progress.md': 'delete_after_sync'
    }
}
```

## Monitoring & Analytics

### 1. Sync Performance Metrics
```python
def track_sync_performance():
    metrics = {
        'sync_duration': measure_sync_time(),
        'data_volume': calculate_data_size(),
        'memory_usage': get_memory_consumption(),
        'file_count': count_processed_files(),
        'error_rate': calculate_error_rate()
    }

    store_sync_metrics(metrics)
```

### 2. Quality Assurance
```python
def verify_sync_quality():
    # Verify data completeness
    completeness_score = verify_data_completeness()

    # Check data accuracy
    accuracy_score = validate_data_accuracy()

    # Assess retrieval performance
    retrieval_score = test_memory_retrieval()

    return {
        'completeness': completeness_score,
        'accuracy': accuracy_score,
        'retrievability': retrieval_score,
        'overall_quality': calculate_overall_score()
    }
```

This auto-sync mechanism ensures that all valuable workflow data is preserved in Graphiti Memory while maintaining the file-based transparency that users need for immediate inspection and debugging.
