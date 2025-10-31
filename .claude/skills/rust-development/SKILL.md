---
name: Rust Development
description: Modern Rust development with cargo, rustc, clippy, rustfmt, async programming, and memory-safe systems programming. Automatically assists with Rust projects, ownership patterns, and fearless concurrency.
allowed-tools: Glob, Grep, Read, Bash, Edit, Write, TodoWrite, WebFetch, WebSearch, BashOutput, KillShell
---

# Rust Development

Expert knowledge for modern systems programming with Rust, focusing on memory safety, fearless concurrency, and zero-cost abstractions.

## Core Expertise

**Modern Rust Ecosystem**
- **Cargo**: Build system, package manager, and workspace management
- **Rustc**: Compiler optimization, target management, and cross-compilation
- **Clippy**: Linting for idiomatic code and performance improvements
- **Rustfmt**: Consistent code formatting following Rust style guidelines
- **Rust-analyzer**: Advanced IDE support with LSP integration

## Key Capabilities

**Ownership & Memory Safety**
- Implement ownership patterns with borrowing and lifetimes
- Design zero-copy abstractions and efficient memory layouts
- Apply RAII patterns through Drop trait and smart pointers (Box, Rc, Arc)
- Leverage interior mutability patterns (Cell, RefCell, Mutex, RwLock)

**Async Programming & Concurrency**
- **Tokio**: Async runtime for high-performance network applications
- **async-std**: Alternative async runtime with familiar API design
- **Futures**: Composable async abstractions and stream processing
- **Rayon**: Data parallelism with work-stealing thread pools
- Design lock-free data structures with atomics and memory ordering

**Error Handling & Type Safety**
- Design comprehensive error types with thiserror and anyhow
- Implement Result<T, E> and Option<T> patterns effectively
- Use pattern matching for exhaustive error handling
- Apply type-state patterns for compile-time guarantees

**Performance Optimization**
- Profile with cargo-flamegraph, perf, and criterion benchmarks
- Optimize with SIMD intrinsics and auto-vectorization
- Implement zero-cost abstractions and inline optimizations
- Use unsafe code judiciously with proper safety documentation

**Testing & Quality Assurance**
- **Unit Testing**: #[test] modules with assertions
- **Integration Testing**: tests/ directory for end-to-end validation
- **Criterion**: Micro-benchmarking with statistical analysis
- **Miri**: Undefined behavior detection in unsafe code
- **Fuzzing**: cargo-fuzz for security and robustness testing

## Essential Commands

```bash
# Project setup
cargo new my-project
cargo init

# Development workflow
cargo build                      # Debug build
cargo build --release           # Optimized build
cargo run                       # Build and run
cargo test                      # Run tests
cargo bench                     # Run benchmarks

# Code quality
cargo clippy                    # Lint code
cargo fmt                       # Format code
cargo fix                       # Auto-fix warnings

# Advanced tools
cargo expand                    # Macro expansion
cargo flamegraph               # Profile with flame graph
cargo audit                    # Security audit
```

## Best Practices

**Idiomatic Rust Patterns**
- Use RAII for all resource management
- Apply const-correctness and constexpr where possible
- Implement move semantics and perfect forwarding
- Prefer std::unique_ptr and std::shared_ptr over raw pointers

**Project Structure**
- Organize code with modules and workspaces
- Separate library (src/lib.rs) from binary (src/main.rs)
- Use feature flags for optional dependencies
- Implement proper visibility controls

**Error Handling**
```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Parse error: {0}")]
    Parse(String),
}

type Result<T> = std::result::Result<T, AppError>;
```

For detailed async patterns, unsafe code guidelines, WebAssembly compilation, embedded development, and advanced debugging, see REFERENCE.md.
