# Test-Driven Development (TDD) Setup

Configure comprehensive testing infrastructure with CI/CD integration.

## Usage
```bash
claude chat --file ~/.claude/commands/tdd.md
```

## Workflow

### 1. Pre-commit Configuration
- **Install pre-commit**: Ensure pre-commit framework is installed
  ```bash
  pip install pre-commit
  ```
- **Configure hooks**: Create/update `.pre-commit-config.yaml`
  ```yaml
  repos:
    - repo: https://github.com/pre-commit/pre-commit-hooks
      rev: v4.5.0
      hooks:
        - id: trailing-whitespace
        - id: end-of-file-fixer
        - id: check-yaml
        - id: check-added-large-files
        - id: check-merge-conflict

    # Language-specific hooks
    - repo: https://github.com/astral-sh/ruff-pre-commit
      rev: v0.1.0
      hooks:
        - id: ruff
        - id: ruff-format

    - repo: https://github.com/pre-commit/mirrors-mypy
      rev: v1.0.0
      hooks:
        - id: mypy
  ```
- **Install hooks**: `pre-commit install`
- **Test configuration**: `pre-commit run --all-files`

### 2. Documentation Generation Setup
- **Configure documentation tool** based on language:
  - Python: Sphinx with autodoc
  - JavaScript/TypeScript: TypeDoc or JSDoc
  - Go: godoc
  - Rust: rustdoc

- **Create GitHub Action** for documentation:
  ```yaml
  name: Documentation
  on:
    push:
      branches: [main]
    pull_request:
      branches: [main]

  jobs:
    docs:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4

        - name: Setup environment
          # Language-specific setup

        - name: Generate documentation
          run: |
            # Documentation generation commands

        - name: Deploy to GitHub Pages
          if: github.ref == 'refs/heads/main'
          uses: peaceiris/actions-gh-pages@v3
          with:
            github_token: ${{ secrets.GITHUB_TOKEN }}
            publish_dir: ./docs/_build/html
  ```

### 3. Test Creation
- **Analyze codebase** to identify testing needs
- **Create test structure**:
  ```
  tests/
  ├── unit/           # Isolated unit tests
  ├── integration/    # Component interaction tests
  ├── e2e/           # End-to-end tests
  ├── fixtures/      # Test data and mocks
  └── conftest.py    # Shared test configuration (Python)
  ```

- **Write comprehensive tests**:
  - Unit tests for all functions/methods
  - Integration tests for component interactions
  - Edge cases and error conditions
  - Performance benchmarks where relevant

- **Test patterns to follow**:
  - Arrange-Act-Assert (AAA) pattern
  - Given-When-Then for BDD style
  - Test one thing per test
  - Descriptive test names

### 4. GitHub Actions Test Runner
- **Create test workflow** (`.github/workflows/tests.yml`):
  ```yaml
  name: Tests
  on:
    push:
      branches: [main, develop]
    pull_request:
      branches: [main]

  jobs:
    test:
      runs-on: ubuntu-latest
      strategy:
        matrix:
          python-version: [3.9, 3.10, 3.11, 3.12]

      steps:
        - uses: actions/checkout@v4

        - name: Set up Python
          uses: actions/setup-python@v4
          with:
            python-version: ${{ matrix.python-version }}

        - name: Install dependencies
          run: |
            pip install -e ".[test]"

        - name: Run tests with coverage
          run: |
            pytest --cov=src --cov-report=xml --cov-report=html

        - name: Upload coverage to Codecov
          uses: codecov/codecov-action@v3
          with:
            file: ./coverage.xml

        - name: Archive coverage report
          uses: actions/upload-artifact@v3
          with:
            name: coverage-report
            path: htmlcov/
  ```

### 5. Test Coverage Publication
- **Configure GitHub Pages**:
  - Enable GitHub Pages in repository settings
  - Set source to `gh-pages` branch

- **Create coverage workflow**:
  ```yaml
  name: Coverage Report
  on:
    push:
      branches: [main]

  jobs:
    coverage:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4

        - name: Setup and test
          # Run tests with coverage

        - name: Generate coverage badge
          run: |
            coverage-badge -o coverage.svg

        - name: Publish coverage report
          uses: peaceiris/actions-gh-pages@v3
          with:
            github_token: ${{ secrets.GITHUB_TOKEN }}
            publish_dir: ./htmlcov
            destination_dir: coverage

        - name: Update README badge
          run: |
            # Update coverage badge in README
  ```

- **Add badges to README**:
  ```markdown
  ![Tests](https://github.com/user/repo/workflows/Tests/badge.svg)
  ![Coverage](https://user.github.io/repo/coverage/coverage.svg)
  ```

## Configuration Files Created

1. `.pre-commit-config.yaml` - Pre-commit hooks
2. `.github/workflows/tests.yml` - Test runner
3. `.github/workflows/docs.yml` - Documentation generator
4. `.github/workflows/coverage.yml` - Coverage reporter
5. `pyproject.toml` or `setup.cfg` - Test dependencies
6. `pytest.ini` or `tox.ini` - Test configuration

## Success Criteria
- Pre-commit hooks passing
- All tests passing in CI
- Code coverage > 80%
- Documentation auto-generated
- Coverage report published
- Badges displaying in README
