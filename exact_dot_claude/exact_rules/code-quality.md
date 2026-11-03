# Code Quality & Design

## Core Principles

- **YAGNI**: Implement only what's immediately necessary
- **KISS**: Prefer simple, understandable solutions
- **DRY**: Extract common logic into shared functions
- **Separation of Concerns**: Keep distinct aspects of functionality in separate modules/functions
- **Convention over Configuration**: Follow established project patterns and conventions
- **Just Enough Design**: Design for current needs, refactor when requirements emerge

## Function Design

- Keep functions small and focused on a single responsibility
- Minimize function arguments (ideally few parameters)
- Prefer pure functions without side effects

## Functional Programming Principles

- **Pure Functions**: Deterministic with explicit inputs and outputs
- **Immutability**: Create new data structures rather than modifying existing ones
- **Function Composition**: Build complex behavior from simple functions
- **Declarative Code**: Express intent and desired outcome

## Functional Design Principles

- **Single Responsibility**: Each function/module has one job
- **Open for Extension**: Compose new behavior from existing functions
- **Small Interfaces**: Functions accept only the data they need — favor specific parameters
- **Depend on Abstractions**: Accept functions as arguments (callbacks, strategies) for flexible composition

## Prefer Functional Style

- Prefer functional composition over class hierarchies
- Use data structures and functions over objects with methods

## Fail Fast (Let It Crash)

- Surface failures immediately and obviously for quick root cause identification
- Use explicit failure signals over silent continuation
- Crash cleanly with clear error context

## Error Handling Guidelines

- Validate inputs early and fail immediately on invalid data
- Propagate errors up the stack to the appropriate handler
- Use type systems to prevent errors at compile time when possible
- Log errors comprehensively before failing (for observability)
- Handle errors explicitly with clear recovery logic
