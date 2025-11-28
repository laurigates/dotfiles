---
name: fvh-pre-commit
description: |
  FVH (Forum Virium Helsinki) pre-commit hook standards and configuration. Use when
  configuring pre-commit hooks in FVH repositories, checking hook compliance, or when
  the user mentions FVH pre-commit, conventional commits, or hook configuration.
---

# FVH Pre-commit Standards

## Version: 2025.1

FVH standard pre-commit configuration for repository compliance.

## Standard Versions (2025.1)

| Hook | Version | Purpose |
|------|---------|---------|
| pre-commit-hooks | v5.0.0 | Core hooks (trailing-whitespace, check-yaml, etc.) |
| conventional-pre-commit | v4.3.0 | Conventional commit message validation |
| prettier | v4.0.0-alpha.8 | Code formatting (JS, TS, Vue, JSON, YAML, Markdown) |
| eslint (mirrors) | v9.17.0 | JavaScript/Vue linting |
| gruntwork pre-commit | v0.1.29 | helmlint, tflint (infrastructure only) |
| actionlint | v1.7.7 | GitHub Actions validation (infrastructure only) |
| helm-docs | v1.14.2 | Helm documentation (infrastructure only) |
| detect-secrets | v1.5.0 | Secret scanning (recommended) |

## Project Type Configurations

### Frontend App (Vue/React)

Required hooks for frontend applications:

```yaml
default_install_hook_types:
  - pre-commit
  - commit-msg

repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        exclude: ^(helm/templates/|skaffold/|k8s/).*\.ya?ml$
      - id: check-json
        exclude: tsconfig\.json$
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.3.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]

  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v4.0.0-alpha.8
    hooks:
      - id: prettier
        types_or: [javascript, jsx, ts, tsx, vue, json, yaml, markdown, css, scss]
        exclude: ^(helm/templates/|skaffold/|k8s/).*\.ya?ml$

  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v9.17.0
    hooks:
      - id: eslint
        files: \.(jsx?|tsx?|vue)$
        types: [file]
        additional_dependencies:
          - eslint
          - eslint-config-prettier
          - eslint-plugin-vue

  # Optional: If project has Helm charts
  - repo: https://github.com/gruntwork-io/pre-commit
    rev: v0.1.29
    hooks:
      - id: helmlint
        files: ^helm/
```

### Infrastructure Repository

Required hooks for infrastructure (Terraform, Helm, ArgoCD):

```yaml
default_install_hook_types:
  - pre-commit
  - commit-msg

repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        args: [--allow-multiple-documents]
        exclude: argocd/.*templates/|helm/[^/]+/templates/
      - id: check-json
      - id: check-merge-conflict
      - id: check-symlinks
      - id: check-toml
      - id: check-added-large-files

  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.3.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]

  - repo: https://github.com/gruntwork-io/pre-commit
    rev: v0.1.29
    hooks:
      - id: tflint
      - id: helmlint

  - repo: https://github.com/rhysd/actionlint
    rev: v1.7.7
    hooks:
      - id: actionlint

  - repo: https://github.com/norwoodj/helm-docs
    rev: v1.14.2
    hooks:
      - id: helm-docs
        args:
          - --chart-search-root=helm

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

### Python Service

Required hooks for Python projects:

```yaml
default_install_hook_types:
  - pre-commit
  - commit-msg

repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-toml
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.3.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.4
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.5.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
```

## Compliance Checking

### Required Base Hooks (All Projects)

Every FVH repository MUST have these hooks:

1. **pre-commit-hooks** (v5.0.0+)
   - `trailing-whitespace`
   - `end-of-file-fixer`
   - `check-yaml`
   - `check-json`
   - `check-merge-conflict`
   - `check-added-large-files`

2. **conventional-pre-commit** (v4.3.0+)
   - `conventional-pre-commit` in `commit-msg` stage

### Status Levels

| Status | Meaning |
|--------|---------|
| PASS | Hook present with compliant version |
| WARN | Hook present but version outdated |
| FAIL | Required hook missing |
| SKIP | Hook not applicable for project type |

### Version Comparison

When checking versions:
- Exact match or newer: PASS
- Older by patch version: WARN (functional but should update)
- Missing entirely: FAIL (must add)

## Exclusion Patterns

### Frontend Apps

Exclude Kubernetes/Helm templates from YAML/prettier checks:

```yaml
exclude: ^(helm/templates/|skaffold/|k8s/).*\.ya?ml$
```

### Infrastructure

Exclude ArgoCD and Helm templates:

```yaml
exclude: argocd/.*templates/|helm/[^/]+/templates/
```

### Python

No special exclusions needed for standard Python projects.

## Installation

After configuring `.pre-commit-config.yaml`:

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

Or simply:

```bash
pre-commit install --install-hooks
```

## Updating

To update all hooks to latest versions:

```bash
pre-commit autoupdate
```

Then verify versions match FVH standards.
