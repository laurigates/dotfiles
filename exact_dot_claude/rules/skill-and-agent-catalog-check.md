# Proactive Skill/Agent Catalog Checking

Treat the available skills/agents catalog as something to actively consult,
not passively wait to be reminded about. Two distinct habits, both aimed at
the same failure mode: work proceeding without the specialized skill or
agent that already covers it, either because Claude didn't check, or because
a dispatched subagent had no way to know.

## 1. Re-scan at task and topic boundaries

Check the catalog for a match at:

- **Session start**, before diving into the first substantive request.
- **Every new top-level user request**, even mid-session.
- **A visible topic shift** within a session — e.g. git work gives way to
  Python testing, or infrastructure debugging gives way to a macOS
  performance question.

This does **not** mean re-checking before every trivial tool call or
single-step ask — a Read, a one-line Edit, answering a factual question
needs no catalog pass. Scope this to "new task or topic shift," the same
trivial/non-trivial split `plan-mode.md` already draws for when to plan at
all.

This is a habit to internalize, not a restatement of the Skill tool's own
blocking-requirement instructions — those already govern the mechanics of
invoking a matched skill. This rule is about remembering to look.

## 2. Cross-reference the catalog when planning, and brief subagents explicitly

When breaking work into phases — a `TodoWrite`/`TaskCreate` list, or an
`ExitPlanMode` plan — walk the phase list against the skill/agent catalog
and annotate each phase with the matching skill(s)/agent(s) by name, or
note explicitly that none apply. This turns "check the catalog" from a
vague intention into a concrete line in the plan artifact itself.

**When dispatching an `Agent`/`Task`/`Workflow` subagent, write the matching
skill/agent name(s) directly into the subagent's prompt.** A freshly spawned
subagent has no memory of this session and no way to know a skill exists
unless told — it cannot "proactively check the catalog" the way the main
loop can, because the catalog-checking habit above is a main-loop practice,
not something a subagent inherits. This is the same principle as "never
delegate understanding": a prompt that says "use the `python-testing` skill
to write these tests" is self-contained; a prompt that just says "write
tests" leaves the subagent to reinvent pytest fixture conventions the skill
already encodes.

The concrete failure this prevents: an unbriefed subagent reinvents logic a
skill already encodes — wasted tokens, inconsistent output, and established
conventions (from `configure-*`, `git-plugin:*`, language-specific skills,
etc.) silently missed.

## Scoping guards

- Don't preface trivial single-tool actions with catalog-checking commentary
  — this applies to non-trivial or multi-step work only.
- The annotation belongs in the plan/phase text and in subagent prompts
  themselves, not as extra narrated chatter to the user before each action.

## Relationship to sibling rules

- `agent-and-tool-selection.md` — governs *how* to name and model a chosen
  agent (plugin-qualified IDs, always-Opus). This rule governs *whether and
  which* skill or agent applies to a piece of work in the first place.
- `plan-mode.md` — governs *when* to enter plan mode. This rule governs what
  a good plan or phase list should contain once you're building one: an
  explicit skill/agent cross-reference per phase.

## Rationale

The catalog is large enough that "just remember" doesn't hold up across a
long session or a multi-phase plan — the failure is invisible until a
subagent's output reveals it reinvented something a skill already solved.
Scanning at task/topic boundaries catches the main loop's own blind spots;
writing skill names into subagent prompts closes the harder gap, since a
subagent has no session history to scan in the first place.
