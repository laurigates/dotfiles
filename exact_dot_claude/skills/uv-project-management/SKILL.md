# UV Project Management

Quick reference for UV project lifecycle and dependency management.

## When This Skill Applies

- Python projects using UV for dependency management
- Initializing new Python projects
- Adding, removing, or updating dependencies
- Managing lockfiles and virtual environments
- Syncing project dependencies

## Quick Reference

### Project Initialization

```bash
# Create new project with complete structure
uv init my-project
cd my-project

# Initialize in existing directory
uv init

# Initialize with specific Python version
uv init --python 3.11 my-app
```

### Dependency Management

```bash
# Add dependencies
uv add requests
uv add 'flask>=2.0'
uv add 'django>=4.0,<5.0'

# Add development dependencies
uv add --dev pytest pytest-cov black

# Add optional dependency groups
uv add --group docs sphinx sphinx-rtd-theme

# Remove dependencies
uv remove requests flask

# Migrate from requirements.txt
uv add -r requirements.txt
```

### Lockfile Operations

```bash
# Create/update lockfile (uv.lock)
uv lock

# Lock with upgraded packages
uv lock --upgrade-package requests
uv lock --upgrade

# Lock without installing (CI/CD)
uv lock --frozen
```

### Environment Synchronization

```bash
# Sync environment to lockfile
uv sync

# Sync without updating lockfile
uv sync --frozen

# Error if lockfile is out of date
uv sync --locked
```

### Running Commands

```bash
# Run command in project environment
uv run python script.py
uv run pytest
uv run ruff check

# Run with specific Python version
uv run --python 3.11 script.py
```

## Project Structure

UV projects follow this standard structure:

```
my-project/
├── pyproject.toml      # Project metadata and dependencies
├── uv.lock            # Locked dependency versions
├── .venv/             # Virtual environment (auto-created)
├── README.md
└── src/
    └── my_project/
        └── __init__.py
```

## Generated pyproject.toml

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Add your description here"
readme = "README.md"
dependencies = []

[build-system]
requires = ["uv_build>=0.9.2,<0.10.0"]
build-backend = "uv_build"
```

## Common Workflows

### Starting a New Project

```bash
uv init my-app && cd my-app
uv add ruff pytest
uv run pytest
```

### Adding Multiple Dependencies

```bash
# Production dependencies
uv add fastapi uvicorn 'pydantic>=2.0'

# Development tooling
uv add --dev pytest pytest-cov ruff mypy

# Documentation
uv add --group docs sphinx mkdocs-material
```

### Updating Dependencies

```bash
# Update specific package
uv lock --upgrade-package requests

# Update all dependencies
uv lock --upgrade

# Sync after update
uv sync
```

## Key Features

- **Fast**: 10-100x faster than pip
- **Deterministic**: Lockfile ensures reproducible installs
- **Automatic**: Creates and manages virtual environments
- **Modern**: Uses pyproject.toml for configuration
- **Compatible**: Works with pip, Poetry, and other tools

## See Also

- `uv-python-versions` - Managing Python interpreter versions
- `uv-workspaces` - Monorepo and multi-package projects
- `uv-advanced-dependencies` - Git, path, and constraint dependencies
- `python-testing` - Running tests with pytest
- `python-code-quality` - Linting and formatting with ruff

## References

- Official docs: https://docs.astral.sh/uv/
- GitHub: https://github.com/astral-sh/uv
- Detailed guide: See REFERENCE.md in this skill directory
