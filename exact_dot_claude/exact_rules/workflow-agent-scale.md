# A Workflow's Cost Is Its Agent Count — Confirm the Scale Before Fanning Out

Enforced by `hooks-plugin:workflow-scale-guard.sh` (`ask` above
`CLAUDE_HOOKS_WORKFLOW_MAX_AGENTS`, default 10). Invoke
`workflow-orchestration-plugin:workflow-scale-budget` before authoring a
`Workflow` script.

Inline invariants: state the expected agent count when proposing a workflow;
cap the fan-out where the list is produced (`.slice(0, N)`); a run large enough
to trip the gate is Lauri's call — never raise the limit to clear your own prompt.
