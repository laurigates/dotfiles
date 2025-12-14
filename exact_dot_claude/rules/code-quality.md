# Code Quality & Design

## Convention Over Configuration

- Follow established project conventions rather than inventing new patterns
- Adopt framework and language idioms—do what the ecosystem expects
- Place files where developers expect to find them
- Use standard naming conventions, directory structures, and tooling defaults
- When conventions exist, follow them; only configure when conventions don't apply

## Simplicity and Clarity

- Prioritize readability and simplicity over cleverness
- Avoid unnecessary complexity
- Use descriptive names that reveal intent
- Don't reinvent the wheel—leverage existing, proven solutions

## Function Design

- Keep functions small and focused on a single responsibility
- Minimize function arguments (ideally few parameters)
- Prefer pure functions without side effects

## Functional Programming Principles

- **Pure Functions**: Deterministic, no side effects
- **Immutability**: Avoid mutating data structures
- **Function Composition**: Build complex behavior from simple functions
- **Declarative Code**: Express what to do, not how to do it

## Avoid Object-Oriented Programming

- Prefer functional composition over class hierarchies
- Use data structures and functions over objects with methods

## Fail Fast (Let It Crash)

- Prefer fail-fast behavior over layered error handling
- Let failures surface immediately and obviously so root causes can be identified and fixed
- Avoid error swallowing or silent failures that mask problems
- Don't add defensive fallback logic that hides bugs
- Make bugs reproducible by allowing them to manifest clearly
- Explicit failure over implicit continuation
- Better to crash cleanly than limp along in a broken state

## Error Handling Guidelines

- Validate inputs early and fail immediately on invalid data
- Propagate errors up the stack rather than catching and hiding them
- Use type systems to prevent errors at compile time when possible
- Log errors comprehensively before failing (for observability)
- Avoid generic catch-all error handlers that obscure root causes
- When errors must be handled, do so explicitly with clear recovery logic

## Boy Scout Rule

- Leave code cleaner than you found it
- Fix small issues when encountered, even if unrelated to current task
