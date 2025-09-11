---
name: /init-project
description: Initializes a project with a standard dev environment, including pre-commit hooks, a release workflow, a Makefile, and a Dockerfile.
argument-hint: "python|node|go|generic"
allowed-tools: Bash(ls:*), Bash(pwd:*), Bash(pre-commit install:*), Write
---

You are about to initialize a new project structure. Your primary goal is to create a robust, modern development environment based on the user's specified project type.

**Argument Handling:**
The user may provide a project type as an argument (`$ARGUMENTS`).
- If `$ARGUMENTS` is `python`, `node`, `go`, or `generic`, use that as the project type.
- If `$ARGUMENTS` is empty or invalid, **default to `python`**.
- Announce which project type you are setting up.

**Your Tasks:**

1.  **Determine Project Type:** Evaluate `$ARGUMENTS` and set the project type.
2.  **Create Files:** Create the following files with the content provided in the templates below. Pay close attention to the `{{PROJECT_TYPE}}` placeholders and replace them correctly.
3.  **Finalization:** After creating all files, you must run the command to install the git hooks.
4.  **Inform the User:** Conclude by telling the user what has been done and what their next steps should be (e.g., "I have initialized the project. Please create a virtual environment, run 'make install-hooks', and set the `RELEASE_PLEASE_TOKEN` secret in your GitHub repository.").

---
### **File Templates**

#### **Makefile**
Create a file named `Makefile` with this content. This Makefile provides colored output and common development commands.

```makefile
# Makefile for {{PROJECT_TYPE}} project
# Provides common commands for development, testing, and building.

# Colors for console output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

.DEFAULT_GOAL := help

# ==============================================================================
# HELP
# ==============================================================================

help:
	@echo "$(BLUE)Project Commands:$(NC)"
	@echo "  $(GREEN)install-hooks$(NC)   Install git hooks using pre-commit."
	@echo "  $(GREEN)lint$(NC)            Run the linter to check for style issues."
	@echo "  $(GREEN)format$(NC)          Format the code automatically."
	@echo "  $(GREEN)test$(NC)            Run the test suite."
	@echo "  $(GREEN)build$(NC)           Build the Docker container for the project."
	@echo "  $(GREEN)clean$(NC)           Remove temporary files and build artifacts."

# ==============================================================================
# DEVELOPMENT
# ==============================================================================

install-hooks:
	@echo "$(BLUE)Installing pre-commit hooks...$(NC)"
	@pre-commit install --install-hooks --hook-type pre-commit --hook-type commit-msg

lint:
	@echo "$(BLUE)Running linter...$(NC)"
ifeq ({{PROJECT_TYPE}}, python)
	@uv run ruff check .
else ifeq ({{PROJECT_TYPE}}, node)
	@npm run lint
else
	@echo "$(YELLOW)No lint command configured for '{{PROJECT_TYPE}}'$(NC)"
endif

format:
	@echo "$(BLUE)Formatting code...$(NC)"
ifeq ({{PROJECT_TYPE}}, python)
	@uv run ruff format .
else ifeq ({{PROJECT_TYPE}}, node)
	@npm run format
else
	@echo "$(YELLOW)No format command configured for '{{PROJECT_TYPE}}'$(NC)"
endif

test:
	@echo "$(BLUE)Running tests...$(NC)"
ifeq ({{PROJECT_TYPE}}, python)
	@uv run pytest
else ifeq ({{PROJECT_TYPE}}, node)
	@npm test
else
	@echo "$(YELLOW)No test command configured for '{{PROJECT_TYPE}}'$(NC)"
endif

# ==============================================================================
# BUILD & CLEAN
# ==============================================================================

build:
	@echo "$(BLUE)Building Docker image...$(NC)"
	@docker build -t {{PROJECT_NAME}} .

clean:
	@echo "$(BLUE)Cleaning up...$(NC)"
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@rm -rf .pytest_cache .ruff_cache

.PHONY: help install-hooks lint format test build clean
```

#### **Dockerfile**
Create a file named `Dockerfile` with this content. This is a multi-stage Dockerfile for a {{PROJECT_TYPE}} application.

```dockerfile
# Use a variable for the Python version
ARG PYTHON_VERSION=3.11

# Stage 1: Build stage
FROM python:${PYTHON_VERSION}-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends build-essential

# Install poetry
RUN pip install poetry

# Copy only files necessary for dependency installation
COPY poetry.lock pyproject.toml ./

# Install dependencies
RUN poetry install --no-dev --no-root

# Stage 2: Final stage
FROM python:${PYTHON_VERSION}-slim as final

WORKDIR /app

# Create a non-root user
RUN useradd --create-home appuser
USER appuser

# Copy virtual environment from builder
COPY --from=builder /app/.venv ./.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy application code
COPY src/ ./src/

# Set the command to run the application
CMD ["python", "src/main.py"]
```

#### **.gitignore**
Create a file named `.gitignore` with standard ignores for a {{PROJECT_TYPE}} project.

```gitignore
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
#  Usually these files are written by a python script from a template
#  before PyInstaller builds the exe, so as to inject date/other infos into it.
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# pyenv
.python-version

# PEP 582; used by PDM, PEP 582 compatible tools
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# pytype
.pytype/

# Cython debug symbols
cython_debug/

# VSCode
.vscode/
```

#### **.github/workflows/release-please.yml**
Create this file at `.github/workflows/release-please.yml`.

```yaml
# This workflow uses release-please to automate releases.
# When you merge a PR with a conventional commit message, it will:
# 1. Create or update a release PR.
# 2. When the release PR is merged, it creates a GitHub release and tag.

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
      - uses: google-github-actions/release-please-action@v4
        with:
          # This token is used to create the release PR.
          # You need to create a secret in your repository settings called RELEASE_PLEASE_TOKEN
          # and give it a Personal Access Token (PAT) with repo and workflow scopes.
          token: ${{ secrets.RELEASE_PLEASE_TOKEN }}
          release-type: {{PROJECT_TYPE}}
```

#### **.pre-commit-config.yaml**
Create a file named `.pre-commit-config.yaml`.

```yaml
default_install_hook_types:
  - pre-commit
  - commit-msg
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
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
    rev: v3.2.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
        args: []
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.5.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/rhysd/actionlint
    rev: v1.7.1
    hooks:
      - id: actionlint
  - repo: local
    hooks:
      - id: trufflehog
        name: TruffleHog
        description: Detect secrets in your data.
        entry: bash -c 'trufflehog git file://. --since-commit HEAD --fail --no-update'
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

#### **pyproject.toml**
Create a file named `pyproject.toml` for project metadata and tool configuration.

```toml
[build-system]
requires = ["poetry-core>=1.0.0"]
build-backend = "poetry.core.masonry.api"

[tool.poetry]
name = "{{PROJECT_NAME}}"
version = "0.1.0"
description = ""
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = "^3.11"

[tool.poetry.dev-dependencies]
pytest = "^8.0"
ruff = "^0.5.0"
pre-commit = "^3.6"
bandit = "^1.7"
uv = "^0.2.0"

[tool.ruff]
line-length = 88
select = ["E", "F", "W", "I", "UP", "B", "C4"]
ignore = ["E501"]

[tool.ruff.format]
quote-style = "double"

[tool.bandit]
exclude_dirs = ["tests"]
```

#### **.claude/settings.json**
Create this file at `.claude/settings.json`.

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

---
**Final Command**

After creating all the files, run this command:
`!pre-commit install --install-hooks --hook-type pre-commit --hook-type commit-msg`
