# Code Quality & Design

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
- Don't add defensive fallback logic that hides bugs
- Explicit failure over implicit continuation
- Better to crash cleanly than limp along in a broken state

## Error Handling Guidelines

- Validate inputs early and fail immediately on invalid data
- Propagate errors up the stack rather than catching and hiding them
- Use type systems to prevent errors at compile time when possible
- Log errors comprehensively before failing (for observability)
- When errors must be handled, do so explicitly with clear recovery logic
