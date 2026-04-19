# Agent and Tool Selection

## Use Plugin-Qualified Agent IDs

When invoking `Agent` or `Task`, use the fully-qualified `plugin:agent` form
shown in the system prompt's agent list. The bare form (e.g. `security-audit`)
is only correct for agents defined at the user or project level
(`~/.claude/agents/` or `.claude/agents/`).

**Correct:**

- `agents-plugin:security-audit`
- `github-actions-plugin:github-actions-inspection`

**Incorrect (causes `Agent type 'X' not found`):**

- `security-audit`
- `github-actions-inspection`

When the agent list shows a `plugin:agent` form, always use that form. If the
expected agent is missing from the current session's agent list, prefer a
graceful fallback (different agent or direct tool use) over guessing a name.
