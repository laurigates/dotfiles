---
name: ArgoCD Investigation
description: Expert ArgoCD troubleshooting, event analysis, sync debugging, and health investigation. Use when analyzing ArgoCD application issues, sync failures, health degradation, or Kubernetes deployment problems.
allowed-tools: Bash, Read, Grep, Glob, mcp__argocd, mcp__github
---

# ArgoCD Investigation

Expert knowledge for investigating, debugging, and resolving ArgoCD application issues, sync failures, and health problems.

## Core Expertise

**Application Health Analysis**
- Diagnose Degraded, Missing, Unknown health states
- Identify resource-level health issues
- Trace health cascades across dependencies

**Sync Troubleshooting**
- Debug OutOfSync conditions
- Analyze sync failures and operation errors
- Resolve stuck syncs and prune issues

**Event Pattern Recognition**
- Identify recurring error patterns
- Correlate Kubernetes events with ArgoCD state
- Detect configuration drift and conflicts

**Root Cause Analysis**
- Trace issues to configuration, resources, or cluster state
- Differentiate transient from persistent problems
- Prioritize based on impact and urgency

## Essential Commands

### Application Status

```bash
# List all applications with status
argocd app list

# Get detailed app status
argocd app get <app-name>

# Get app status as JSON (for parsing)
argocd app get <app-name> -o json

# Get specific fields
argocd app get <app-name> -o json | jq '{
  health: .status.health.status,
  sync: .status.sync.status,
  conditions: .status.conditions
}'

# List apps by health status
argocd app list -o json | jq '.[] | select(.status.health.status != "Healthy") | .metadata.name'

# List OutOfSync apps
argocd app list -o json | jq '.[] | select(.status.sync.status == "OutOfSync") | .metadata.name'
```

### Sync Operations

```bash
# Sync application
argocd app sync <app-name>

# Sync with prune (delete removed resources)
argocd app sync <app-name> --prune

# Sync specific resources
argocd app sync <app-name> --resource <group>:<kind>:<name>

# Force sync (ignore hooks)
argocd app sync <app-name> --force

# Dry run sync
argocd app sync <app-name> --dry-run

# Get sync history
argocd app history <app-name>

# Rollback to previous revision
argocd app rollback <app-name> <revision>
```

### Resource Inspection

```bash
# List managed resources
argocd app resources <app-name>

# Get specific resource status
argocd app resources <app-name> --kind Deployment

# View resource diff
argocd app diff <app-name>

# View live manifest
argocd app manifests <app-name> --source live

# View target manifest
argocd app manifests <app-name> --source git

# Compare live vs desired
argocd app diff <app-name> --local <path>
```

### Logs and Events

```bash
# Get ArgoCD controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100

# Get repo server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server --tail=100

# Get application events
kubectl get events -n argocd --field-selector involvedObject.name=<app-name>

# Watch events
kubectl get events -n argocd -w

# Get events for managed namespace
kubectl get events -n <app-namespace> --sort-by='.lastTimestamp'
```

## Health Status Investigation

### Degraded Health

**Symptoms**: Application shows `Degraded` health status

**Investigation Steps**:
```bash
# 1. Get health details
argocd app get <app-name> -o json | jq '.status.health'

# 2. Check resource health breakdown
argocd app get <app-name> -o json | jq '.status.resources[] | select(.health.status != "Healthy")'

# 3. Get specific unhealthy resource
kubectl describe <kind> <name> -n <namespace>

# 4. Check pod status if deployment
kubectl get pods -n <namespace> -l <app-label>
kubectl describe pod <pod-name> -n <namespace>

# 5. Check logs
kubectl logs <pod-name> -n <namespace> --previous
```

**Common Causes**:
- Pod CrashLoopBackOff
- Failed readiness/liveness probes
- ImagePullBackOff
- Resource constraints (OOM, CPU throttling)
- Configuration errors

### Missing Health

**Symptoms**: Application shows `Missing` health status

**Investigation Steps**:
```bash
# 1. Check if resources exist
argocd app resources <app-name>

# 2. Compare desired vs live
argocd app diff <app-name>

# 3. Check for pruning issues
argocd app get <app-name> -o json | jq '.spec.syncPolicy'

# 4. Verify namespace exists
kubectl get namespace <app-namespace>
```

**Common Causes**:
- Resources deleted externally
- Namespace deleted
- Prune disabled but resources removed from Git
- RBAC preventing resource creation

### Unknown Health

**Symptoms**: Application shows `Unknown` health status

**Investigation Steps**:
```bash
# 1. Check controller connectivity
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller | grep -i error

# 2. Verify cluster connection
argocd cluster list

# 3. Check resource health lua script
argocd app get <app-name> -o json | jq '.status.resources[] | select(.health.status == "Unknown")'
```

**Common Causes**:
- Controller can't reach cluster
- Custom resource without health check
- Timeout fetching resource state

## Sync Failure Investigation

### OutOfSync Status

**Symptoms**: Application shows `OutOfSync` but won't sync

**Investigation Steps**:
```bash
# 1. View diff to understand changes
argocd app diff <app-name>

# 2. Check sync policy
argocd app get <app-name> -o json | jq '.spec.syncPolicy'

# 3. Check for sync windows
argocd app get <app-name> -o json | jq '.spec.syncWindows'

# 4. Check operation state
argocd app get <app-name> -o json | jq '.status.operationState'

# 5. Try manual sync
argocd app sync <app-name> --dry-run
```

**Common Causes**:
- Sync window blocking
- Hook failure preventing completion
- Resource conflict
- Manual changes to cluster

### Sync Error

**Symptoms**: Sync operation fails with error

**Investigation Steps**:
```bash
# 1. Get operation details
argocd app get <app-name> -o json | jq '.status.operationState'

# 2. Check sync result
argocd app get <app-name> -o json | jq '.status.operationState.syncResult'

# 3. Get specific resource errors
argocd app get <app-name> -o json | jq '.status.operationState.syncResult.resources[] | select(.status != "Synced")'

# 4. Check controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller | grep <app-name>
```

**Common Causes**:
- Validation errors (invalid manifests)
- RBAC insufficient permissions
- Resource conflicts (already exists)
- Hook failures
- Namespace not found

### Stuck Syncing

**Symptoms**: Application stuck in `Syncing` state

**Investigation Steps**:
```bash
# 1. Check operation phase
argocd app get <app-name> -o json | jq '.status.operationState.phase'

# 2. Look for blocking resources
argocd app get <app-name> -o json | jq '.status.operationState.syncResult.resources[] | select(.status == "SyncFailed" or .status == "Syncing")'

# 3. Check for hooks
argocd app get <app-name> -o json | jq '.status.operationState.syncResult.resources[] | select(.hook)'

# 4. Check hook job status
kubectl get jobs -n <namespace> -l argocd.argoproj.io/hook

# 5. Terminate stuck operation
argocd app terminate-op <app-name>
```

**Common Causes**:
- Hook job not completing
- Slow resource creation
- Waiting for resource dependencies
- Controller overloaded

## Event Pattern Analysis

### CrashLoopBackOff Pattern

```bash
# Find pods in CrashLoopBackOff
kubectl get pods -n <namespace> --field-selector=status.phase=Failed
kubectl get pods -n <namespace> | grep CrashLoopBackOff

# Get container logs
kubectl logs <pod-name> -n <namespace> --previous

# Check events
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 Events

# Common causes:
# - Application startup errors
# - Missing dependencies
# - Configuration errors
# - Resource exhaustion
```

### ImagePullBackOff Pattern

```bash
# Find pods with image issues
kubectl get pods -n <namespace> | grep ImagePull

# Check image details
kubectl describe pod <pod-name> -n <namespace> | grep -A 5 "Container ID"

# Verify image exists
# For private registries, check secrets:
kubectl get secrets -n <namespace> | grep docker
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d

# Common causes:
# - Image doesn't exist
# - Wrong tag
# - Registry authentication
# - Registry unreachable
```

### OOMKilled Pattern

```bash
# Find OOMKilled pods
kubectl get pods -n <namespace> -o json | jq '.items[] | select(.status.containerStatuses[]?.lastState.terminated.reason == "OOMKilled") | .metadata.name'

# Check resource limits
kubectl get pod <pod-name> -n <namespace> -o json | jq '.spec.containers[].resources'

# Check node memory
kubectl top nodes
kubectl describe node <node-name> | grep -A 5 "Allocated resources"

# Common causes:
# - Memory limit too low
# - Memory leak in application
# - Large data processing
```

## Root Cause Analysis Patterns

### Configuration Issues

```bash
# Check configmap/secret references
kubectl get pod <pod-name> -n <namespace> -o json | jq '.spec.containers[].env[] | select(.valueFrom)'

# Verify configmap exists
kubectl get configmap -n <namespace>

# Check secret exists
kubectl get secrets -n <namespace>

# Compare config versions
argocd app diff <app-name> --local <path>
```

### Resource Constraint Issues

```bash
# Check pod resource usage
kubectl top pod -n <namespace>

# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check pending pods
kubectl get pods -n <namespace> --field-selector=status.phase=Pending

# Check for resource quotas
kubectl get resourcequota -n <namespace>
kubectl describe resourcequota -n <namespace>
```

### Network Issues

```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Test DNS resolution
kubectl run test --rm -i --restart=Never --image=busybox -- nslookup <service-name>

# Check network policies
kubectl get networkpolicies -n <namespace>

# Test connectivity
kubectl run test --rm -i --restart=Never --image=busybox -- wget -O- http://<service-name>:<port>
```

### RBAC Issues

```bash
# Check ArgoCD service account permissions
kubectl auth can-i --as=system:serviceaccount:argocd:argocd-application-controller create deployments -n <namespace>

# List role bindings
kubectl get rolebindings -n <namespace>
kubectl get clusterrolebindings | grep argocd

# Describe role
kubectl describe clusterrole argocd-application-controller
```

## Issue Priority Framework

### Critical (Immediate Action)

**Criteria**:
- Production service down
- Data loss risk
- Security vulnerability exposed
- Cascading failures

**Examples**:
- All pods in CrashLoopBackOff
- Database connection failures
- Certificate expired
- Secret exposure

**Actions**:
- Immediate escalation
- Rollback if possible
- Emergency fix deployment

### High (Urgent)

**Criteria**:
- Service degradation
- Partial outage
- Approaching limits
- Failed deployments blocking releases

**Examples**:
- Some pods unhealthy
- Increased error rates
- Memory approaching limits
- Sync failures on main branch

**Actions**:
- Investigate within 1 hour
- Prepare rollback
- Scale resources if needed

### Medium (Soon)

**Criteria**:
- Non-production issues
- Performance degradation
- Configuration drift
- Warnings accumulating

**Examples**:
- Staging environment issues
- Slow responses
- OutOfSync in dev
- Resource warnings

**Actions**:
- Investigate within 24 hours
- Plan fix in next sprint
- Monitor for escalation

### Low (Backlog)

**Criteria**:
- Informational
- Cosmetic issues
- Tech debt
- Optimization opportunities

**Examples**:
- Resource requests not set
- Deprecated API versions
- Missing labels
- Documentation gaps

**Actions**:
- Add to backlog
- Address when convenient
- Batch with related work

## GitHub Issue Templates

### Sync Failure Issue

```markdown
## ArgoCD Sync Failure

**Application**: `{app_name}`
**Cluster**: `{cluster}`
**Namespace**: `{namespace}`

### Error Details

```
{error_message}
```

### Affected Resources

{resource_list}

### Investigation

**Sync History**:
{sync_history}

**Diff Summary**:
{diff_summary}

### Root Cause

{root_cause_analysis}

### Recommended Fix

{fix_steps}

### Rollback Available

- [ ] Previous version: {revision}
```

### Health Degradation Issue

```markdown
## ArgoCD Health Degradation

**Application**: `{app_name}`
**Health Status**: `{health_status}`
**Detected**: `{timestamp}`

### Unhealthy Resources

{unhealthy_resources}

### Events

```
{kubernetes_events}
```

### Container Logs

```
{container_logs}
```

### Root Cause Analysis

{analysis}

### Impact

{impact_description}

### Recommended Actions

{action_items}
```

## Integration with Other Skills

This skill complements:
- **kubernetes-operations** - General K8s debugging
- **helm-debugging** - Helm-specific issues
- **github-actions-inspection** - CI/CD pipeline debugging
- **container-development** - Container troubleshooting

## Best Practices

**Investigation Workflow**:
1. Check application status and health
2. Review recent events and logs
3. Compare desired vs live state
4. Trace to specific resources
5. Analyze root cause
6. Determine if transient or persistent
7. Prioritize based on impact
8. Document findings

**Monitoring**:
- Set up alerts for Degraded/OutOfSync
- Monitor sync duration trends
- Track application deployment frequency
- Alert on repeated failures

**Prevention**:
- Use sync windows for production
- Implement proper health checks
- Set resource limits appropriately
- Use pre-sync hooks for validation
- Regular review of application configs

## Quick Reference

### Health Status Values
- `Healthy` - All resources healthy
- `Progressing` - Resources updating
- `Degraded` - Some resources unhealthy
- `Suspended` - Workload suspended
- `Missing` - Resources not found
- `Unknown` - Can't determine health

### Sync Status Values
- `Synced` - Live matches target
- `OutOfSync` - Differences detected
- `Unknown` - Can't determine sync

### Operation Phases
- `Running` - Sync in progress
- `Terminating` - Being cancelled
- `Error` - Operation failed
- `Failed` - Sync failed
- `Succeeded` - Sync completed

### Useful jq Filters

```bash
# Get all unhealthy apps
argocd app list -o json | jq '[.[] | select(.status.health.status != "Healthy")] | length'

# Get sync errors
argocd app get <app> -o json | jq '.status.operationState.syncResult.resources[] | select(.message) | {kind, name, message}'

# Get resource conditions
argocd app get <app> -o json | jq '.status.conditions'

# Get hook status
argocd app get <app> -o json | jq '.status.operationState.syncResult.resources[] | select(.hook) | {name, status, message}'
```
