# ArgoCD Investigation Reference

Comprehensive reference for ArgoCD troubleshooting, monitoring patterns, and integration with automation tools.

## Table of Contents

1. [ArgoCD Architecture](#argocd-architecture)
2. [Monitoring Best Practices](#monitoring-best-practices)
3. [Common Issues Playbook](#common-issues-playbook)
4. [Automation Integration](#automation-integration)
5. [Alert Thresholds](#alert-thresholds)
6. [Recovery Procedures](#recovery-procedures)

## ArgoCD Architecture

### Components

```
┌─────────────────────────────────────────────────────┐
│                   ArgoCD Server                      │
│  - API Server                                        │
│  - UI                                                │
│  - Authentication/Authorization                      │
└─────────────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
┌────────▼───────┐ ┌────▼──────┐ ┌─────▼──────┐
│ Application    │ │   Repo    │ │  Dex       │
│ Controller     │ │   Server  │ │  (SSO)     │
└────────────────┘ └───────────┘ └────────────┘
         │               │
         │               │
    ┌────▼───────────────▼─────┐
    │  Kubernetes Cluster(s)    │
    │  - Target applications    │
    └───────────────────────────┘
```

### Key Concepts

**Application**: A deployment unit tracking a Git repository path to a cluster namespace

**Project**: Logical grouping of applications with shared RBAC and source/destination policies

**Sync**: The operation that applies Git changes to the cluster

**Health**: Assessment of actual resource state (Healthy, Progressing, Degraded, etc.)

**Sync Status**: Comparison between Git (desired) and cluster (live) state

## Monitoring Best Practices

### Health Metrics to Track

```yaml
# Critical metrics
- app.health.status          # Overall health
- app.sync.status            # Sync state
- app.operationState.phase   # Operation status
- controller.app.reconcile   # Reconciliation rate
- server.api.request.count   # API load

# Performance metrics
- app.sync.duration          # Sync time
- kubectl.exec.duration      # K8s API latency
- git.fetch.duration         # Git repo fetch time

# Error metrics
- app.sync.error.count       # Sync failures
- controller.webhook.error   # Webhook failures
- repo.server.error          # Repo access errors
```

### Alert Rules

```yaml
# Critical alerts
- Alert: ApplicationDegraded
  Expression: app_health_status == "Degraded" for 5m
  Severity: critical

- Alert: SyncFailed
  Expression: app_sync_status_code == "SyncFailed" for 5m
  Severity: high

- Alert: ApplicationMissing
  Expression: app_health_status == "Missing" for 2m
  Severity: critical

# Warning alerts
- Alert: ApplicationOutOfSync
  Expression: app_sync_status == "OutOfSync" for 15m
  Severity: warning

- Alert: SlowSyncDuration
  Expression: app_sync_duration > 300 for 3m
  Severity: warning

- Alert: HighReconciliationErrors
  Expression: rate(controller_app_reconcile_error[5m]) > 0.1
  Severity: warning
```

### Monitoring Queries

**Prometheus queries**:
```promql
# Applications by health status
count by (health_status) (argocd_app_info)

# Average sync duration per app
avg(argocd_app_sync_total) by (name)

# Sync failure rate
rate(argocd_app_sync_total{phase="Error"}[5m])

# OutOfSync applications
count(argocd_app_info{sync_status="OutOfSync"})
```

## Common Issues Playbook

### Issue: Application Stuck in Progressing

**Symptoms**:
- Health status: `Progressing` for > 10 minutes
- Resources show as created but not ready

**Investigation**:
```bash
# Check what's progressing
argocd app get <app> -o json | jq '.status.resources[] | select(.health.status == "Progressing")'

# Check pod status
kubectl get pods -n <namespace> -o wide

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | tail -20
```

**Common Causes**:
1. **Container startup time**: Large image, slow initialization
2. **Readiness probe failure**: Probe misconfigured or app not ready
3. **Resource constraints**: Insufficient CPU/memory
4. **Image pull issues**: Slow registry, large layers

**Resolution**:
```bash
# If readiness probe too strict
kubectl edit deployment <name> -n <namespace>
# Adjust initialDelaySeconds, periodSeconds

# If resource constraints
kubectl describe node <node-name> | grep -A 5 "Allocated resources"
# Scale up node pool or reduce requests

# If image pull slow
# Use smaller base images, implement layer caching
```

### Issue: Sync Fails with "Resource Already Exists"

**Symptoms**:
- Sync error: "resource already exists"
- Resource shows in cluster but not in ArgoCD

**Investigation**:
```bash
# Check resource ownership
kubectl get <resource> <name> -n <namespace> -o yaml | grep -A 5 "ownerReferences\|annotations"

# Check if resource is tracked
argocd app resources <app> | grep <resource-name>
```

**Common Causes**:
1. **Resource created manually**: Not tracked by ArgoCD
2. **Previous sync incomplete**: Orphaned resource
3. **Annotation missing**: `argocd.argoproj.io/tracking-id` not set

**Resolution**:
```bash
# Option 1: Delete and let ArgoCD recreate
kubectl delete <resource> <name> -n <namespace>
argocd app sync <app>

# Option 2: Add ArgoCD annotation
kubectl annotate <resource> <name> -n <namespace> \
  argocd.argoproj.io/tracking-id=<app-namespace>:<app-name>:<group>/<kind>:<namespace>/<name>

# Option 3: Enable replace
argocd app sync <app> --replace
```

### Issue: OutOfSync Despite No Changes

**Symptoms**:
- Status: `OutOfSync`
- Git diff shows no changes
- Live resource differs unexpectedly

**Investigation**:
```bash
# View exact diff
argocd app diff <app>

# Check for drift annotations
argocd app get <app> -o json | jq '.status.resources[] | select(.status == "OutOfSync")'

# Check if controllers are modifying resources
kubectl get events -n <namespace> | grep <resource-name>
```

**Common Causes**:
1. **Controller modifying resource**: HPA, VPA, admission webhooks
2. **Status field changes**: Not ignored by ArgoCD
3. **Default values**: K8s API server adding defaults
4. **Time-based fields**: Timestamps causing diff

**Resolution**:
```bash
# Ignore differences in annotation
argocd app patch <app> --type json \
  -p='[{"op": "add", "path": "/spec/ignoreDifferences", "value": [{"group": "apps", "kind": "Deployment", "jsonPointers": ["/spec/replicas"]}]}]'

# Or in Application manifest:
spec:
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas  # Ignore HPA changes

# Respect ignore difference
argocd app sync <app> --force
```

### Issue: Sync Hooks Failing

**Symptoms**:
- Sync stuck in `Running` phase
- Hook jobs show `Failed` status

**Investigation**:
```bash
# List hooks
argocd app get <app> -o json | jq '.status.operationState.syncResult.resources[] | select(.hookPhase)'

# Check hook jobs
kubectl get jobs -n <namespace> -l argocd.argoproj.io/hook

# Get job logs
kubectl logs -n <namespace> job/<hook-job-name>

# Check hook job status
kubectl describe job/<hook-job-name> -n <namespace>
```

**Common Causes**:
1. **Hook script failure**: Script exits non-zero
2. **Hook timeout**: Job exceeds timeout
3. **Resource constraints**: Job can't schedule
4. **Incorrect permissions**: ServiceAccount lacks RBAC

**Resolution**:
```bash
# Delete failed hook job manually
kubectl delete job/<hook-job-name> -n <namespace>

# Skip hook and retry
argocd app patch <app> --type json \
  -p='[{"op": "add", "path": "/operation/sync/syncOptions", "value": ["SkipHooks=true"]}]'

# Or use sync option in manifest:
metadata:
  annotations:
    argocd.argoproj.io/hook-delete-policy: HookSucceeded,HookFailed
```

### Issue: Prune Not Working

**Symptoms**:
- Resources remain in cluster after removal from Git
- Prune policy enabled but not executing

**Investigation**:
```bash
# Check prune policy
argocd app get <app> -o json | jq '.spec.syncPolicy.automated.prune'

# List resources that should be pruned
argocd app resources <app> --orphaned

# Check for finalizers
kubectl get <resource> <name> -n <namespace> -o yaml | grep finalizers -A 5
```

**Common Causes**:
1. **Automated prune disabled**: Manual sync required
2. **Finalizers blocking deletion**: Resource stuck terminating
3. **Ownership lost**: Resource no longer tracked
4. **Protection annotation**: Deletion prevented

**Resolution**:
```bash
# Manual prune
argocd app sync <app> --prune

# Remove finalizer if stuck
kubectl patch <resource> <name> -n <namespace> -p '{"metadata":{"finalizers":[]}}' --type=merge

# Force deletion
kubectl delete <resource> <name> -n <namespace> --force --grace-period=0
```

## Automation Integration

### ArgoCD Notifications

```yaml
# argocd-notifications-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  # Trigger templates
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]

  trigger.on-health-degraded: |
    - when: app.status.health.status == 'Degraded'
      send: [app-health-degraded]

  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      send: [app-sync-failed]

  # Message templates
  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} deployed successfully.
      Revision: {{.app.status.sync.revision}}

  template.app-health-degraded: |
    message: |
      Application {{.app.metadata.name}} health degraded.
      Current status: {{.app.status.health.status}}

  template.app-sync-failed: |
    message: |
      Application {{.app.metadata.name}} sync failed.
      Message: {{.app.status.operationState.message}}
```

### Webhook Integration

```bash
# Configure GitHub webhook for notifications
apiVersion: v1
kind: Secret
metadata:
  name: argocd-notifications-secret
  namespace: argocd
stringData:
  github-token: <github-pat>
---
# In argocd-notifications-cm
service.webhook.github: |
  url: https://api.github.com
  headers:
  - name: Authorization
    value: token $github-token
```

### Prometheus Metrics

```yaml
# ServiceMonitor for ArgoCD metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
    interval: 30s
```

### Agent SDK Integration Points

```python
# Example: Fetch metrics for analysis
async def get_argocd_metrics():
    """Query Prometheus for ArgoCD metrics"""
    queries = {
        "degraded_apps": 'count(argocd_app_info{health_status="Degraded"})',
        "out_of_sync": 'count(argocd_app_info{sync_status="OutOfSync"})',
        "sync_failures": 'rate(argocd_app_sync_total{phase="Error"}[5m])',
    }

    async for msg in query(
        prompt=f"Analyze ArgoCD metrics: {queries}",
        options=ClaudeAgentOptions(
            allowed_tools=["Bash", "mcp__prometheus__query"],
            mcp_servers={"prometheus": {...}}
        )
    ):
        # Process analysis
        pass

# Example: Auto-remediation
async def auto_remediate_issue(app_name: str, issue_type: str):
    """Attempt automated remediation for known issues"""
    remediation_prompts = {
        "image_pull": f"Debug ImagePullBackOff for {app_name}. Check registry, credentials, image tag.",
        "oom_killed": f"Analyze OOMKilled pods in {app_name}. Recommend memory limit increases.",
        "sync_failed": f"Investigate sync failure for {app_name}. Check hooks, RBAC, resource conflicts.",
    }

    async for msg in query(
        prompt=remediation_prompts.get(issue_type, f"Investigate {issue_type} for {app_name}"),
        options=ClaudeAgentOptions(
            allowed_tools=["Bash", "Read", "Edit"],
            system_prompt="You are an SRE with ArgoCD expertise. Provide remediation steps."
        )
    ):
        # Execute remediation
        pass
```

## Alert Thresholds

### Severity Levels

| Severity | Definition | Response Time | Examples |
|----------|------------|---------------|----------|
| **Critical** | Production impact, data loss risk | Immediate | All pods down, database failure, secrets exposed |
| **High** | Service degradation, partial outage | < 1 hour | Multiple pods unhealthy, sync failures on main, certificate expiring |
| **Medium** | Non-prod issues, performance degradation | < 24 hours | Staging issues, slow responses, dev OutOfSync |
| **Low** | Warnings, tech debt | Backlog | Missing labels, deprecated APIs, documentation gaps |

### Recommended Thresholds

```yaml
# Application health
critical_health:
  - health_status: "Degraded"
    duration: "5m"
    affected_resources: "> 50%"

high_health:
  - health_status: "Degraded"
    duration: "10m"
    affected_resources: "< 50%"

# Sync status
critical_sync:
  - sync_status: "OutOfSync"
    auto_sync: true
    duration: "10m"

high_sync:
  - operation_phase: "Failed"
    retry_count: "> 3"

# Performance
warning_performance:
  - sync_duration: "> 300s"
  - reconcile_duration: "> 60s"
  - api_latency: "> 1s"

# Resource issues
critical_resources:
  - pods_ready: "0/n"
  - crash_loop_backoff: true
  - oom_killed: true

high_resources:
  - pods_ready: "< 50%"
  - image_pull_backoff: true
  - pending_pods: "> 5m"
```

## Recovery Procedures

### Rollback Application

```bash
# View history
argocd app history <app>

# Rollback to specific revision
argocd app rollback <app> <revision>

# Rollback to previous
argocd app rollback <app>

# Verify rollback
argocd app get <app>
kubectl get pods -n <namespace> -o wide
```

### Recover From Failed Sync

```bash
# 1. Check current state
argocd app get <app> -o json | jq '.status.operationState'

# 2. Terminate stuck operation
argocd app terminate-op <app>

# 3. Identify cause
argocd app diff <app>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# 4. Fix and retry
# Fix issue in Git or cluster
argocd app sync <app> --force --prune

# 5. If still fails, manual intervention
kubectl apply -f <manifest>
argocd app sync <app> --local <path>
```

### Restore ArgoCD State

```bash
# Backup ArgoCD applications
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml

# Backup ArgoCD config
kubectl get configmap -n argocd -o yaml > argocd-config-backup.yaml
kubectl get secret -n argocd -o yaml > argocd-secrets-backup.yaml

# Restore applications
kubectl apply -f argocd-apps-backup.yaml

# Recreate application from scratch
argocd app create <app> \
  --repo <repo-url> \
  --path <path> \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace <namespace>
```

### Emergency Procedures

**ArgoCD controller not reconciling**:
```bash
# Restart controller
kubectl rollout restart deployment/argocd-application-controller -n argocd

# Check logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100

# Force reconciliation
argocd app get <app> --refresh
```

**Cluster unreachable**:
```bash
# Check cluster connection
argocd cluster list

# Re-add cluster
argocd cluster add <context-name>

# Verify connectivity
kubectl --context <context-name> get nodes
```

**Git repository unreachable**:
```bash
# Check repo connection
argocd repo list

# Update credentials
argocd repo add <repo-url> --username <user> --password <pass>

# Or use SSH key
argocd repo add <repo-url> --ssh-private-key-path ~/.ssh/id_rsa
```

## References

- **Official Docs**: https://argo-cd.readthedocs.io/
- **Troubleshooting Guide**: https://argo-cd.readthedocs.io/en/stable/user-guide/troubleshooting/
- **Best Practices**: https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/
- **Operator Manual**: https://argo-cd.readthedocs.io/en/stable/operator-manual/
- **Notifications**: https://argocd-notifications.readthedocs.io/

## Related Skills

- `kubernetes-operations` - K8s debugging and operations
- `helm-debugging` - Helm chart troubleshooting
- `github-actions-inspection` - CI/CD pipeline debugging
- `git-operations` - Git repository management
