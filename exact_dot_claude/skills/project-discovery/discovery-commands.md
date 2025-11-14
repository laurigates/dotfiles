# Discovery Commands Reference

Comprehensive command reference for project discovery, organized by phase with expected outputs and fallback strategies.

---

## Phase 1: Git State Analysis

### Current Branch Information

```bash
# Get current branch name
git branch --show-current
# Output: feature/user-auth

# Alternative (works in older git versions)
git rev-parse --abbrev-ref HEAD
# Output: feature/user-auth

# Show branch with tracking info
git status --short --branch
# Output: ## feature/user-auth...origin/feature/user-auth [ahead 2, behind 1]
```

**What to Extract:**
- Branch name (e.g., `main`, `feature/user-auth`, `develop`)
- Tracking branch (e.g., `origin/main`)
- Ahead/behind status (e.g., `[ahead 2, behind 1]`)

---

### Working Tree Status

```bash
# Get clean status overview
git status --short --branch
# Output example:
## main...origin/main [ahead 1]
 M src/auth.py
 M tests/test_auth.py
?? new_file.py

# Count uncommitted files
git status --porcelain | wc -l
# Output: 5

# Detailed changes (staged)
git diff --staged --stat
# Output:
src/auth.py     | 23 +++++++++++++++++------
tests/test_auth.py | 15 +++++++++++++--
2 files changed, 30 insertions(+), 8 deletions(-)

# Detailed changes (unstaged)
git diff --stat
# Output:
README.md | 3 ++-
1 file changed, 2 insertions(+), 1 deletion(-)
```

**Status Codes:**
- `M` = Modified
- `A` = Added (staged)
- `D` = Deleted
- `R` = Renamed
- `??` = Untracked
- `!!` = Ignored

---

### Remote Sync Status

```bash
# Check commits ahead/behind remote
git rev-list --left-right --count HEAD...@{u} 2>/dev/null || echo "No tracking branch"
# Output: 2       1
# Meaning: 2 commits ahead, 1 commit behind

# Alternative: show detailed divergence
git status --short --branch
# Output: ## main...origin/main [ahead 2, behind 1]

# Check if remote exists
git remote -v
# Output:
origin  git@github.com:user/repo.git (fetch)
origin  git@github.com:user/repo.git (push)

# Fetch latest remote info (non-invasive)
git fetch --dry-run 2>&1 | head -5
```

**Interpretation:**
- `ahead X` = You have X local commits not pushed to remote
- `behind Y` = Remote has Y commits you don't have locally
- `No tracking branch` = Branch is local-only (not pushed yet)

---

### Recent Commit History

```bash
# Last 10 commits (one-line format)
git log --oneline --decorate -n 10
# Output:
a1b2c3d (HEAD -> feature/auth, origin/feature/auth) feat(auth): add OAuth2 support
e4f5g6h fix(api): handle timeout edge case
i7j8k9l docs: update API documentation
m0n1o2p refactor(auth): simplify token validation

# Last 10 commits with author and date
git log --pretty=format:"%h - %an, %ar : %s" -n 10
# Output:
a1b2c3d - Alice Smith, 2 hours ago : feat(auth): add OAuth2 support
e4f5g6h - Bob Jones, 1 day ago : fix(api): handle timeout edge case

# Check for conventional commits
git log --oneline -n 20 | grep -E "^[a-f0-9]+ (feat|fix|docs|style|refactor|test|chore|build|ci|perf|revert)(\(.+\))?:"
# Output (matches only):
a1b2c3d feat(auth): add OAuth2 support
e4f5g6h fix(api): handle timeout edge case

# Last commit details
git log -1 --stat
# Shows full commit message, author, date, and file changes
```

**Commit Pattern Detection:**
- If `grep` returns matches → Conventional commits in use
- If `grep` returns nothing → Free-form commit messages

---

### Detached HEAD Detection

```bash
# Check if in detached HEAD state
git symbolic-ref -q HEAD || echo "Detached HEAD"
# Output: refs/heads/main (normal) OR "Detached HEAD" (problem)

# If detached, show what commit you're on
git describe --always --tags
# Output: v1.2.3-45-ga1b2c3d
```

**Risk:** Detached HEAD means commits aren't associated with a branch and can be lost.

---

## Phase 2: Project Type Detection

### Manifest File Detection

```bash
# Check for project manifests
ls -la | grep -E "(package\.json|Cargo\.toml|pyproject\.toml|go\.mod|Gemfile|pom\.xml|build\.gradle|composer\.json|mix\.exs)"
# Output (example):
-rw-r--r--  1 user user  1234 Jan 15 10:30 package.json
-rw-r--r--  1 user user   567 Jan 15 10:30 pyproject.toml

# Check specific manifest exists
test -f package.json && echo "JavaScript/TypeScript project" || echo "Not JS/TS"
test -f Cargo.toml && echo "Rust project" || echo "Not Rust"
test -f pyproject.toml && echo "Python project" || echo "Not Python"
```

---

### Monorepo Detection

```bash
# Find all package.json files (JavaScript monorepo indicator)
find . -maxdepth 3 -name "package.json" | head -20
# Output:
./package.json
./packages/frontend/package.json
./packages/backend/package.json
./apps/web/package.json

# Find all Cargo.toml files (Rust workspace indicator)
find . -maxdepth 3 -name "Cargo.toml" | head -20

# Find all pyproject.toml files (Python monorepo indicator)
find . -maxdepth 3 -name "pyproject.toml" | head -20

# Check for workspace indicators in root manifest
grep -i "workspace\|workspaces" package.json 2>/dev/null
# Output: "workspaces": ["packages/*", "apps/*"]

grep -i "\[workspace\]" Cargo.toml 2>/dev/null
# Output: [workspace]
```

**Interpretation:**
- **Single manifest** → Single-project repository
- **Multiple manifests** → Monorepo with sub-projects
- **Workspace key** in root manifest → Confirmed monorepo

---

### Directory Structure Scan

```bash
# List all directories (max depth 1)
ls -d */ 2>/dev/null | head -20
# Output:
src/
tests/
docs/
scripts/
.github/

# Common directory patterns
find . -maxdepth 2 -type d -name "src" -o -name "lib" -o -name "tests" -o -name "test" -o -name "docs" -o -name "examples"
```

**Common Patterns:**
- `src/` → Source code
- `lib/` → Library code (Rust, Ruby)
- `tests/` or `test/` → Test files
- `docs/` → Documentation
- `examples/` → Example code
- `.github/` → GitHub-specific files (Actions, templates)

---

### Entry Point Detection

```bash
# Find main files (common entry points)
find . -maxdepth 2 -name "main.*" -o -name "index.*" -o -name "app.*" -o -name "__init__.py" -o -name "server.*" 2>/dev/null | head -10
# Output:
./src/main.rs
./index.js
./app.py

# JavaScript/TypeScript entry point from package.json
jq -r '.main // "No main field"' package.json 2>/dev/null
# Output: dist/index.js

# Check for npm start script
jq -r '.scripts.start // "No start script"' package.json 2>/dev/null
# Output: node src/index.js

# Python entry point (check pyproject.toml)
grep -A 5 "\[project.scripts\]" pyproject.toml 2>/dev/null
# Output:
[project.scripts]
myapp = "myapp.main:main"
```

---

### Language Version Detection

```bash
# Node.js version (from package.json engines)
jq -r '.engines.node // "Not specified"' package.json 2>/dev/null
# Output: >=18.0.0

# Python version (from pyproject.toml)
grep "requires-python" pyproject.toml 2>/dev/null
# Output: requires-python = ">=3.9"

# Rust edition (from Cargo.toml)
grep "edition" Cargo.toml 2>/dev/null
# Output: edition = "2021"

# Go version (from go.mod)
grep "^go " go.mod 2>/dev/null
# Output: go 1.21
```

---

### Framework Detection

#### JavaScript/TypeScript

```bash
# Check package.json dependencies for frameworks
jq -r '.dependencies | keys[]' package.json 2>/dev/null | grep -E "(react|vue|next|nuxt|svelte|angular|express|fastify|nest)"
# Output:
react
next

# Check for framework config files
ls | grep -E "(next\.config|vite\.config|webpack\.config|vue\.config)"
# Output:
next.config.js
vite.config.ts
```

#### Python

```bash
# Check pyproject.toml dependencies for frameworks
grep -E "(django|fastapi|flask|pyramid)" pyproject.toml 2>/dev/null
# Output:
dependencies = ["fastapi>=0.100.0", "uvicorn[standard]>=0.23.0"]

# Check for framework-specific files
ls | grep -E "(manage\.py|wsgi\.py|asgi\.py)"
# Output: manage.py (Django indicator)
```

#### Rust

```bash
# Check Cargo.toml dependencies for web frameworks
grep -E "(actix-web|rocket|axum|warp)" Cargo.toml 2>/dev/null
# Output:
actix-web = "4.4"
```

---

## Phase 3: Development Tooling Discovery

### Build System Detection

```bash
# Check for build files
ls -la | grep -E "(Makefile|Justfile|taskfile|build\.sh)"
# Output:
-rw-r--r--  1 user user  2345 Jan 15 10:30 Makefile

# Extract Makefile targets
grep "^[a-zA-Z0-9_-]*:" Makefile 2>/dev/null | cut -d: -f1 | head -20
# Output:
build
test
lint
clean
install

# Extract package.json scripts (JavaScript/TypeScript)
jq -r '.scripts | to_entries[] | .key + ": " + .value' package.json 2>/dev/null
# Output:
build: vite build
test: vitest
lint: eslint src/
format: prettier --write src/

# Cargo commands (Rust) - always available
echo "build, test, check, run, clippy, fmt"
```

---

### Test Framework Detection

```bash
# Find test files
find . -maxdepth 3 -name "*test*" -o -name "*spec*" 2>/dev/null | grep -E "\.(js|ts|py|rs|go)$" | head -10
# Output:
./tests/test_auth.py
./src/auth.test.ts
./src/utils.spec.js

# JavaScript/TypeScript test frameworks
jq -r '.devDependencies | keys[]' package.json 2>/dev/null | grep -E "(jest|vitest|mocha|ava|jasmine)"
# Output: vitest

# Python test frameworks
grep -E "(pytest|unittest|nose)" pyproject.toml 2>/dev/null
# Output: pytest>=7.0

# Check for test config files
ls | grep -E "(jest\.config|vitest\.config|pytest\.ini|phpunit\.xml)"
# Output: vitest.config.ts

# Rust tests (always built-in)
grep -r "#\[test\]" src/ 2>/dev/null | wc -l
# Output: 45 (number of test functions)
```

**Test Framework Mapping:**
| Language | Common Frameworks | Config Files |
|----------|------------------|--------------|
| JavaScript/TypeScript | Jest, Vitest, Mocha | jest.config.js, vitest.config.ts |
| Python | pytest, unittest | pytest.ini, pyproject.toml |
| Rust | Built-in cargo test | N/A |
| Go | Built-in go test | N/A |
| Ruby | RSpec, Minitest | .rspec, test/test_helper.rb |

---

### Linter & Formatter Detection

```bash
# Check for linter/formatter config files
ls -la | grep -E "(\.eslintrc|\.prettierrc|ruff\.toml|\.flake8|rustfmt\.toml|\.golangci|\.editorconfig)"
# Output:
.eslintrc.json
.prettierrc.js
ruff.toml

# JavaScript/TypeScript linters
jq -r '.devDependencies | keys[]' package.json 2>/dev/null | grep -E "(eslint|prettier|biome)"
# Output:
eslint
prettier

# Python linters/formatters
grep -E "(ruff|black|flake8|mypy)" pyproject.toml 2>/dev/null
# Output:
ruff>=0.1.0
mypy>=1.0

# Rust (always available via cargo)
rustup component list --installed | grep -E "(rustfmt|clippy)"
# Output:
rustfmt
clippy
```

---

### Pre-commit Hooks

```bash
# Check if pre-commit is installed
ls -la .git/hooks/ 2>/dev/null | grep -v sample
# Output:
-rwxr-xr-x  1 user user  478 Jan 15 10:30 pre-commit
-rwxr-xr-x  1 user user  234 Jan 15 10:30 commit-msg

# Read pre-commit config
cat .pre-commit-config.yaml 2>/dev/null | head -30
# Output:
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.0
    hooks:
      - id: ruff

# List configured hooks
grep "id:" .pre-commit-config.yaml 2>/dev/null | awk '{print $3}'
# Output:
trailing-whitespace
end-of-file-fixer
ruff
```

---

### CI/CD Detection

```bash
# GitHub Actions
ls -la .github/workflows/ 2>/dev/null | grep "\.yml"
# Output:
-rw-r--r--  1 user user  1234 Jan 15 10:30 build.yml
-rw-r--r--  1 user user   567 Jan 15 10:30 test.yml
-rw-r--r--  1 user user   890 Jan 15 10:30 deploy.yml

# List workflow names
grep "^name:" .github/workflows/*.yml 2>/dev/null
# Output:
.github/workflows/build.yml:name: Build
.github/workflows/test.yml:name: Test Suite
.github/workflows/deploy.yml:name: Deploy to Production

# GitLab CI
ls -la .gitlab-ci.yml 2>/dev/null
# Output: -rw-r--r--  1 user user  2345 Jan 15 10:30 .gitlab-ci.yml

# CircleCI
ls -la .circleci/config.yml 2>/dev/null
# Output: -rw-r--r--  1 user user  1234 Jan 15 10:30 .circleci/config.yml

# Travis CI (legacy)
ls -la .travis.yml 2>/dev/null
```

---

## Phase 4: Documentation Quick Scan

### README Analysis

```bash
# First 50 lines of README (captures header and intro)
head -50 README.md 2>/dev/null
# Output: [Full content of first 50 lines]

# Extract project title (first heading)
grep "^#" README.md 2>/dev/null | head -1
# Output: # My Awesome Project

# Find installation/setup section
grep -n -A 10 -i "install\|setup\|getting started" README.md 2>/dev/null | head -30
# Output:
15:## Installation
16:
17:```bash
18:npm install
19:npm run build
20:```

# Count README lines (quality indicator)
wc -l README.md 2>/dev/null
# Output: 234 README.md
```

**Quality Indicators:**
- < 50 lines → Minimal documentation
- 50-200 lines → Basic documentation
- 200+ lines → Comprehensive documentation

---

### Documentation Files

```bash
# Check for standard documentation files
ls -la | grep -E "(README|CONTRIBUTING|CHANGELOG|LICENSE|CODE_OF_CONDUCT|SECURITY|ARCHITECTURE)"
# Output:
-rw-r--r--  1 user user  5678 Jan 15 10:30 README.md
-rw-r--r--  1 user user  1234 Jan 15 10:30 CONTRIBUTING.md
-rw-r--r--  1 user user  2345 Jan 15 10:30 CHANGELOG.md
-rw-r--r--  1 user user  1067 Jan 15 10:30 LICENSE

# Check for docs directory
ls -la docs/ 2>/dev/null | head -20
# Output:
total 32
drwxr-xr-x  5 user user  160 Jan 15 10:30 .
-rw-r--r--  1 user user 1234 Jan 15 10:30 api.md
-rw-r--r--  1 user user  567 Jan 15 10:30 architecture.md
-rw-r--r--  1 user user  890 Jan 15 10:30 deployment.md

# Check for inline API documentation
grep -r "@param\|@returns\|@example\|@deprecated" src/ 2>/dev/null | wc -l
# Output: 145 (number of documented functions/methods)
```

---

### License Detection

```bash
# Check LICENSE file
head -5 LICENSE 2>/dev/null
# Output:
MIT License

Copyright (c) 2024 Author Name

# Or extract license from package.json
jq -r '.license // "Not specified"' package.json 2>/dev/null
# Output: MIT
```

---

## Performance Considerations

### Large Repository Optimization

If discovery takes too long (>30 seconds), use these optimizations:

```bash
# Limit file search depth
find . -maxdepth 2 -name "*.json"  # Instead of -maxdepth 5

# Use head to limit output
git log --oneline | head -10  # Instead of -n 10 (faster)

# Skip expensive operations
# Skip: find . -name "*test*" (slow in large repos)
# Use: ls tests/ or test/ (faster if structure is known)

# Use git ls-files instead of find
git ls-files | grep "test"  # Faster than find for tracked files
```

---

## Fallback Strategies

### When Commands Fail

```bash
# Git command fails (not a git repo)
git status 2>/dev/null || echo "Not a git repository"

# jq not installed
if command -v jq &> /dev/null; then
    jq -r '.scripts' package.json
else
    grep '"scripts"' package.json | head -20
fi

# File doesn't exist
cat README.md 2>/dev/null || echo "No README found"

# Command not found
command -v pytest &> /dev/null && pytest --version || echo "pytest not installed"
```

---

## Command Cheat Sheet

### Quick Discovery (30 seconds)

```bash
# Essential commands for rapid orientation
git status --short --branch
git log --oneline -n 5
ls -la | grep -E "(package\.json|Cargo\.toml|pyproject\.toml|Makefile)"
head -20 README.md
```

### Full Discovery (2-3 minutes)

```bash
# Complete systematic scan (run all Phase 1-4 commands)
# See SKILL.md for full command list
```

---

*This reference complements the main SKILL.md discovery workflow.*
