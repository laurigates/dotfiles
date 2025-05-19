## Software engineering guidelines

- Human-Centered Design
- Discoverability
- Don't reinvent the wheel
- Readability and simplicity are paramount. Avoid complexity.
- Use descriptive names to reveal intent.
- Functions should be small, focused, and ideally take few arguments.
- Minimize comments; prioritize self-explanatory code.
- Handle errors with exceptions for robustness.
- Secure the code against vulnerabilities.
- Follow Functional Programming principles: Pure Functions, Immutability, Function Composition, Declarative Code.
- Avoid Object-Oriented Programming.
- Adhere to Twelve-Factor App methodology.
- Embrace:
  - YAGNI (Implement only what's necessary).
  - KISS (Keep It Simple, Stupid).
  - DRY (Don't Repeat Yourself).
  - SOC (Separation of Concerns).
  - Fail Fast (Early error detection).
  - Convention over Configuration.
  - JEDI (Just Enough Design Initially).
- Practice TDD (Test-Driven Development). Run tests after changes.

## Language specific guidelines

### Rust

Use `cargo run --message-format=short` when running rust code
