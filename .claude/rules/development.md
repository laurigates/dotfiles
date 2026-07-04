# Development Workflow

## TDD Workflow

Follow RED → GREEN → REFACTOR:
1. Write a failing test
2. Implement minimal code to pass
3. Refactor while keeping tests green

## Commit Conventions

Use conventional commits: `type(scope): description`

Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `style`

Common scopes: `zsh`, `nvim`, `mise`, `chezmoi`, `claude`, `brew`, `scripts`

## Chezmoi Workflow

- Always edit source files in `~/.local/share/chezmoi/`, never target files directly
- Run `chezmoi diff` before `chezmoi apply` to review changes
- Use `chezmoi apply --dry-run` to preview without applying
- After modifying `exact_dot_claude/rules/`, run `chezmoi apply -v ~/.claude` to sync
