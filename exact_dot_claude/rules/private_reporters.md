# Context-Efficient Output

Use reporter flags for minimal, actionable output with direct file:line:col pointers.

## Linting

### Biome

```bash
biome check --reporter=github              # file:line:col format
biome check --reporter=github --staged     # Only staged files
biome check --max-diagnostics=N            # Limit to N issues
biome check --diagnostic-level=error       # Errors only, skip warnings
```

### ESLint

```bash
eslint --format=stylish                    # Compact grouped output
eslint --format=unix                       # One line per issue
eslint --max-warnings=0                    # Fail on any warning
```

## Testing

### Vitest

```bash
vitest --reporter=github-actions           # One-line per failure with file:line
vitest --reporter=dot                      # Minimal: dots for pass/fail
vitest --reporter=basic                    # Simple summary
vitest --bail=1                            # Stop on first failure
vitest --changed                           # Only affected tests
vitest --reporter=dot --bail=1             # Fast fail, minimal output
```

### Playwright

```bash
npx playwright test --reporter=line        # One line per test
npx playwright test --reporter=dot         # Minimal dots
npx playwright test --reporter=github      # GitHub Actions annotations
```

## Type Checking

### TypeScript

```bash
tsc --pretty false                         # Machine-readable output
tsc 2>&1 | head -30                        # Limit output length
```

### Basedpyright (Python)

```bash
basedpyright --outputjson                  # JSON for parsing
basedpyright 2>&1 | head -50               # Limit output
```

## Pre-commit Workflow Pattern

Combine for fast feedback:

```bash
# JavaScript/TypeScript
biome check --reporter=github --staged && tsc && vitest --reporter=dot --bail=1

# Python
ruff check --output-format=github && basedpyright && pytest -x -q
```
