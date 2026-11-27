---
reviewed: 2026-02-16
---

# Code Quality & Design

## Core Principles

- **YAGNI / Just Enough Design**: Implement only what's immediately necessary; refactor when requirements emerge
- **KISS**: Prefer simple, understandable solutions
- **DRY**: Extract common logic into shared functions
- **Convention over Configuration**: Follow established project patterns and conventions
- **Single Responsibility / Separation of Concerns**: Each function or module has one job; keep functions small
- **Small Interfaces**: Few parameters; a function accepts only the data it needs

## Prefer Functional Style

- **Pure Functions**: Deterministic, explicit inputs and outputs, no side effects
- **Immutability**: Create new data structures rather than modifying existing ones
- **Composition**: Build behavior from simple functions, not class hierarchies; data structures and functions over objects with methods
- **Declarative Code**: Express intent and desired outcome
- **Depend on Abstractions**: Accept functions as arguments (callbacks, strategies), so new behavior composes from existing functions

## Fail Fast (Let It Crash)

- Validate inputs early and fail immediately on invalid data, with clear error context
- Use explicit failure signals over silent continuation; log errors before failing
- Propagate errors up to the handler that can act on them; recover only with explicit logic
- Use type systems to prevent errors at compile time when possible
