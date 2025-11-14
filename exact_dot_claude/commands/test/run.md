---
allowed-tools: Bash(pytest:*), Bash(npm test:*), Bash(cargo test:*), Bash(go test:*), Bash(bun test:*), Read, Glob
argument-hint: [test-pattern] [--coverage] [--watch]
description: Universal test runner that automatically detects and runs the appropriate testing framework
---

## Context

**First, detect the project type and test framework:**

Use Read and Glob tools to check for configuration files:
- Node.js: Check for `package.json`, then inspect for test frameworks (vitest, jest, mocha)
- Python: Check for `pyproject.toml`, `pytest.ini`, or `setup.py`
- Rust: Check for `Cargo.toml`
- Go: Check for `go.mod`

**Determine the appropriate test command based on what you find.**

## Parameters

- `$1`: Optional test pattern or specific test file/directory
- `$2`: --coverage flag to enable coverage reporting
- `$3`: --watch flag to run tests in watch mode

## Test Execution

Based on the detected framework, run the appropriate test command:

### Python (pytest)
{{ if TEST_FRAMEWORK == "pytest" }}
Execute tests with pytest:
- Basic: `uv run pytest $1`
- With coverage: `uv run pytest --cov --cov-report=term-missing --cov-report=html $1`
- Watch mode: `uv run pytest-watch $1`
- Verbose: `uv run pytest -vv $1`
{{ endif }}

### Node.js (Vitest)
{{ if TEST_FRAMEWORK == "vitest" }}
Execute tests with Vitest:
- Basic: `npm run test $1`
- With coverage: `npm run test -- --coverage $1`
- Watch mode: `npm run test -- --watch $1`
{{ endif }}

### Node.js (Jest)
{{ if TEST_FRAMEWORK == "jest" }}
Execute tests with Jest:
- Basic: `npm test -- $1`
- With coverage: `npm test -- --coverage $1`
- Watch mode: `npm test -- --watch $1`
{{ endif }}

### Node.js (Mocha)
{{ if TEST_FRAMEWORK == "mocha" }}
Execute tests with Mocha:
- Basic: `npm test $1`
- With coverage: `nyc npm test $1`
- Watch mode: `npm test -- --watch $1`
{{ endif }}

### Rust (cargo)
{{ if TEST_FRAMEWORK == "cargo" }}
Execute tests with Cargo:
- Basic: `cargo test $1`
- With output: `cargo test -- --nocapture $1`
- Single threaded: `cargo test -- --test-threads=1 $1`
{{ endif }}

### Go
{{ if TEST_FRAMEWORK == "go" }}
Execute tests with Go:
- Basic: `go test ./... $1`
- With coverage: `go test -cover ./... $1`
- Verbose: `go test -v ./... $1`
{{ endif }}

## Fallback

If no framework is detected, try common test commands:
1. Check for Makefile: `make test`
2. Check for npm scripts: `npm test`
3. Check for test files and run directly

## Post-test Actions

After running tests:
1. Display summary of passed/failed tests
2. If coverage was requested, show coverage report location
3. If failures occurred, suggest using `/refactor` or `/debug` commands
