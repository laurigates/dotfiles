# Delegating to Other Models — the Disagreement Is the Payload

Promoted to a skill: `agent-patterns-plugin:multi-model-delegation` auto-loads
(it sets `user-invocable: false`) when briefing several models (PAL
`chat`/`consensus` over kimi, glm, gemini, gpt) on an open design decision, or
when reconciling their split answers.

Scope: *external* models consulted for judgment. Claude subagents doing work
are covered by `agent-and-tool-selection.md` (model selection).
