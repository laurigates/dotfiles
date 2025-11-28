---
name: fvh-skaffold
description: |
  FVH (Forum Virium Helsinki) Skaffold configuration standards for local Kubernetes
  development. Use when configuring Skaffold, setting up local K8s development, or
  when the user mentions FVH Skaffold, local development, or Kubernetes profiles.
---

# FVH Skaffold Standards

## Version: 2025.1

FVH standard Skaffold configuration for local Kubernetes development workflows.

## Standard Configuration

### API Version

```yaml
apiVersion: skaffold/v4beta11
kind: Config
```

Always use the latest stable API version. Currently: `skaffold/v4beta11`

### Build Configuration

```yaml
build:
  local:
    push: false           # Never push to registry for local dev
    useDockerCLI: true    # Use Docker CLI (better caching)
    useBuildkit: true     # Enable BuildKit for performance
    concurrency: 0        # Unlimited parallel builds
  artifacts:
    - image: app-name
      context: .
      docker:
        dockerfile: Dockerfile
```

### Port Forwarding (Security)

**IMPORTANT**: Always bind to localhost only:

```yaml
portForward:
  - resourceType: service
    resourceName: app-name
    port: 80
    localPort: 8080
    address: 127.0.0.1    # REQUIRED: Bind to localhost only
```

Never use `0.0.0.0` or omit the address field.

### Deploy Configuration

```yaml
deploy:
  kubectl: {}  # or helm: {}
  statusCheck: true
  statusCheckDeadlineSeconds: 180
  tolerateFailuresUntilDeadline: true
```

## Standard Profiles

### Profile: `services-only`

Backend services only (database, APIs) - use with local frontend dev:

```yaml
profiles:
  - name: services-only
    build:
      artifacts: []  # Don't build frontend
    manifests:
      rawYaml:
        - k8s/namespace.yaml
        - k8s/database/*.yaml
        - k8s/api/*.yaml
    portForward:
      - resourceType: service
        resourceName: postgresql
        port: 5432
        localPort: 5432
        address: 127.0.0.1
```

**Use case**: Run `skaffold dev -p services-only` + `npm run dev` for hot-reload frontend

### Profile: `e2e` or `e2e-with-prod-data`

Full stack for end-to-end testing:

```yaml
profiles:
  - name: e2e
    manifests:
      rawYaml:
        - k8s/*.yaml  # All manifests
```

### Profile: `migration-test`

Database migration testing:

```yaml
profiles:
  - name: migration-test
    manifests:
      rawYaml:
        - k8s/database/*.yaml
    test:
      - image: migration-tester
        custom:
          - command: "run-migrations.sh"
```

## Compliance Requirements

### Cluster Context (CRITICAL)

**Always specify `kubeContext: orbstack`** in deploy configuration. This is the FVH standard local development context.

```yaml
deploy:
  kubeContext: orbstack
  kubectl: {}
```

When using Skaffold commands, always include `--kube-context=orbstack`:

```bash
skaffold dev --kube-context=orbstack
skaffold run --kube-context=orbstack
skaffold delete --kube-context=orbstack
```

Only use a different context if explicitly requested by the user.

### Required Elements

| Element | Requirement |
|---------|-------------|
| API version | `skaffold/v4beta11` |
| deploy.kubeContext | `orbstack` (default) |
| local.push | `false` |
| portForward.address | `127.0.0.1` |
| statusCheck | `true` recommended |

### Recommended Profiles

Depending on project type:

| Profile | Purpose | Required |
|---------|---------|----------|
| `services-only` | Backend dev + local frontend | Recommended |
| `e2e` | Full stack testing | Optional |
| `migration-test` | DB migration testing | Optional |

## Project Type Variations

### Frontend with Backend Services

```yaml
# Default: Full stack
manifests:
  rawYaml:
    - k8s/namespace.yaml
    - k8s/frontend/*.yaml
    - k8s/backend/*.yaml
    - k8s/database/*.yaml

profiles:
  - name: services-only
    build:
      artifacts: []
    manifests:
      rawYaml:
        - k8s/namespace.yaml
        - k8s/backend/*.yaml
        - k8s/database/*.yaml
```

### API Service Only

```yaml
# Simpler configuration
manifests:
  rawYaml:
    - k8s/*.yaml

# No profiles needed for simple services
```

### Infrastructure Testing

Skaffold may not be applicable for pure infrastructure repos. Use Terraform/Helm directly.

## Build Hooks

Pre-build hooks for validation:

```yaml
build:
  artifacts:
    - image: app
      hooks:
        before:
          - command: ['npm', 'run', 'lint']
            os: [darwin, linux]
```

## Status Levels

| Status | Condition |
|--------|-----------|
| PASS | Compliant configuration |
| WARN | Present but missing recommended elements |
| FAIL | Security issue (e.g., portForward without localhost) |
| SKIP | Not applicable (e.g., infrastructure repo) |

## Troubleshooting

### Pods Not Starting

- Check `statusCheckDeadlineSeconds` (increase if needed)
- Enable `tolerateFailuresUntilDeadline: true`
- Review pod logs: `kubectl logs -f <pod>`

### Port Forwarding Issues

- Ensure port is not already in use
- Check service name matches deployment
- Verify `address: 127.0.0.1` is set

### Build Caching

- Enable BuildKit: `useBuildkit: true`
- Use Docker CLI: `useDockerCLI: true`
- Set `concurrency: 0` for parallel builds
