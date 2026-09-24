# Tool Use Patterns

Promoted to skills — invoke the one matching the moment:

- `agent-patterns-plugin:harness-tool-errors` when Read or Edit/Write errors —
  missing path, EISDIR, >25k tokens, not-read-yet, modified-since-read.
- `code-quality-plugin:ast-grep-search` before finding references to a code
  symbol — the LSP → ast-grep → rg ladder.
- `git-plugin:gh-cli-agentic` when `gh api` rejects a value's type (`-f` sends
  strings, `-F` typed literals).
- `documentation-plugin:docs-fetch-fallbacks` when a WebFetch returns 404, 403,
  or a timeout — do not retry the same failing URL.
- `agent-patterns-plugin:tool-result-traps` when an empty or negative result is
  about to gate an action or be reported as done.

## Before editing

Prefer the smallest unique `Edit` over rewriting a file with `Write`, and pass
absolute paths in agent prompts (agent threads do not keep their cwd).

## Bash permission denials are terminal

When a Bash call returns "Permission to use Bash has been denied", the denial is
**final for that command**. Do not retry with cosmetic variations (different
quoting, prepended `env`, etc.). Use the alternative tool the denial suggests,
or hand the exact command to the user as `! <cmd>`.

## Control-test negatives

**Control-test any negative that gates an action** — re-run the same command
shape against a term you know is present. If the control is also empty, the
tool is broken, not the tree clean. The control must exercise the part of the
pattern that can fail; when a negative matters, confirm it with the other tool
(`git grep -E` and `rg` disagree on some regex).
