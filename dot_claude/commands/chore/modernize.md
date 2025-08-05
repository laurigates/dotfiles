# modernize.md - Application Modernization Instructions for Claude

When the user types `/modernize`, follow these instructions to systematically modernize applications to follow modern standards, 12-factor app principles, and security best practices.

## Overview

Execute a comprehensive modernization process that:

1. Analyzes the current application stack and dependencies
2. Upgrades package management to modern tools
3. Implements security hardening
4. Ensures 12-factor app compliance
5. Updates infrastructure and containerization
6. Modernizes documentation and development workflows

## Step-by-Step Instructions

### Phase 1: Application Analysis & Assessment

**1. Detect application stack and structure**

Analyze the repository to identify:

- **Backend technologies**: Check for `manage.py` (Django), `app.py` (Flask), `server.js` (Node.js), `main.go` (Go), `Cargo.toml` (Rust), `composer.json` (PHP), etc.
- **Frontend technologies**: Check for `package.json`, `src/` directory, framework-specific files
- **Database**: Look for migration files, database config, Docker services
- **Build tools**: `Dockerfile`, `docker-compose.yml`, `Makefile`, CI config files
- **Package managers**: `Pipfile`, `requirements.txt`, `package.json`, `Cargo.toml`, `go.mod`, etc.

**2. Inventory current dependency management**

For each detected technology stack:

- **Python**: Check for `Pipfile`, `requirements.txt`, `poetry.lock`, `pyproject.toml`
- **Node.js**: Check for `yarn.lock`, `package-lock.json`, `pnpm-lock.yaml`
- **Rust**: Check for `Cargo.lock`
- **Go**: Check for `go.mod`, `go.sum`
- **PHP**: Check for `composer.lock`
- **Ruby**: Check for `Gemfile.lock`

**3. Security and compliance audit**

Scan for common issues:

```bash
# Search for hardcoded secrets
grep -r "SECRET_KEY\|PASSWORD\|TOKEN\|API_KEY" --include="*.py" --include="*.js" --include="*.go" --include="*.rs" --exclude-dir=node_modules --exclude-dir=.git .

# Check for hardcoded debug flags
grep -r "DEBUG.*=.*[Tt]rue\|debug.*:.*true" --include="*.py" --include="*.js" --include="*.go" --exclude-dir=node_modules .

# Look for localhost hardcoding
grep -r "localhost\|127.0.0.1" --include="*.py" --include="*.js" --include="*.go" --exclude-dir=node_modules . | grep -v ALLOWED_HOSTS
```

### Phase 2: Package Management Modernization

**For Python projects:**

**4. Migrate to uv and pyproject.toml (ALWAYS use Context7 for current uv documentation)**

- **FIRST**: Use Context7 MCP to fetch current uv documentation and best practices
- If `Pipfile` exists: Convert to `pyproject.toml` format
- If only `requirements.txt`: Create `pyproject.toml` with dependencies
- If `poetry.lock` exists: Consider keeping Poetry or migrating to uv
- **Use `uv add` instead of `pip install` for new dependencies**
- **Use `uvx` for global tool installation instead of pipx when available**

**Generate pyproject.toml:**

```toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "{auto-detect-from-directory}"
version = "0.1.0"
description = "{auto-generate-from-readme-or-prompt}"
requires-python = ">={detect-from-existing-config}"
dependencies = [
    # Convert from existing dependency files
]

[project.optional-dependencies]
dev = [
    # Development dependencies
    "pytest>=7.0.0",
    "black>=23.0.0",
    "flake8>=6.0.0",
    "mypy>=1.0.0",
]

[tool.black]
line-length = 88
target-version = ['py39']

[tool.flake8]
max-line-length = 88
exclude = [".git", "__pycache__", "build", "dist"]

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
```

**For Node.js projects:**

**5. Modernize package management (ALWAYS use Context7 for current documentation)**

- **FIRST**: Use Context7 MCP to fetch current documentation for npm, bun, pnpm best practices
- **Prefer modern package managers**: bun > pnpm > npm
- If migrating from yarn: Remove `yarn.lock` and reinstall with chosen package manager
- **Use npx for one-off executions** of packages
- Update all documentation to reflect chosen package manager
- **Verify current best practices via Context7** before suggesting migration commands

**For other languages:**

- **Rust**: Ensure `Cargo.toml` follows current standards
- **Go**: Verify `go.mod` is properly configured
- **PHP**: Ensure `composer.json` follows current standards

### Phase 3: Security Hardening

**6. Fix hardcoded secrets and configuration**

For each detected framework:

**Django:**

```python
# Replace hardcoded secrets
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')
if not SECRET_KEY:
    if DEBUG:
        SECRET_KEY = 'dev-only-secret-key-not-for-production'
    else:
        raise ValueError("DJANGO_SECRET_KEY environment variable must be set")

# Fix ALLOWED_HOSTS
ALLOWED_HOSTS = os.environ.get('DJANGO_ALLOWED_HOSTS', 'localhost').split(',')

# Fix DEBUG setting
DEBUG = os.environ.get('DJANGO_DEBUG', 'False').lower() == 'true'
```

**Flask:**

```python
# Fix secret key
app.config['SECRET_KEY'] = os.environ.get('FLASK_SECRET_KEY') or \
    ('dev-secret-key' if app.debug else None)
if not app.config['SECRET_KEY']:
    raise ValueError("FLASK_SECRET_KEY must be set in production")
```

**Node.js/Express:**

```javascript
// Use environment variables for sensitive config
const config = {
  port: process.env.PORT || 3000,
  dbUrl: process.env.DATABASE_URL,
  secretKey: process.env.SECRET_KEY,
  nodeEnv: process.env.NODE_ENV || "development",
};

if (config.nodeEnv === "production" && !config.secretKey) {
  throw new Error("SECRET_KEY must be set in production");
}
```

**7. Database and external service configuration**

- Ensure all database credentials use environment variables
- Configure external API keys via environment variables
- Set up proper CORS configuration for web applications

### Phase 4: Infrastructure Modernization

**8. Update Dockerfile (if exists)**

**For Python applications (prefer Alpine):**

```dockerfile
FROM python:3.11-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_NO_CACHE=1 \
    UV_COMPILE_BYTECODE=1

# Install system dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libpq-dev \
    curl \
    && pip install uv

WORKDIR /app

# Install dependencies
COPY pyproject.toml ./
RUN uv pip install --system -e .

COPY . .

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health/ || exit 1

EXPOSE 8000
```

**For Node.js applications (Alpine preferred):**

```dockerfile
FROM node:18-alpine

# Install curl for health checks
RUN apk add --no-cache curl

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY . .

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000
CMD ["npm", "start"]
```

**For Go applications (Alpine preferred):**

```dockerfile
FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest
RUN apk add --no-cache ca-certificates curl
WORKDIR /root/

COPY --from=builder /app/main .

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["./main"]
```

**For Rust applications (Alpine preferred):**

```dockerfile
FROM rust:1.75-alpine AS builder

RUN apk add --no-cache musl-dev

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm src/main.rs

COPY . .
RUN cargo build --release

FROM alpine:latest
RUN apk add --no-cache ca-certificates curl
WORKDIR /app

COPY --from=builder /app/target/release/app .

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["./app"]
```

**9. Modernize docker-compose.yml**

- Remove deprecated `version` field
- Add health checks for all services
- Use environment variable substitution
- Configure proper networking and volumes

```yaml
services:
  app:
    build: .
    ports:
      - "${APP_PORT:-8000}:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - SECRET_KEY=${SECRET_KEY}
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health/"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

### Phase 5: 12-Factor App Compliance

**10. Audit and fix 12-factor violations**

For each principle, check and fix:

**I. Codebase**: Ensure single repo, environment-agnostic code
**II. Dependencies**: Verify explicit dependency declarations
**III. Config**: Move all config to environment variables
**IV. Backing Services**: Treat databases/services as attached resources
**V. Build, Release, Run**: Ensure proper separation
**VI. Processes**: Make application processes stateless
**VII. Port Binding**: Export services via port binding
**VIII. Concurrency**: Scale via process model
**IX. Disposability**: Fast startup and graceful shutdown
**X. Dev/Prod Parity**: Keep environments similar
**XI. Logs**: Treat logs as event streams
**XII. Admin Processes**: Run admin tasks as one-off processes

**11. Generate comprehensive .env.example**

Create `.env.example` with all required environment variables:

```bash
# Application Configuration
APP_NAME=your-app-name
APP_ENV=development
APP_DEBUG=false
APP_PORT=8000

# Security
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,yourdomain.com

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
# or individual components:
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_db
DB_USER=your_user
DB_PASSWORD=your_password

# External Services
REDIS_URL=redis://localhost:6379/0
# Add other service URLs as needed

# Third-party Integrations
# SENTRY_DSN=https://your-sentry-dsn
# STRIPE_SECRET_KEY=sk_test_...
# AWS_ACCESS_KEY_ID=your-key
# AWS_SECRET_ACCESS_KEY=your-secret
```

### Phase 6: Documentation Updates

**12. Update README.md**

Generate modernized README with:

- Clear project description
- Updated prerequisites (modern tool versions)
- Installation instructions using modern package managers
- Development setup instructions
- Docker setup instructions
- Testing commands
- Deployment notes

**Template:**

````markdown
# {Project Name}

{Brief description of what the application does}

## Prerequisites

- {Language} {version}+ with {modern package manager}
- {Database} {version}+
- Docker & Docker Compose (for containerized development)

## Quick Start

```bash
# Clone and setup
git clone <repo-url>
cd <project-name>
cp .env.example .env
# Edit .env with your configuration

# Docker development
docker-compose up

# OR Local development
{language-specific setup commands}
```
````

## Development

### {Backend/API}

```bash
cd {backend-dir}/
{install dependencies}
{run migrations}
{start development server}
```

### {Frontend} (if applicable)

```bash
cd {frontend-dir}/
{install dependencies}
{start development server}
```

## Testing

```bash
{test commands for each component}
```

## Deployment

See [deployment documentation](docs/deployment.md) for production setup.

````

**13. Update CLAUDE.md (if exists)**

Add modernized development commands and tool specifications:
```markdown
### Package Management
- **{Language}**: Use {modern package manager} instead of {old tools}

### Development Commands
```bash
# Updated commands for modern tools
````

### Configuration

- All configuration via environment variables
- Use .env files for local development
- Never commit secrets to repository

````

### Phase 7: Testing & Validation

**14. Verify application builds and runs**

Test the modernized application:
```bash
# Test Docker builds
docker-compose build --no-cache

# Test application startup
docker-compose up -d

# Verify health endpoints (if configured)
curl -f http://localhost:${APP_PORT}/health/ || echo "Health check endpoint not available"

# Test database connectivity
# {framework-specific database connection test}
````

**15. Run security scans**

For each technology:

- **Python**: `pip-audit` or `safety check`
- **Node.js**: `npm audit`
- **Rust**: `cargo audit`
- **Go**: `govulncheck` or `nancy`
- **Docker**: `docker scout` or `trivy`

**16. Verify dependency resolution**

Check that all dependencies install correctly:

- **Python**: `uv pip check` or `pip check`
- **Node.js**: `npm ls` and `npm doctor`
- **Rust**: `cargo check`
- **Go**: `go mod verify`

### Phase 8: GitHub Actions Workflows

**17. Set up essential GitHub Actions workflows**

Create `.github/workflows/` directory and add these essential workflows:

**CI/CD Workflow (`.github/workflows/ci.yml`):**

```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python (if Python project)
        if: ${{ hashFiles('pyproject.toml') != '' }}
        uses: actions/setup-python@v4
        with:
          python-version: "3.11"

      - name: Install uv (if Python project)
        if: ${{ hashFiles('pyproject.toml') != '' }}
        run: pip install uv

      - name: Install Python dependencies
        if: ${{ hashFiles('pyproject.toml') != '' }}
        run: uv pip install --system -e .[dev]

      - name: Set up Node.js (if Node.js project)
        if: ${{ hashFiles('package.json') != '' }}
        uses: actions/setup-node@v4
        with:
          node-version: "18"
          cache: "npm"

      - name: Install Node.js dependencies
        if: ${{ hashFiles('package.json') != '' }}
        run: npm ci

      - name: Set up Go (if Go project)
        if: ${{ hashFiles('go.mod') != '' }}
        uses: actions/setup-go@v4
        with:
          go-version: "1.21"

      - name: Set up Rust (if Rust project)
        if: ${{ hashFiles('Cargo.toml') != '' }}
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable

      - name: Run tests
        run: |
          if [ -f "pyproject.toml" ]; then
            python -m pytest
          elif [ -f "package.json" ]; then
            npm test
          elif [ -f "go.mod" ]; then
            go test ./...
          elif [ -f "Cargo.toml" ]; then
            cargo test
          fi

      - name: Run linting
        run: |
          if [ -f "pyproject.toml" ]; then
            flake8 .
            black --check .
          elif [ -f "package.json" ]; then
            npm run lint || echo "No lint script found"
          elif [ -f "go.mod" ]; then
            go vet ./...
            gofmt -d .
          elif [ -f "Cargo.toml" ]; then
            cargo clippy -- -D warnings
            cargo fmt --check
          fi

  build-and-push-image:
    runs-on: ubuntu-latest
    if: contains(fromJSON('["Dockerfile", "docker-compose.yml"]'), github.event.head_commit.modified) || github.event_name == 'push'
    needs: test
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**Release Please Workflow (`.github/workflows/release-please.yml`):**

```yaml
name: Release Please

on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
    steps:
      - uses: google-github-actions/release-please-action@v4
        id: release
        with:
          # Detect project type automatically or set specific type
          release-type: ${{
            hashFiles('pyproject.toml') != '' && 'python' ||
            hashFiles('package.json') != '' && 'node' ||
            hashFiles('Cargo.toml') != '' && 'rust' ||
            hashFiles('go.mod') != '' && 'go' ||
            'simple'
          }}

  build-release-image:
    runs-on: ubuntu-latest
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created }}
    permissions:
      contents: read
      packages: write

    env:
      REGISTRY: ghcr.io
      IMAGE_NAME: ${{ github.repository }}

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=semver,pattern={{version}},value=${{ needs.release-please.outputs.tag_name }}
          type=semver,pattern={{major}}.{{minor}},value=${{ needs.release-please.outputs.tag_name }}
          type=semver,pattern={{major}},value=${{ needs.release-please.outputs.tag_name }}

    - name: Build and push release image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

    # Optional: Deploy to staging/production
    # - name: Deploy to production
    #   run: |
    #     echo "Deploy release ${{ needs.release-please.outputs.tag_name }} to production"
    #     # Add your deployment commands here
```

**Security Scanning Workflow (`.github/workflows/security.yml`):**

```yaml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: "0 2 * * 1" # Weekly on Monday at 2 AM

jobs:
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Python security scan
        if: ${{ hashFiles('pyproject.toml') != '' }}
        run: |
          pip install pip-audit
          pip-audit

      - name: Run Node.js security scan
        if: ${{ hashFiles('package.json') != '' }}
        run: |
          npm audit

      - name: Run Rust security scan
        if: ${{ hashFiles('Cargo.toml') != '' }}
        run: |
          cargo install cargo-audit
          cargo audit

      - name: Run Trivy container scan
        uses: aquasecurity/trivy-action@master
        if: ${{ hashFiles('Dockerfile') != '' }}
        with:
          image-ref: "."
          format: "sarif"
          output: "trivy-results.sarif"

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        if: ${{ hashFiles('Dockerfile') != '' }}
        with:
          sarif_file: "trivy-results.sarif"
```

**18. Configure release-please settings**

Create `.release-please-config.json`:

```json
{
  "release-type": "simple",
  "packages": {
    ".": {}
  },
  "changelog-sections": [
    { "type": "feat", "section": "Features" },
    { "type": "fix", "section": "Bug Fixes" },
    { "type": "perf", "section": "Performance Improvements" },
    { "type": "deps", "section": "Dependencies" },
    { "type": "docs", "section": "Documentation" },
    { "type": "test", "section": "Tests" },
    { "type": "build", "section": "Build System" },
    { "type": "ci", "section": "Continuous Integration" }
  ]
}
```

For multi-language projects, create `.release-please-manifest.json`:

```json
{
  ".": "0.1.0"
}
```

### Phase 9: Development Workflow Setup

### Phase 9: Development Workflow Setup

**19. Set up base pre-commit hooks**

Create `.pre-commit-config.yaml` with the standardized base configuration:

```yaml
default_install_hook_types:
  - pre-commit
  - commit-msg

repos:
  # Essential file and format checks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: check-symlinks
      - id: check-toml
      - id: check-added-large-files

  # Conventional commit enforcement
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v4.2.0
    hooks:
      - id: conventional-pre-commit
        stages: [commit-msg]
        args: []

  # GitHub Actions workflow validation
  - repo: https://github.com/rhysd/actionlint
    rev: v1.7.7
    hooks:
      - id: actionlint

  # Secret detection
  - repo: local
    hooks:
      - id: trufflehog
        name: TruffleHog
        description: Detect secrets in your data.
        entry: bash -c 'trufflehog git file://. --since-commit HEAD --results=verified,unknown --fail --no-update'
        language: system
        stages: ["pre-commit", "pre-push"]
```

**Add language-specific hooks based on detected project type:**

**For Python projects (if pyproject.toml exists):**

```yaml
# Python formatting and linting
- repo: https://github.com/psf/black
  rev: 23.12.1
  hooks:
    - id: black
      language_version: python3

- repo: https://github.com/pycqa/flake8
  rev: 7.0.0
  hooks:
    - id: flake8
      additional_dependencies: [flake8-docstrings]
```

**For Node.js projects (if package.json exists):**

```yaml
# JavaScript/TypeScript formatting
- repo: https://github.com/pre-commit/mirrors-prettier
  rev: v4.0.0-alpha.8
  hooks:
    - id: prettier
      types_or: [javascript, jsx, ts, tsx, json, yaml, markdown]
```

**For Go projects (if go.mod exists):**

```yaml
# Go formatting and linting
- repo: https://github.com/dnephin/pre-commit-golang
  rev: v0.5.1
  hooks:
    - id: go-fmt
    - id: go-vet-mod
    - id: go-mod-tidy
```

**For Rust projects (if Cargo.toml exists):**

```yaml
# Rust formatting and linting
- repo: local
  hooks:
    - id: cargo-fmt
      name: cargo fmt
      entry: cargo fmt --
      language: system
      types: [rust]
      pass_filenames: false
    - id: cargo-clippy
      name: cargo clippy
      entry: cargo clippy -- -D warnings
      language: system
      types: [rust]
      pass_filenames: false
```

**Install and configure pre-commit:**

```bash
# Install pre-commit tool
pip install pre-commit

# Install the hooks in the repository
pre-commit install --install-hooks

# Install commit-msg hook for conventional commits
pre-commit install --hook-type commit-msg

# Test the hooks on all files (optional)
pre-commit run --all-files
```

**Document the pre-commit setup:**
Create or update documentation explaining that:

- Base hooks are standardized across all repositories
- Language-specific hooks are added automatically based on project detection
- Additional project-specific hooks can be added as needed
- All hooks must pass before commits are allowed

**20. Set up additional development automation**

If not already present, create:

- **Pre-commit hooks**: `.pre-commit-config.yaml`
- **GitHub Actions**: `.github/workflows/ci.yml`
- **Release automation**: Configure release-please
- **Dependency updates**: Configure Dependabot

**21. Generate migration summary**

Create a comprehensive report of changes made:

```markdown
# Modernization Summary for {Project Name}

## Stack Detected

- Backend: {detected technologies}
- Frontend: {detected technologies}
- Database: {detected database}
- Package Managers: {old} → {new}

## Changes Made

- [x] Migrated package management: {details}
- [x] Fixed {N} security issues
- [x] Updated Docker configuration (Alpine-based images)
- [x] Created .env.example with {N} variables
- [x] Set up standardized pre-commit hooks:
  - [x] Base hooks: file checks, conventional commits, secret detection
  - [x] Language-specific hooks: {detected languages}
  - [x] GitHub Actions validation
- [x] Set up GitHub Actions workflows:
  - [x] CI/CD pipeline with testing and container builds
  - [x] Release-please for automated releases
  - [x] Security scanning workflow
- [x] Updated documentation
- [x] Achieved {X}/12 twelve-factor compliance

## Security Fixes

- Removed {N} hardcoded secrets
- Fixed configuration management
- Updated {specific vulnerabilities}

## Dependencies Updated

- {Language}: {old version} → {new version}
- {Framework}: {old version} → {new version}

## Next Steps Recommended

- [ ] Set up CI/CD pipeline
- [ ] Configure monitoring and logging
- [ ] Plan major version upgrades:
  - {framework upgrades needed}
- [ ] Security audit with external tools

## Breaking Changes

{Any manual intervention needed}

## Generated Files

- {list of new files created}
- {list of files modified}

## Compliance Status

12-Factor App Principles:

- [x] I. Codebase: {status}
- [x] II. Dependencies: {status}
- [x] III. Config: {status}
- [x] IV. Backing services: {status}
- [x] V. Build, release, run: {status}
- [x] VI. Processes: {status}
- [x] VII. Port binding: {status}
- [x] VIII. Concurrency: {status}
- [x] IX. Disposability: {status}
- [x] X. Dev/prod parity: {status}
- [x] XI. Logs: {status}
- [x] XII. Admin processes: {status}
```

## Configuration Options

Handle these command variations:

- `/modernize` - Full modernization process
- `/modernize --phase 3` - Run specific phase only
- `/modernize --dry-run` - Show what would be changed without making changes
- `/modernize --security-only` - Focus only on security fixes
- `/modernize --audit-only` - Generate compliance report without changes
- `/modernize --interactive` - Prompt for confirmation before major changes

## Error Handling

**Unknown technology stack:**

- List detected files and ask user to specify the stack
- Provide general modernization principles
- Focus on common patterns (Docker, environment variables, etc.)

**Package manager migration failures:**

- Provide manual migration steps
- Document current state and recommended actions
- Skip to next phase if user confirms

**Security scan failures:**

- Document vulnerabilities found
- Provide upgrade paths for problematic dependencies
- Create issues for manual review

**Docker build failures:**

- Provide troubleshooting steps
- Document current configuration issues
- Offer alternative configurations

## Success Reporting

After completion, provide:

```
✅ /modernize completed successfully!

📊 Summary:
- Technology Stack: {detected stack}
- Package Manager: Modernized to {new tools}
- Docker: Updated to Alpine-based images for security and size
- Security: Fixed {N} issues, removed {N} hardcoded secrets
- Pre-commit: Standardized base hooks + language-specific additions
- GitHub Actions: Set up CI/CD, release-please, and security scanning
- 12-Factor: {X}/12 principles compliant

📋 Next Steps:
1. Review generated .env.example and configure for your environment
2. Test the modernized application and Docker builds
3. Run `pre-commit install --install-hooks` to activate all hooks
4. Test pre-commit hooks: `pre-commit run --all-files`
5. Configure GitHub repository secrets for container registry
6. Review and customize GitHub Actions workflows for your needs
7. Plan dependency upgrades: {specific recommendations}

📄 Files Generated/Modified:
- {list of key files}

⚠️  Manual Review Needed:
- {any items requiring human intervention}
```

## Integration Requirements

**Required tools:**

- Git command line access
- Docker (for containerized applications)
- Language-specific package managers
- Security scanning tools (when available)

**Repository requirements:**

- Clean git working directory or user confirmation of changes
- Write access to repository
- Ability to create and modify configuration files

**Best practices:**

- Always backup original configuration files
- Test changes incrementally
- Document all modifications
- Follow language-specific conventions
- **MANDATORY: Use Context7 MCP for current best practices documentation before ANY tool usage**
- **For all package managers (uv, npm, bun, cargo, etc.)**: Always verify current best practices via Context7
- **Never suggest package management commands without first checking Context7 documentation**
