---
allowed-tools: Bash(uv:*), Bash(npm:*), Bash(bun:*), Bash(cargo:*), Bash(go:*), Bash(brew:*), Read, Write
argument-hint: [package-names] [--dev] [--global]
description: Universal dependency installer that automatically detects and uses the appropriate package manager
---

## Context

- Project type: !`if [ -f package.json ]; then echo "node"; elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then echo "python"; elif [ -f Cargo.toml ]; then echo "rust"; elif [ -f go.mod ]; then echo "go"; elif [ -f Gemfile ]; then echo "ruby"; else echo "unknown"; fi`
- Package manager: !`if command -v uv >/dev/null 2>&1 && [ -f pyproject.toml ]; then echo "uv"; elif command -v bun >/dev/null 2>&1 && [ -f package.json ]; then echo "bun"; elif [ -f package-lock.json ]; then echo "npm"; elif [ -f yarn.lock ]; then echo "yarn"; elif [ -f pnpm-lock.yaml ]; then echo "pnpm"; elif [ -f Cargo.toml ]; then echo "cargo"; elif [ -f go.mod ]; then echo "go"; else echo "none"; fi`
- Lock file: !`ls -la | grep -E "(uv.lock|package-lock|yarn.lock|pnpm-lock|Cargo.lock|go.sum)" || echo "no lock file"`

## Parameters

- `$1`: Package names to install (space-separated or "all" to install from manifest)
- `$2`: --dev flag for development dependencies
- `$3`: --global flag for global installation

## Installation Execution

### Python (uv)
{{ if PACKAGE_MANAGER == "uv" }}
Install Python packages with uv:
- Install all: `uv sync`
- Add package: `uv add $1`
- Add dev dependency: `uv add --dev $1`
- Install from requirements: `uv pip install -r requirements.txt`
{{ endif }}

### Node.js (Bun)
{{ if PACKAGE_MANAGER == "bun" }}
Install Node packages with Bun:
- Install all: `bun install`
- Add package: `bun add $1`
- Add dev dependency: `bun add -d $1`
- Global install: `bun add -g $1`
{{ endif }}

### Node.js (npm)
{{ if PACKAGE_MANAGER == "npm" }}
Install Node packages with npm:
- Install all: `npm ci` (if lock exists) or `npm install`
- Add package: `npm install $1`
- Add dev dependency: `npm install -D $1`
- Global install: `npm install -g $1`
{{ endif }}

### Node.js (Yarn)
{{ if PACKAGE_MANAGER == "yarn" }}
Install Node packages with Yarn:
- Install all: `yarn install --frozen-lockfile`
- Add package: `yarn add $1`
- Add dev dependency: `yarn add -D $1`
- Global install: `yarn global add $1`
{{ endif }}

### Node.js (pnpm)
{{ if PACKAGE_MANAGER == "pnpm" }}
Install Node packages with pnpm:
- Install all: `pnpm install --frozen-lockfile`
- Add package: `pnpm add $1`
- Add dev dependency: `pnpm add -D $1`
- Global install: `pnpm add -g $1`
{{ endif }}

### Rust (Cargo)
{{ if PACKAGE_MANAGER == "cargo" }}
Install Rust packages with Cargo:
- Build dependencies: `cargo build`
- Add dependency: Edit Cargo.toml then `cargo build`
- Install binary: `cargo install $1`
{{ endif }}

### Go
{{ if PACKAGE_MANAGER == "go" }}
Install Go packages:
- Download modules: `go mod download`
- Add dependency: `go get $1`
- Install tool: `go install $1@latest`
{{ endif }}

## System Dependencies

Check for system-level dependencies:
- macOS: Use Homebrew if Brewfile exists
- Linux: Detect package manager (apt, yum, dnf, pacman)

## Lock File Management

After installation:
1. Verify lock file is updated
2. If new lock file created, remind to commit it
3. Check for security vulnerabilities

## Post-install Actions

1. Display installed packages and versions
2. Run `/lint:check` to ensure code quality
3. Run `/test:run` to verify nothing broke
4. Suggest `/git:smartcommit` if lock files changed
