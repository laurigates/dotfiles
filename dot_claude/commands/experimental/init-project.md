i want to make sure pre-commit hooks are used, release-please as github workflow is configured, dockerfile exists, makefile for lint, format, test, built commands with colored output

.github/workflows/release-please.yml

```yaml
on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

name: release-please

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
          release-type: python
```

.claude/settings.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "make lint && make format && make test"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit|TodoWrite",
        "hooks": [
          {
            "type": "command",
            "command": "tdd-guard"
          }
        ]
      }
    ]
  }
}
```

.pre-commit-config

```yaml
default_install_hook_types:
  - pre-commit
  - commit-msg
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0 # Use a recent version
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: check-symlinks
      - id: check-toml
      - id: check-added-large-files
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.2.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
        args: []
  - repo: https://github.com/astral-sh/ruff-pre-commit
    # Ruff version.
    rev: v0.12.2
    hooks:
      # Run the linter.
      - id: ruff-check
        args: [--fix]
      # Run the formatter.
      - id: ruff-format
  - repo: https://github.com/rhysd/actionlint
    rev: v1.7.7
    hooks:
      - id: actionlint
  - repo: local
    hooks:
      - id: trufflehog
        name: TruffleHog
        description: Detect secrets in your data.
        entry: bash -c 'trufflehog git file://. --since-commit HEAD --results=verified,unknown --fail --no-update'
        language: system
        stages: ["pre-commit", "pre-push"]
      - id: bandit
        name: bandit
        description: "Run bandit to find common security issues in Python code."
        entry: uv run bandit
        args: [-r, src/, -c, pyproject.toml]
        language: python
        types: [python]
        stages: [pre-commit]
```
