---
paths:
  - ".claude/rules/**"
---

# Path-Scoped Rules

Rules in `.claude/rules/` load on every session by default. Use the `paths` frontmatter field to scope rules to specific file types so they only load when Claude reads matching files — reducing context noise for unrelated work.

## When to Scope

Add `paths` when a rule is only relevant for specific workflows or file types:

| Rule type | Example paths |
|-----------|--------------|
| Skill authoring | `"**/skills/**"`, `"**/SKILL.md"` |
| Agent authoring | `"**/agents/**"` |
| Test files | `"**/*.{test,spec}.{ts,tsx,js}"`, `"**/*.test.py"` |
| CI/CD | `".github/workflows/**"` |
| Shell scripts | `"**/*.sh"`, `"scripts/**"` |
| Changelogs/versions | `"**/CHANGELOG.md"`, `"**/package.json"` |
| Plugin manifests | `"**/.claude-plugin/**"` |
| Hooks config | `".claude/hooks/**"`, `".claude/settings*.json"` |
| Chezmoi templates | `"**/.chezmoidata.toml"`, `"**/*.sh.tmpl"` |

## When NOT to Scope

Keep unconditional when the rule applies to any file or context:
- Commit message conventions (needed for any git operation)
- Code quality and design principles
- Communication style
- Security principles
- Delegation and tool selection strategy

## Syntax

```yaml
---
paths:
  - "**/skills/**"
  - "**/SKILL.md"
---
```

Multiple patterns are OR-combined. Rules without `paths` load at session start. Path-scoped rules trigger when Claude reads a file matching any pattern.

Scope the rule file itself when it's only relevant for specific workflows — including this one.
