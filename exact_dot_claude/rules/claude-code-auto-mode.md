# Claude Code Auto Mode & Permission Rules

**Scope**: writing or editing `permissions` / `autoMode` in any Claude Code
`settings.json` — user (`~/.claude/`), project (`.claude/`), or the chezmoi
`modify_settings.json` overlay. Especially relevant when
`permissions.defaultMode` is `"auto"`.

## Two gates, evaluated in order

Auto mode runs **two** independent checks:

1. **Permission rules** (`permissions.allow` / `ask` / `deny`, tool-pattern
   based) — resolve first.
2. **The classifier** (a separate model, configured by the `autoMode` block,
   prose based) — reviews whatever the rules didn't resolve.

Decision order, first match wins: allow/deny rules → read-only and
working-directory edits auto-approved → everything else to the classifier.
Writes to protected paths always route to the classifier even when an allow
rule matches.

## Broad allow rules are DROPPED on entry to auto mode

The easy mistake. On entering auto mode, allow rules that grant **arbitrary
code execution are stripped**:

- `Bash(*)`, `PowerShell(*)`
- wildcarded interpreters like `Bash(python*)` / `Bash(python3:*)`
- package-manager run commands (`npm run *`)
- `Agent(*)`

Narrow rules like `Bash(npm test)` or `Bash(git add *)` carry over and skip
the classifier round-trip. **So prefer narrow, scoped allow rules**
(`Bash(git add *)`, `Bash(gh pr *)`) over broad `Bash(git:*)`. The broad form
gives no benefit under auto mode (it is stripped) and reduces classifier
oversight in the non-auto modes. Under auto mode the allow-list's only job is
skipping the classifier on safe, high-frequency commands — which wants narrow
entries.

## `deny` is a hard backstop

`permissions.deny` resolves before the classifier and cannot be overridden in
any mode except `bypassPermissions`. Keep dangerous ops in `deny`
(`git push --force *`, `git add -A`, `kubectl config use-context *`,
`Write(**/CHANGELOG.md)`).

## The `autoMode` block is the real lever

Separate from `permissions`; user-settable in `~/.claude/settings.json` (it is
**not** read from project `.claude/settings.json`, so a repo can't grant itself
trust). Four prose-list fields:

| Field | Purpose |
|---|---|
| `environment` | Trusted infra (repos, buckets, domains). Default trusts only the working repo + its remotes; everything else is "external". |
| `allow` | Exceptions that override `soft_deny`. |
| `soft_deny` | Destructive actions; explicit user intent or a matching `allow` can clear them. |
| `hard_deny` | Unconditional boundaries; nothing overrides, not even explicit intent. |

Precedence inside the classifier: `hard_deny` > `soft_deny` > `allow`-exception
> explicit-user-intent. A general request ("clean up the repo") is not explicit
intent; naming the exact action ("force-push this branch") is.

- **Always include the literal `"$defaults"`** in each list you set — omitting
  it REPLACES the entire built-in list for that section. A `soft_deny` without
  `$defaults` silently discards force-push / `curl|bash` / prod-deploy
  protection; a `hard_deny` without it discards the data-exfiltration and
  auto-mode-bypass rules.
- Inspect with `claude auto-mode defaults` (built-ins), `claude auto-mode
  config` (effective config, `$defaults` expanded), and `claude auto-mode
  critique` (AI review of your custom prose — surfaces ambiguity and
  over-block risk).
- The classifier also reads CLAUDE.md, so behavioral boundaries there
  ("never force push", "never deploy to prod without approval") steer it too.
- Custom rules should name destinations relative to `environment`, default
  ambiguous targets to the safe side (e.g. unknown namespace ⇒ production), and
  not re-state "in-boundary" language so broadly that it reads as clearing the
  default exfiltration / credential-leak / destruction rules.

## `defaultMode: "auto"` placement & requirements

`defaultMode: "auto"` is **ignored** in project/local `.claude/settings*.json`
(v2.1.142+) so a repo cannot grant itself auto mode — set it in
`~/.claude/settings.json`. Requires Opus 4.6+ / Sonnet 4.6+ on the Anthropic
API (Opus 4.7+/4.8 on Bedrock/Vertex/Foundry, which also need
`CLAUDE_CODE_ENABLE_AUTO_MODE=1`).

## Ref

- <https://code.claude.com/docs/en/permission-modes.md>
- <https://code.claude.com/docs/en/permissions.md>
- <https://code.claude.com/docs/en/auto-mode-config.md>
