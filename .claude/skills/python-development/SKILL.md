---
name: Python Development
description: Modern Python development with uv package manager, ruff linting, pytest testing, type hints, and pyproject.toml configuration. Automatically assists with Python projects, debugging, performance profiling, and best practices.
allowed-tools: Glob, Grep, Read, WebFetch, TodoWrite, WebSearch, BashOutput, KillShell, Edit, Write, NotebookEdit, Bash
---

# Python Development

Expert knowledge for modern Python development with focus on fast tooling, type safety, and comprehensive testing.

## Core Expertise

- **uv**: Fast package management and Python environment handling (10-100x faster than pip)
- **ruff**: Ultra-fast linting and code formatting (replaces black, isort, flake8)
- **pytest**: Comprehensive testing with fixtures, parametrization, and coverage
- **Type Hints**: Static type checking with mypy/pyright integration
- **pyproject.toml**: Modern Python project configuration with dependency groups

## Key Capabilities

- **Project Setup**: Modern project structure with uv and pyproject.toml
- **Code Quality**: Linting with ruff, formatting, type checking
- **Testing**: Unit tests, integration tests, parametrization, coverage tracking
- **Dependencies**: Package management with uv, dependency groups for dev/docs/security
- **CI Integration**: Automated testing and quality checks
- **Debugging**: Python-specific debugging with pdb, profiling, and memory analysis

## Python Debugging Expertise

**Interactive Debugging**
- **pdb/ipdb**: Step-through debugging with breakpoints and inspection
- **pytest --pdb**: Drop into debugger on test failures
- **Django Debug Toolbar**: Web application debugging and profiling
- **Flask Debug Mode**: Development server with auto-reload and debugger

**Performance & Memory Profiling**
- **memory_profiler**: Line-by-line memory consumption analysis
- **py-spy**: Sampling profiler for production Python programs
- **cProfile/profile**: Built-in CPU profiling modules
- **line_profiler**: Line-by-line execution time analysis
- **tracemalloc**: Memory allocation tracking (built-in)

**Debugging Commands**
```bash
# Interactive debugging
python -m pdb script.py                # Start with debugger
pytest --pdb                           # Debug on test failure

# Memory profiling
python -m memory_profiler script.py    # Memory usage per line
py-spy top -- python script.py        # Real-time CPU profiling

# Performance profiling
python -m cProfile -s cumtime script.py | head -20
python -m trace --trace script.py     # Trace execution
```

## Modern uv Workflow

**Project Initialization**
```bash
# Create new project with modern structure
uv init my-project --package          # Creates src/ layout project
cd my-project

# Create venv and install
uv venv
uv sync                               # Install from uv.lock

# Add dependencies
uv add requests pydantic              # Runtime dependencies
uv add --dev pytest ruff mypy        # Development dependencies
uv add --group docs sphinx            # Dependency groups
```

**Dependency Management**
```bash
# Add with version constraints
uv add "fastapi>=0.100.0,<1.0.0"
uv add "sqlalchemy[postgresql]"

# Update and sync
uv lock --upgrade                     # Update lockfile
uv sync --frozen                      # Install exact versions

# Run application
uv run app.py
```

## Essential Commands

```bash
# Code quality
uv run ruff check --fix .               # Lint and auto-fix
uv run ruff format .                    # Format code
uv run mypy .                           # Type checking

# Testing
uv run pytest                          # Run tests
uv run pytest --cov                    # With coverage
uv run pytest -v --tb=short           # Verbose output

# Building and publishing
uv build                               # Build package
uv publish --token $PYPI_TOKEN        # Publish to PyPI
```

## Best Practices

**Project Structure (src layout)**
```
my-project/
├── pyproject.toml
├── uv.lock
├── README.md
├── src/
│   └── my_awesome_project/
│       ├── __init__.py
│       ├── main.py
│       └── utils.py
└── tests/
    ├── test_main.py
    └── test_utils.py
```

**Type Hints (Python 3.10+)**
```python
def process_data(
    items: list[str],                    # Use list[T] not List[T]
    config: dict[str, int],              # Use dict[K, V]
    optional_param: str | None = None,   # Use | not Union
) -> tuple[bool, str]:
    """Process data with modern type hints."""
    return True, "success"
```

**Testing with pytest**
```python
import pytest

@pytest.fixture
def sample_data():
    return {"key": "value"}

@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("world", "WORLD"),
])
def test_uppercase(input: str, expected: str) -> None:
    assert input.upper() == expected
```

For detailed pyproject.toml configuration, advanced debugging patterns, CI/CD integration, and troubleshooting, see REFERENCE.md.
