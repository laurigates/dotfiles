---
allowed-tools: Bash(find:*), Bash(ls:*), Read, Write, Edit
description: Perform comprehensive code review with automated fixes
argument-hint: "[PATH]"
---

## Context

- Review path: !`echo "${1:-.}"`
- Files to review: !`find ${1:-.} -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" \) 2>/dev/null | head -20`
- Test files: !`find ${1:-.} -type f -name "*test*" 2>/dev/null | wc -l`
- Project size: !`find ${1:-.} -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" | xargs wc -l 2>/dev/null | tail -1`

## Your task

### 1. Analysis
- Use `mcp__zen-mcp-server__codereview` with Gemini Pro
- Set review type: full (or security/performance/quick as needed)
- Configure thinking mode based on complexity

### 2. Planning
- Use `mcp__zen-mcp-server__planner` for action plan
- Prioritize critical issues first
- Group related fixes together

### 3. Review Focus
- **Quality**: Naming, structure, maintainability
- **Security**: Input validation, authentication, secrets
- **Performance**: Bottlenecks, memory, optimization
- **Architecture**: SOLID principles, patterns, coupling
- **Testing**: Coverage gaps, edge cases

### 4. Fix Implementation
- Apply fixes incrementally
- Validate after each fix
- Maintain git history for rollback

### 5. Validation
- Run existing tests
- Use `mcp__zen-mcp-server__precommit` for final check
- Ensure no regressions

### 6. Report
- Summary of issues found/fixed
- Remaining manual interventions needed
- Improvement recommendations
