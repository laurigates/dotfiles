# Front-Load Executive Decisions

When a task will run long enough that a mid-run question would stall it — a
multi-step workflow, a plan-mode design, a parallel-agent dispatch, an
autonomous session — identify every decision that is genuinely Lauri's to
make and ask them **all at the start, in one batch**, before work begins.
One question round at time zero buys an uninterrupted run to completion.

This is "ask *earlier*", never "ask *more*": the total number of questions
should go down, because mid-run stalls and post-hoc rework disappear.

## What counts as an executive decision

Only decisions that are genuinely the user's:

- **Irreversible or outward-facing actions** — deletes, force-pushes,
  publishing, sending content to external services
- **Scope and cost trade-offs** — minimal fix vs. broader refactor, one PR
  vs. several, token/time budget for a long sweep
- **Taste and preference calls** — naming, UX, formatting choices with no
  conventional default
- **Ambiguous requirements** — where two readings of the request lead to
  materially different work

Never front-load (or ask at all):

- **Choices with a conventional default** — pick it, state it in the
  response, and proceed
- **Anything already answered by `decision-defaults.md`** — the standing
  defaults exist precisely so these are not re-asked
- **Facts verifiable from the codebase, docs, or tools** — go look instead
  of asking

## Protocol

1. **Scan the task for decision points before starting work.** In plan mode
   this is the documented moment — clarify requirements and choose between
   approaches *before* finalizing the plan, not after presenting it.
2. **Filter against `decision-defaults.md`.** A covered decision is settled;
   drop it from the ask list.
3. **Batch the survivors into one `AskUserQuestion` call** (multiple
   questions per call; `multiSelect` where options aren't exclusive). Follow
   the actor-label convention from `communication.md` — `Claude` / `Lauri`,
   never "I" / "you".
4. **Run to completion.** With the answers in hand, execute without pausing
   for confirmation. Mid-run asks are reserved for genuinely unforeseeable
   blockers; if the terminal is likely unattended, that's `telegram-ask` per
   `telegram-communication.md` (fail closed on timeout).
5. **Brief the answers into subagents.** A dispatched agent cannot re-ask
   the user — write the relevant decisions into its prompt, the same way
   matched skills are briefed per `skill-and-agent-catalog-check.md`.

## Feedback loop

When the same question gets front-loaded across multiple sessions, promote
the answer into `decision-defaults.md` (its "Adding New Defaults" section
invites this) so it stops being asked at all. Front-loading is for *novel*
decisions; *recurring* ones become standing defaults.

## Rationale

A question asked mid-workflow blocks everything behind it — and in an
unattended session it can block for hours, or worse, tempt a guess at a
decision that wasn't Claude's to make. The decision points of most tasks are
visible at kickoff with a minute of thought; surfacing them there converts
"start, stall, ask, resume" into "ask once, run clean". This is the
complement of `decision-defaults.md`: defaults eliminate the recurring
questions, front-loading batches the novel ones, and together they keep the
execution phase question-free.
