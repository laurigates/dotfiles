# Scheduled Work — Keeping Claude Tasks Portable

Detail for the `prefer-claude-schedulers.md` rule
(`exact_dot_claude/exact_rules/`, rendered to `~/.claude/rules/`). The rule
holds the substrate ordering; this page holds how to set a chosen task up.

## Making a Claude task survive a machine change

The schedule, folder and permission mode live in app or account state, which
no file captures. Keep everything else versioned:

- The task's `SKILL.md` is one line pointing at a `PROMPT.md` in a repo. Run the
  task with **worktree on**, so the pointer resolves against a fresh
  `origin/main`. Use permission mode **auto**, so an unattended run does not
  wait for an approval.
- Record the task ID, cron, folder, worktree and permission mode next to the
  prompt, so the task can be re-created by hand.
- The run's output goes to a durable, OS-independent sink such as a log issue,
  not to a local log file.

## Do not move a deterministic job onto an LLM for its own sake

Every Desktop or cloud run consumes subscription usage. A `just` recipe that an
agent runs and pastes unchanged costs tokens and adds nothing. A job that does
no judgment goes to GitHub Actions `schedule:`, or stays where it is. Move it to
a cloud routine or Desktop local task only when the agent also acts on the
output: triaging it, filing issues, or cleaning up what the report found.

The comparison table and per-job notes for the `~/repos` portfolio are in
`~/repos/.routines/README.md` § "Choosing a scheduler".
