# Proactive Skill/Agent Catalog Checking

Actively consult the skills/agents catalog; don't wait to be reminded. The
failure mode: work proceeds without the skill or agent that already covers it.

## 1. Re-scan at task and topic boundaries

Check the catalog for a match at **session start**, at **every new top-level
user request**, and at a **visible topic shift** (git work gives way to Python
testing, infra debugging gives way to a macOS performance question). Not before
every trivial tool call — a Read, a one-line Edit, or a factual answer needs no
catalog pass.

## 2. Cross-reference when planning, and brief subagents explicitly

When breaking work into phases (a phase list, an `ExitPlanMode` plan, a task
list), annotate each phase with the matching skill(s)/agent(s) by name, or note
that none apply.

**When dispatching an `Agent`/`Task`/`Workflow` subagent, write the matching
skill/agent name(s) into its prompt.** A fresh subagent has no session memory
and cannot check the catalog on your behalf — "use the `python-testing` skill to
write these tests" is self-contained; "write tests" leaves it to reinvent
conventions the skill already encodes.

Keep the annotation in the plan text and subagent prompts, not as narrated
chatter before each action. Sibling: `agent-and-tool-selection.md` governs
*how* to name and model a chosen agent.
