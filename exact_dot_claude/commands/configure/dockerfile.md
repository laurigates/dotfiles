---
description: Check and configure Dockerfile for FVH standards
allowed-tools: Glob, Grep, Read, Write, Edit, AskUserQuestion, TodoWrite
argument-hint: "[--check-only] [--fix] [--type <frontend|python>]"
---

# /configure:dockerfile

Check and configure Dockerfile against FVH (Forum Virium Helsinki) standards.

## Context

This command validates Dockerfile configuration for Node.js frontend and Python service projects.

**Skills referenced**: `container-development`

## Workflow

### Phase 1: Detection

1. Find Dockerfile(s) in project root
2. Detect project type from context (package.json, pyproject.toml)
3. Parse Dockerfile to analyze configuration

### Phase 2: Compliance Analysis

**Frontend (Node.js) Standards:**

| Check | Standard | Severity |
|-------|----------|----------|
| Build base | `node:22-alpine` (LTS) | WARN if other |
| Runtime base | `nginx:1.27-alpine` | WARN if other |
| Multi-stage | Required | FAIL if missing |
| HEALTHCHECK | Required | FAIL if missing |
| Build caching | `--mount=type=cache` recommended | INFO |
| EXPOSE | Should match nginx port | INFO |

**Python Service Standards:**

| Check | Standard | Severity |
|-------|----------|----------|
| Base image | `python:3.12-slim` | WARN if other |
| Multi-stage | Required for production | FAIL if missing |
| HEALTHCHECK | Required | FAIL if missing |
| Non-root user | Recommended | WARN if missing |
| Poetry/uv | Modern package manager | INFO |

### Phase 3: Report Generation

```
FVH Dockerfile Compliance Report
================================
Project Type: frontend (detected)
Dockerfile: ./Dockerfile (found)

Configuration Checks:
  Build base      node:24-alpine    ⚠️ WARN (standard: node:22-alpine)
  Runtime base    nginx:1.27-alpine ✅ PASS
  Multi-stage     2 stages          ✅ PASS
  HEALTHCHECK     Present           ✅ PASS
  Build caching   npm cache         ✅ PASS
  EXPOSE          80                ✅ PASS

Recommendations:
  - Consider using Node 22 LTS for stability
```

### Phase 4: Configuration (If Requested)

If `--fix` flag or user confirms:

1. **Missing Dockerfile**: Create from FVH template
2. **Missing HEALTHCHECK**: Add standard healthcheck
3. **Missing multi-stage**: Suggest restructure (manual fix needed)
4. **Outdated base images**: Update FROM lines

**HEALTHCHECK Template (nginx):**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1
```

### Phase 5: Standards Tracking

Update `.fvh-standards.yaml`:

```yaml
components:
  dockerfile: "2025.1"
```

## FVH Standard Templates

### Frontend (Node/Vite/nginx)

```dockerfile
FROM node:22-alpine AS build

ARG SENTRY_AUTH_TOKEN
ARG VITE_SENTRY_DSN

WORKDIR /app

COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm npm ci

COPY . .
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/app/node_modules/.vite \
    npm run build

FROM nginx:1.27-alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx/default.conf.template /etc/nginx/templates/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1
```

### Python Service

```dockerfile
FROM python:3.12-slim AS builder

WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev

FROM python:3.12-slim

RUN useradd --create-home appuser
USER appuser
WORKDIR /app

COPY --from=builder /app/.venv /app/.venv
COPY --chown=appuser:appuser . .

ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Flags

| Flag | Description |
|------|-------------|
| `--check-only` | Report status without offering fixes |
| `--fix` | Apply fixes automatically |
| `--type <type>` | Override project type (frontend, python) |

## Notes

- Node 22 is current LTS (recommended over 24)
- nginx:1.27-alpine preferred over debian variant
- HEALTHCHECK is critical for Kubernetes liveness probes
- Build caching significantly improves CI/CD speed

## See Also

- `/configure:skaffold` - Kubernetes development configuration
- `/configure:all` - Run all FVH compliance checks
- `container-development` skill - Container best practices
