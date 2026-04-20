# Decision Defaults

Explicit defaults for common decisions. When you approve an approach with "go" or similar affirmation, Claude executes confidently using the approach already presented—no second-guessing or re-asking for confirmation.

## PR Strategy

When committing changes with "go" (no specific instruction):

- **Two separate PRs** — distinct concerns get separate PRs
- **Preserve existing patterns** — maintain vars/secrets split, configuration conventions
- **Pass secrets through unchanged** — don't modify secret handling or token patterns
- Rationale: Easier review, clearer intent, maintains consistency

## Refactoring

When approving a refactoring suggestion:

- **Minimal scope** — only the changes proposed, no additional improvements
- **No surrounding cleanup** — don't extract new abstractions or reorganize unrelated code
- **Preserve behavior** — focus on readability/structure, not adding features

## Architecture

When approving an architectural approach:

- **Execute as proposed** — use the approach already presented
- **Surface constraints as they emerge** — adjust if new information appears, don't pre-optimize
- **No additional abstractions** — implement what's needed, not for hypothetical future requirements

## Bug Fixes

When approving a targeted fix:

- **Fix the specific issue** — don't refactor surrounding code
- **No preventative changes** — additional error handling only at system boundaries
- **Minimal diff** — clearest demonstration that the bug is fixed

## Adding New Defaults

When a decision pattern repeats across multiple sessions, propose a new default entry here. Document:
- **Context** — what type of decision
- **Default behavior** — what "go" means
- **Rationale** — why this reduces friction
