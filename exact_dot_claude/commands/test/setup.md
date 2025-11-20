---
allowed-tools: Read, Write, Edit, MultiEdit, Bash(pip install:*), Bash(npm install:*), Bash(pre-commit:*), Bash(pytest:*), Bash(npm test:*), Bash(git:*), TodoWrite, SlashCommand
description: Configure comprehensive testing infrastructure with CI/CD integration
argument-hint: [--coverage] [--ci <github|gitlab|circleci>]
---

## Context

- Package files: !`ls package.json pyproject.toml setup.py go.mod Cargo.toml`
- Test config: !`ls pytest.ini jest.config.* mocha.opts .mocharc.*`
- Pre-commit: !`ls .pre-commit-config.yaml`
- GitHub Actions: !`ls .github/workflows/`

## Your task

### 1. Pre-commit Setup
- Install pre-commit if needed: `pip install pre-commit`
- Create/update `.pre-commit-config.yaml` with language-specific hooks
- Install hooks: `pre-commit install`
- Test with: `pre-commit run --all-files`

### 2. Test Structure
- Create test directories: `tests/unit`, `tests/integration`, `tests/e2e`
- Write comprehensive tests covering:
  - Unit tests for all functions
  - Integration tests for components
  - Edge cases and error handling
- Use SlashCommand: `/test:run` to verify test execution
- Use SlashCommand: `/lint:check` to ensure test code quality

### 3. GitHub Actions
- Create `.github/workflows/tests.yml` with matrix testing
- Add coverage reporting with Codecov integration
- Configure GitHub Pages for coverage reports

### 4. Documentation
- Set up documentation generation (Sphinx/TypeDoc/godoc)
- Create `.github/workflows/docs.yml` for auto-generation
- Deploy docs to GitHub Pages

### 5. Badges
- Add test and coverage badges to README
