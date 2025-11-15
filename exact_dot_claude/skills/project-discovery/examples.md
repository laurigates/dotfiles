# Discovery Examples

Complete discovery outputs for various project types and scenarios.

---

## Example 1: Python Project (FastAPI + pytest + ruff + GitHub Actions)

### Discovery Output

```markdown
# Project Discovery Summary

## 📊 Project Overview
- **Type**: Python 3.11+ / FastAPI / Single-project
- **Purpose**: REST API for user authentication and management with OAuth2 support
- **Entry Point**: `uvicorn app.main:app --reload` (from pyproject.toml scripts)

## 🔀 Git State
- **Branch**: feature/oauth2-support
- **Status**: 3 files changed (2 staged, 1 unstaged)
- **Remote Sync**: 2 commits ahead, 0 commits behind
- **Last Commit**: a1b2c3d - feat(auth): add OAuth2 token refresh by Alice Smith (2 hours ago)
- **Commit Style**: Conventional commits detected ✅

### ⚠️ Risk Flags
- **Warning**: 1 unstaged file (tests/test_oauth.py) - remember to stage before committing
- **Warning**: 2 commits ahead of origin/feature/oauth2-support - push when ready

## 🛠️ Development Tooling

### Build System
- **Package Manager**: uv (modern Python package manager)
- **Build Command**: `uv build`
- **Dev Server**: `uv run uvicorn app.main:app --reload`

### Test Framework
- **Framework**: pytest 7.4+
- **Test Command**: `uv run pytest` or `make test`
- **Test Location**: tests/ directory with 45 test files
- **Coverage**: Coverage.py configured (97% target in pyproject.toml)

### Code Quality
- **Linters**: ruff (configured for line length 100, strict mode)
- **Formatters**: ruff format (Black-compatible)
- **Type Checking**: mypy (strict mode enabled)
- **Pre-commit Hooks**: Configured ✅
  - ruff linting
  - ruff formatting
  - mypy type checking
  - trailing-whitespace
  - end-of-file-fixer
  - detect-secrets

### CI/CD
- **GitHub Actions**: 3 workflows detected
  - `test.yml` - Run pytest on Python 3.11, 3.12
  - `lint.yml` - Run ruff + mypy
  - `deploy.yml` - Deploy to staging on merge to develop

## 📚 Documentation
- **README**: Comprehensive (342 lines) with setup instructions, API docs, examples
- **CONTRIBUTING**: Present with development workflow and code style guide
- **Other Docs**:
  - docs/api.md - OpenAPI/Swagger documentation
  - docs/architecture.md - System design overview
  - CHANGELOG.md - Release history managed by release-please

## ✅ Recommendations

1. **Stage unstaged test file** - Run `git add tests/test_oauth.py` to include in next commit
2. **Push commits when ready** - 2 commits waiting to be pushed to remote
3. **Run tests before pushing** - Use `make test` or `uv run pytest` to verify changes
4. **Follow conventional commits** - Continue using feat/fix/docs prefixes (detected in history)
5. **Pre-commit hooks active** - Commits will be validated automatically

---

**Discovery completed in 2.1 minutes. Ready to work with clear context.**
```

**Interpretation:**
- ✅ Safe to work on feature branch
- ✅ Conventional commits → can use automated changelog
- ✅ Strong tooling setup (tests, linting, type checking, CI/CD)
- ⚠️ Minor housekeeping: stage unstaged file, push commits

---

## Example 2: JavaScript/TypeScript (React + Next.js + Vitest + ESLint)

### Discovery Output

```markdown
# Project Discovery Summary

## 📊 Project Overview
- **Type**: TypeScript 5.0+ / Next.js 14 (React) / Single-project
- **Purpose**: E-commerce web application with server-side rendering and API routes
- **Entry Point**: `npm run dev` (Next.js dev server on port 3000)

## 🔀 Git State
- **Branch**: main
- **Status**: Working tree clean ✅
- **Remote Sync**: In sync with origin/main (0 ahead, 0 behind)
- **Last Commit**: e4f5g6h - Merge pull request #42 from feature/cart-improvements by GitHub Bot (1 day ago)
- **Commit Style**: Mix of conventional commits and merge commits

### ⚠️ Risk Flags
- **Critical**: Currently on main branch - create feature branch before making changes!

## 🛠️ Development Tooling

### Build System
- **Package Manager**: npm (lock file: package-lock.json)
- **Build Command**: `npm run build` (Next.js production build)
- **Scripts**:
  - `dev` - Start development server
  - `build` - Create production build
  - `start` - Start production server
  - `lint` - Run ESLint
  - `test` - Run Vitest
  - `type-check` - Run TypeScript compiler

### Test Framework
- **Framework**: Vitest 1.0+ (fast Vite-native test runner)
- **Test Command**: `npm test` or `npm run test:watch`
- **Test Location**: **/*.test.ts, **/*.test.tsx files colocated with source
- **Test Count**: 127 test files detected

### Code Quality
- **Linters**: ESLint 8.x with TypeScript support
- **Formatters**: Prettier 3.x (integrated with ESLint)
- **Type Checking**: TypeScript strict mode enabled
- **Pre-commit Hooks**: Not configured ⚠️

### CI/CD
- **GitHub Actions**: 2 workflows detected
  - `ci.yml` - Build + test + lint on PRs and main branch
  - `deploy-vercel.yml` - Auto-deploy to Vercel on push to main

## 📚 Documentation
- **README**: Comprehensive (278 lines) with:
  - Getting started guide
  - Environment variables setup (.env.example provided)
  - Development workflow
  - Deployment instructions
- **CONTRIBUTING**: Present with PR guidelines and code review process
- **Other Docs**:
  - docs/ directory with architecture docs and API documentation
  - Storybook setup detected (for component documentation)

## ✅ Recommendations

1. **Create feature branch immediately** - Working on main is risky: `git checkout -b feature/your-feature`
2. **Review environment setup** - Check .env.example for required variables
3. **Run tests to establish baseline** - `npm test` to ensure all tests pass before changes
4. **Consider adding pre-commit hooks** - Install husky + lint-staged for automatic checks
5. **Safe working tree** - No uncommitted changes, can proceed with confidence

---

**Discovery completed in 2.3 minutes. Ready to work with clear context.**
```

**Interpretation:**
- 🔴 **Critical**: On main branch → must create feature branch first
- ✅ Clean working tree → safe to start
- ✅ Modern tooling (Next.js, Vitest, TypeScript)
- ⚠️ No pre-commit hooks → manual discipline required

---

## Example 3: Rust Project (Actix-web + Cargo + Clippy)

### Discovery Output

```markdown
# Project Discovery Summary

## 📊 Project Overview
- **Type**: Rust 1.75+ (Edition 2021) / Actix-web 4.x / Single-project
- **Purpose**: High-performance REST API service with PostgreSQL backend
- **Entry Point**: `cargo run` (binary: api-server)

## 🔀 Git State
- **Branch**: develop
- **Status**: Working tree clean ✅
- **Remote Sync**: In sync with origin/develop (0 ahead, 0 behind)
- **Last Commit**: i7j8k9l - refactor: simplify database connection pooling by Bob Jones (3 days ago)
- **Commit Style**: Conventional commits detected ✅

### ⚠️ Risk Flags
None - safe to proceed ✅

## 🛠️ Development Tooling

### Build System
- **Build Tool**: Cargo (Rust's built-in build system)
- **Build Command**: `cargo build --release` (optimized) or `cargo build` (debug)
- **Run Command**: `cargo run` (debug) or `cargo run --release` (optimized)
- **Workspace**: Single crate (not a workspace)

### Test Framework
- **Framework**: Built-in Rust test framework (cargo test)
- **Test Command**: `cargo test` or `make test`
- **Test Count**: 156 unit tests + 23 integration tests detected
- **Test Organization**:
  - Unit tests: Inline with `#[cfg(test)]` modules
  - Integration tests: tests/ directory

### Code Quality
- **Linters**: Clippy (Rust's official linter)
- **Formatters**: rustfmt (Rust's official formatter)
- **Linting Command**: `cargo clippy -- -D warnings` (fail on warnings)
- **Format Command**: `cargo fmt --all`
- **Pre-commit Hooks**: Not configured ⚠️

### CI/CD
- **CI System**: None detected ⚠️
- **Recommendation**: Consider adding GitHub Actions for automated testing

## 📚 Documentation
- **README**: Basic (89 lines) with:
  - Installation instructions
  - Build commands
  - Environment setup (DATABASE_URL required)
  - API endpoint list
- **CONTRIBUTING**: Not present
- **Other Docs**:
  - Inline documentation detected (/// doc comments in 78% of public items)
  - docs.rs configuration in Cargo.toml for automatic doc generation

## ✅ Recommendations

1. **Ready to develop** - Clean state on develop branch, no blockers
2. **Run tests before changes** - `cargo test` to establish baseline (156 tests detected)
3. **Use clippy for quality** - `cargo clippy` before committing to catch issues early
4. **Consider CI/CD** - Add GitHub Actions for automated testing on PRs
5. **Add pre-commit hooks** - Consider using pre-commit with rust hooks

---

**Discovery completed in 1.9 minutes. Ready to work with clear context.**
```

**Interpretation:**
- ✅ Perfect state: clean tree, feature branch, in sync
- ✅ Rust conventions followed (clippy, rustfmt, cargo test)
- ⚠️ Missing CI/CD → manual testing discipline required
- ℹ️ Good inline docs (78%) but sparse external docs

---

## Example 4: Monorepo (JavaScript/TypeScript - Turborepo)

### Discovery Output

```markdown
# Project Discovery Summary

## 📊 Project Overview
- **Type**: TypeScript 5.0+ / Monorepo (Turborepo) / 7 packages + 3 apps
- **Purpose**: Multi-product SaaS platform with shared component library
- **Structure**:
  - packages/ui - Shared React component library
  - packages/config - Shared configs (ESLint, TypeScript)
  - packages/utils - Utility functions
  - packages/types - Shared TypeScript types
  - packages/database - Prisma ORM + migrations
  - apps/web - Next.js customer-facing app
  - apps/admin - Next.js admin dashboard
  - apps/api - Express.js REST API

## 🔀 Git State
- **Branch**: feature/dashboard-analytics
- **Status**: 12 files changed (8 staged, 4 unstaged)
- **Remote Sync**: 5 commits ahead, 2 commits behind
- **Last Commit**: m0n1o2p - feat(admin): add analytics dashboard by You (30 minutes ago)
- **Commit Style**: Conventional commits with scope detected ✅

### ⚠️ Risk Flags
- **Warning**: 4 unstaged files across multiple packages - review and stage
- **Warning**: 2 commits behind origin/feature/dashboard-analytics - pull and rebase recommended
- **Conflict Risk**: Ahead and behind simultaneously suggests parallel work on same branch

## 🛠️ Development Tooling

### Build System
- **Monorepo Tool**: Turborepo (high-performance task orchestration)
- **Package Manager**: pnpm (workspace-aware)
- **Build Command**: `pnpm build` (builds all packages in dependency order)
- **Dev Command**: `pnpm dev` (starts all apps concurrently)
- **Workspace Scripts**:
  - `build` - Build all packages + apps
  - `dev` - Run all apps in development mode
  - `lint` - Lint all workspaces
  - `test` - Test all workspaces
  - `type-check` - TypeScript check across monorepo

### Test Framework
- **Framework**: Vitest (for packages) + Jest (for apps/api)
- **Test Command**: `pnpm test` (runs all workspace tests)
- **Test Organization**:
  - packages/ui: 89 component tests
  - packages/utils: 45 unit tests
  - apps/web: 34 integration tests
  - apps/admin: 28 integration tests
  - apps/api: 67 route tests

### Code Quality
- **Linters**: ESLint 8.x (shared config in packages/config)
- **Formatters**: Prettier 3.x (workspace-wide)
- **Type Checking**: TypeScript strict mode (shared tsconfig)
- **Pre-commit Hooks**: Configured ✅ (husky + lint-staged)
  - Lint staged files only
  - Format staged files
  - Type-check affected packages

### CI/CD
- **GitHub Actions**: 5 workflows detected
  - `ci.yml` - Build + test + lint (affected workspaces only)
  - `deploy-web.yml` - Deploy apps/web to Vercel
  - `deploy-admin.yml` - Deploy apps/admin to Vercel
  - `deploy-api.yml` - Deploy apps/api to Railway
  - `publish-packages.yml` - Publish packages to npm (on release)

## 📚 Documentation
- **README**: Comprehensive monorepo overview (456 lines)
  - Architecture diagram
  - Workspace structure explanation
  - Getting started guide
  - Development workflow (Turborepo remote caching enabled)
- **CONTRIBUTING**: Present with monorepo-specific guidelines
- **Per-workspace READMEs**: Each package and app has own README
- **Other Docs**:
  - docs/ directory with:
    - architecture/monorepo-structure.md
    - deployment/vercel-railway-setup.md
    - development/adding-new-package.md

## ✅ Recommendations

1. **Pull and rebase immediately** - 2 commits behind; resolve conflicts before continuing
2. **Stage remaining unstaged files** - Review 4 unstaged files across packages
3. **Run affected tests** - `pnpm test` to verify changes don't break dependent packages
4. **Check Turborepo cache** - Remote caching active; builds should be fast
5. **Validate cross-package changes** - Changes span multiple workspaces; ensure consistency
6. **Push after conflict resolution** - 5 commits waiting; share work with team

---

**Discovery completed in 3.2 minutes. Ready to work with clear context.**
```

**Interpretation:**
- ⚠️ **Moderate risk**: Behind remote + uncommitted changes → pull/rebase needed
- ✅ Monorepo setup is sophisticated (Turborepo + pnpm workspaces)
- ✅ Strong CI/CD coverage across all deployable apps
- ℹ️ Complexity: Changes may affect multiple packages; test carefully

---

## Example 5: Project with Uncommitted Changes (High Risk State)

### Discovery Output

```markdown
# Project Discovery Summary

## 📊 Project Overview
- **Type**: Python 3.10+ / Django 4.2 / Single-project
- **Purpose**: Web application for project management with team collaboration
- **Entry Point**: `python manage.py runserver` (Django dev server)

## 🔀 Git State
- **Branch**: main
- **Status**: 23 files changed (0 staged, 23 unstaged) ⚠️
- **Remote Sync**: 0 commits ahead, 7 commits behind
- **Last Commit**: a1b2c3d - fix: resolve database migration conflict by Alice Smith (3 weeks ago)
- **Commit Style**: Mix of conventional and free-form commits

### ⚠️ Risk Flags
- **Critical**: 23 uncommitted files on main branch - risk of data loss! ⚠️
- **Critical**: 7 commits behind origin/main - significant divergence! ⚠️
- **Critical**: Working on main branch directly - should use feature branch! ⚠️
- **Critical**: Last commit 3 weeks ago + 7 behind - workspace severely out of date! ⚠️

## 🛠️ Development Tooling

### Build System
- **Package Manager**: pip (requirements.txt detected)
- **Python Version**: 3.10+ (from runtime.txt)
- **Setup Command**: `pip install -r requirements.txt`

### Test Framework
- **Framework**: Django's built-in test framework (unittest-based)
- **Test Command**: `python manage.py test`
- **Test Location**: */tests.py or */test_*.py patterns
- **Test Count**: 78 test files detected

### Code Quality
- **Linters**: flake8 (configured in .flake8)
- **Formatters**: black (configured in pyproject.toml)
- **Pre-commit Hooks**: Not configured ⚠️

### CI/CD
- **GitHub Actions**: 1 workflow detected
  - `django-ci.yml` - Run tests on Python 3.10, 3.11

## 📚 Documentation
- **README**: Minimal (42 lines) with basic setup instructions
- **CONTRIBUTING**: Not present
- **Other Docs**: None detected

## ✅ Recommendations

1. **URGENT: Backup uncommitted work** - 23 uncommitted files at risk
   ```bash
   git stash save "WIP: backup before sync"
   ```

2. **URGENT: Update from remote** - 7 commits behind
   ```bash
   git pull origin main
   ```

3. **Resolve conflicts** - Likely conflicts after pulling (3 weeks divergence)

4. **Review stashed changes** - After update, review work-in-progress
   ```bash
   git stash list
   git stash show -p stash@{0}
   ```

5. **Create feature branch** - Move work off main branch
   ```bash
   git checkout -b feature/your-feature-name
   git stash pop
   ```

6. **Run tests after sync** - Verify nothing broke: `python manage.py test`

7. **Consider commit hygiene** - 23 changed files suggests large unorganized work; break into smaller logical commits

---

**Discovery completed in 2.1 minutes. ⚠️ HIGH RISK STATE - Address recommendations before proceeding!**
```

**Interpretation:**
- 🔴 **Critical state**: Multiple severe risk factors
- 🔴 23 uncommitted files → data loss risk
- 🔴 7 commits behind → significant divergence
- 🔴 On main branch → should be on feature branch
- 🔴 3 weeks outdated → integration challenges ahead

**Action Required Before Proceeding:**
1. Backup work (git stash)
2. Pull latest changes
3. Resolve conflicts
4. Move to feature branch
5. Test thoroughly

---

## Example 6: Clean Project (Ideal State)

### Discovery Output

```markdown
# Project Discovery Summary

## 📊 Project Overview
- **Type**: Go 1.21+ / Gin Web Framework / Single-project
- **Purpose**: RESTful API for inventory management with real-time updates
- **Entry Point**: `go run cmd/server/main.go` or `make run`

## 🔀 Git State
- **Branch**: feature/websocket-notifications
- **Status**: Working tree clean ✅
- **Remote Sync**: In sync with origin/feature/websocket-notifications (0 ahead, 0 behind)
- **Last Commit**: e4f5g6h - test: add websocket connection tests by You (15 minutes ago)
- **Commit Style**: Conventional commits detected ✅

### ⚠️ Risk Flags
None - ideal state ✅

## 🛠️ Development Tooling

### Build System
- **Build Tool**: Go build (native)
- **Build Command**: `go build -o bin/server cmd/server/main.go` or `make build`
- **Makefile**: Comprehensive with targets: build, test, lint, run, clean, docker
- **Docker**: Dockerfile present with multi-stage build

### Test Framework
- **Framework**: Go's built-in testing (testing package)
- **Test Command**: `go test ./...` or `make test`
- **Test Coverage**: `make test-coverage` (configured for 80% target)
- **Test Organization**:
  - Unit tests: *_test.go files alongside source
  - Integration tests: tests/ directory
  - Test count: 142 tests across 38 files

### Code Quality
- **Linters**: golangci-lint (configured in .golangci.yml)
- **Formatters**: gofmt + goimports (standard Go tooling)
- **Linting Command**: `make lint` or `golangci-lint run`
- **Pre-commit Hooks**: Configured ✅
  - golangci-lint
  - gofmt
  - go mod tidy
  - go vet

### CI/CD
- **GitHub Actions**: 3 workflows detected
  - `ci.yml` - Build + test + lint on Go 1.20, 1.21
  - `docker.yml` - Build and push Docker image to registry
  - `deploy.yml` - Deploy to Kubernetes cluster (staging + production)

## 📚 Documentation
- **README**: Comprehensive (312 lines) with:
  - Architecture overview with diagrams
  - API documentation with example requests
  - Setup and development guide
  - Deployment instructions (Docker + Kubernetes)
- **CONTRIBUTING**: Present with code style guide and PR process
- **Other Docs**:
  - docs/api.md - Full API reference (OpenAPI/Swagger)
  - docs/deployment.md - Production deployment guide
  - docs/architecture.md - System design and patterns
  - API documentation hosted at `/docs` endpoint (Swagger UI)

## ✅ Recommendations

1. **Continue with confidence** - Perfect state: clean tree, feature branch, in sync
2. **Run tests before final commit** - `make test` to verify all 142 tests pass
3. **Lint before pushing** - `make lint` (pre-commit hooks will also catch issues)
4. **Ready for PR** - When feature complete, open PR to develop or main
5. **No blockers detected** - Excellent project health and tooling setup

---

**Discovery completed in 2.0 minutes. Ready to work with clear context. ✅**
```

**Interpretation:**
- ✅ **Perfect state**: No risk flags, everything clean and organized
- ✅ Feature branch → proper workflow
- ✅ Clean tree → no risk of data loss
- ✅ In sync with remote → no conflicts
- ✅ Recent commit → actively maintained
- ✅ Comprehensive tooling → quality safeguards in place

---

## Comparison Summary

| Scenario | Risk Level | Key Issues | Recommended Action |
|----------|-----------|------------|-------------------|
| **Example 1: Python FastAPI** | 🟡 Low | Minor: unstaged file, commits to push | Stage file, push commits |
| **Example 2: Next.js** | 🟡 Medium | On main branch, no pre-commit hooks | Create feature branch immediately |
| **Example 3: Rust** | 🟢 None | Perfect state, minor CI/CD gap | Proceed with confidence |
| **Example 4: Monorepo** | 🟡 Medium | Behind remote, uncommitted files | Pull/rebase, stage files |
| **Example 5: Django** | 🔴 High | 23 uncommitted, 7 behind, on main, 3 weeks old | Urgent: backup, sync, branch |
| **Example 6: Go Gin** | 🟢 None | Ideal state | Continue development |

---

*These examples demonstrate the range of project states you'll encounter. The systematic discovery process provides clarity regardless of complexity.*
