# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of Claude Code command templates stored in `~/.claude/commands/`. These templates define reusable workflows and development patterns that can be invoked as slash commands in Claude Code sessions.

## Command Categories

### Development Workflows
- **`/tdd`**: Test-driven development setup with pre-commit hooks, automated documentation, unit tests, and GitHub Actions
- **`/codereview`**: Automated code review using AI with detailed planning and implementation fixes
- **`/refactor`**: Code refactoring mode focused on improving quality while preserving functionality

### Project Setup
- **`/init-project`**: Complete project initialization with standardized dev environment
  - Supports project types: `python`, `node`, `go`, `generic` (defaults to `python`)
  - Creates Makefile, Dockerfile, .gitignore, GitHub workflows, pre-commit config
  - Sets up release automation with release-please

### GitHub Integration
- **`/fix-pr`**: Pull request issue resolution
- **`/process-issues`**: GitHub issue processing workflows
- **`/quickpr`**: Rapid pull request creation

### Maintenance & Organization
- **`/chore/git-repo-maintenance`**: Repository maintenance tasks
- **`/chore/modernize`**: Codebase modernization workflows
- **`/docs/update`**: Documentation update processes

## Key Architecture Patterns

### Project Initialization Standard
The `/init-project` command creates a comprehensive development environment:
- **Build System**: Makefile with colored output and common commands (`lint`, `format`, `test`, `build`)
- **Containerization**: Multi-stage Dockerfile optimized for the project type
- **Quality Gates**: Pre-commit hooks with ruff, conventional commits, security scanning
- **Release Automation**: GitHub Actions workflow with release-please
- **Development Tools**: Configured for uv (Python), npm (Node.js), with fallbacks

### Template System
Commands use placeholder replacement:
- `{{PROJECT_TYPE}}`: Dynamic project type configuration
- `{{PROJECT_NAME}}`: Project-specific naming
- Conditional logic for language-specific tooling

### Security & Quality Standards
All project templates include:
- **Security scanning**: TruffleHog for secrets, Bandit for Python security issues
- **Code quality**: Ruff for Python linting/formatting, language-specific equivalents
- **Conventional commits**: Enforced commit message standards
- **Automated testing**: Framework setup for chosen project type

## Development Commands

### Project Initialization
```bash
# Initialize a Python project (default)
/init-project

# Initialize specific project type
/init-project python|node|go|generic
```

### Common Makefile Commands (created by init-project)
```bash
make install-hooks  # Set up pre-commit hooks
make lint           # Run linter
make format         # Auto-format code
make test           # Run test suite
make build          # Build Docker container
make clean          # Remove build artifacts
```

### Quality Assurance
- Pre-commit hooks automatically run on commits
- GitHub Actions for CI/CD with release automation
- Security scanning integrated into development workflow

## Hook Integration
The templates include Claude Code hooks configuration:
- **PostToolUse**: Automatically runs `make lint && make format && make test` after code changes
- **PreToolUse**: Executes `tdd-guard` before code modifications

## File Structure Conventions
Projects initialized follow this structure:
- `src/`: Source code directory
- `tests/`: Test files
- `Makefile`: Development commands
- `pyproject.toml`: Python project configuration
- `.pre-commit-config.yaml`: Quality gate configuration
- `.github/workflows/`: CI/CD automation
- `.claude/settings.json`: Claude Code integration settings
