---
description: Check and configure Skaffold for FVH standards
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, TodoWrite
argument-hint: "[--check-only] [--fix]"
---

# /configure:skaffold

Check and configure Skaffold against FVH (Forum Virium Helsinki) standards.

## Context

This command validates Skaffold configuration for local Kubernetes development.

**Skills referenced**: `fvh-skaffold`, `container-development`

**Applicability**: Only for projects with Kubernetes deployment (k8s/, helm/ directories)

## Workflow

### Phase 1: Applicability Check

1. Check for `k8s/` or `helm/` directories
2. If not found: Report SKIP (Skaffold not applicable)
3. If found: Check for `skaffold.yaml`

### Phase 2: Configuration Detection

Parse `skaffold.yaml` for:
- API version
- Build configuration
- Deploy configuration
- Port forwarding
- Profiles

### Phase 3: Compliance Analysis

**Required Checks:**

| Check | Standard | Severity |
|-------|----------|----------|
| API version | `skaffold/v4beta11` | WARN if older |
| local.push | `false` | FAIL if true |
| portForward.address | `127.0.0.1` | FAIL if missing/0.0.0.0 |
| useBuildkit | `true` | WARN if false |

**Security-Critical:**
- Port forwarding MUST bind to localhost only (`127.0.0.1`)
- Never allow `0.0.0.0` or missing address

**Recommended:**
- `services-only` profile for frontend dev workflow
- `statusCheck: true` with reasonable deadline
- `tolerateFailuresUntilDeadline: true`

### Phase 4: Report Generation

```
FVH Skaffold Compliance Report
==============================
Project Type: frontend (detected)
Skaffold: ./skaffold.yaml (found)

Configuration Checks:
  API version     v4beta11          ✅ PASS
  local.push      false             ✅ PASS
  useBuildkit     true              ✅ PASS
  Port security   127.0.0.1         ✅ PASS
  statusCheck     true              ✅ PASS

Profiles Found:
  services-only   ✅ Present
  e2e-with-prod-data ✅ Present
  migration-test  ✅ Present

Overall: Fully compliant
```

### Phase 5: Configuration (If Requested)

If `--fix` flag or user confirms:

1. **Missing skaffold.yaml**: Create from FVH template
2. **Security issues**: Fix port forwarding addresses
3. **Missing profiles**: Add `services-only` profile template
4. **Outdated API**: Update apiVersion

### Phase 6: Standards Tracking

Update `.fvh-standards.yaml`:

```yaml
components:
  skaffold: "2025.1"
```

## FVH Standard Template

```yaml
apiVersion: skaffold/v4beta11
kind: Config
metadata:
  name: project-name

build:
  local:
    push: false
    useDockerCLI: true
    useBuildkit: true
    concurrency: 0
  artifacts:
    - image: app
      context: .
      docker:
        dockerfile: Dockerfile

manifests:
  rawYaml:
    - k8s/*.yaml

deploy:
  kubectl: {}
  statusCheck: true
  statusCheckDeadlineSeconds: 180
  tolerateFailuresUntilDeadline: true

portForward:
  - resourceType: service
    resourceName: app
    port: 80
    localPort: 8080
    address: 127.0.0.1  # REQUIRED: localhost only

profiles:
  - name: services-only
    build:
      artifacts: []
    manifests:
      rawYaml:
        - k8s/database/*.yaml
        - k8s/api/*.yaml
    portForward:
      - resourceType: service
        resourceName: postgresql
        port: 5432
        localPort: 5432
        address: 127.0.0.1
```

## Flags

| Flag | Description |
|------|-------------|
| `--check-only` | Report status without offering fixes |
| `--fix` | Apply fixes automatically |

## Security Note

Port forwarding without `address: 127.0.0.1` exposes services to the network.
This is a **FAIL** condition that should always be fixed.

## See Also

- `/configure:dockerfile` - Container configuration
- `/configure:all` - Run all FVH compliance checks
- `fvh-skaffold` skill - Skaffold patterns
