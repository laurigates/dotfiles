# ADR-0012: Justfile Command Runner

## Status

Accepted

## Date

2025-12

## Context

The dotfiles repository used a Makefile for common development tasks like applying configurations, running linters, and managing the development environment.

### Problems with Make

While Make is ubiquitous, it has several issues for this use case:

1. **`.PHONY` boilerplate**: Every non-file target requires explicit `.PHONY` declaration
2. **Tab sensitivity**: Recipes must use tabs, not spaces (common source of errors)
3. **GNU vs BSD Make**: Syntax differences between platforms cause portability issues
4. **Variable syntax**: `$(VAR)` vs `${VAR}` vs `$$VAR` confusion
5. **Color output**: Requires manual ANSI escape code definitions
6. **Poor error messages**: Cryptic errors without source context
7. **Build-system baggage**: Make is designed for builds, not command running

### Recipe Complexity Analysis

The existing Makefile had 30+ recipes across categories:

| Category | Recipes | Complexity |
|----------|---------|------------|
| Build & Development | apply, check, diff, status, verify | Simple |
| Testing | test, lint, smoke-* | Medium |
| Environment Setup | setup, setup-brew, setup-mise, setup-nvim | Medium |
| Utilities | update, bump, clean, security-audit | Complex |
| Development | dev, edit, ci | Simple |
| Information | info, help | Simple |

**Pain points observed**:
- The `lint` recipe had complex shell conditionals for tool detection
- Help generation required awk parsing of `##` comments
- Color definitions duplicated at top of file
- Recursive `$(MAKE)` calls for dependencies

### Justfile Capabilities

[just](https://github.com/casey/just) is a modern command runner that addresses these issues:

1. **No `.PHONY`**: All recipes are commands by default
2. **Indentation agnostic**: Spaces or tabs work fine
3. **Cross-platform**: Consistent behavior on Linux, macOS, Windows
4. **Built-in colors**: `{{BLUE}}`, `{{GREEN}}`, `{{YELLOW}}`, `{{RED}}`, `{{NORMAL}}`
5. **Clear errors**: Shows source context in error messages
6. **Native help**: `just --list` with automatic doc comment extraction
7. **Recipe attributes**: `[private]`, `[confirm]`, `[linux]`, `[macos]`, etc.
8. **Parameters**: Recipes can accept command-line arguments
9. **Conditionals**: `if`/`else` expressions in recipe bodies

## Decision

**Replace the Makefile with a justfile** as the project's command runner.

### Recipe Organization

```
justfile
├── Default (help)
├── Build & Development
│   ├── apply          # Apply dotfiles
│   ├── check          # Alias for status
│   ├── diff           # Show differences
│   ├── status         # Show status
│   └── verify         # Verify integrity
├── Testing
│   ├── test           # Run all tests
│   ├── lint           # Run all linters
│   ├── lint-shell     # Shell scripts only
│   ├── lint-lua       # Neovim config only
│   ├── lint-actions   # GitHub Actions only
│   ├── pre-commit     # Pre-commit hooks
│   ├── smoke          # Docker smoke test
│   └── smoke-*        # Docker variants
├── Environment Setup
│   ├── setup          # Full setup
│   ├── setup-brew     # Homebrew packages
│   ├── setup-mise     # mise tools
│   └── setup-nvim     # Neovim plugins
├── Utilities
│   ├── update         # Update all tools
│   ├── bump           # Bump versions
│   ├── clean          # Clean caches
│   └── secrets        # Scan for secrets
├── Development
│   ├── dev            # Start dev environment
│   └── edit           # Open in editor
└── Information
    ├── info           # System information
    └── doctor         # Diagnose issues
```

### Key Improvements

**1. Built-in colored output**:
```just
# Before (Makefile)
BLUE := \033[34m
RESET := \033[0m
apply:
	@echo "$(BLUE)Applying...$(RESET)"

# After (justfile)
apply:
    @echo "{{BLUE}}Applying...{{NORMAL}}"
```

**2. No `.PHONY` declarations**:
```just
# Before (Makefile)
.PHONY: apply status check diff verify

# After (justfile)
# Nothing needed - all recipes are commands
```

**3. Private recipes for internal use**:
```just
[private]
_check-tool tool:
    @command -v {{tool}} >/dev/null 2>&1
```

**4. Platform-specific recipes**:
```just
[macos]
setup-macos:
    brew install coreutils

[linux]
setup-linux:
    sudo apt install build-essential
```

**5. Recipe parameters**:
```just
# Apply specific target
apply target="":
    chezmoi apply {{target}} -v
```

### Recipes Removed

| Recipe | Reason |
|--------|--------|
| `docker` | Deprecated alias for `smoke` |
| `docs-serve` | Not implemented |
| `qa` | Redundant (same as `lint check`) |

### Recipes Added

| Recipe | Purpose |
|--------|---------|
| `lint-shell` | Run shellcheck only |
| `lint-lua` | Run luacheck only |
| `lint-actions` | Run actionlint only |
| `pre-commit` | Run pre-commit hooks |
| `secrets` | Scan for secrets with detect-secrets |
| `doctor` | Diagnose common issues |

### Recipes Modified

| Recipe | Change |
|--------|--------|
| `lint` | Now depends on individual lint-* recipes |
| `security-audit` | Renamed to `secrets`, uses detect-secrets |
| `colors` | Made private (demo/debug tool) |

## Consequences

### Positive

1. **Simpler syntax**: No Make quirks or POSIX shell restrictions
2. **Better DX**: Built-in colors, `--list` for discovery
3. **Cross-platform**: Consistent behavior everywhere
4. **Maintainable**: Easier to read and modify
5. **Extensible**: Recipe attributes enable advanced patterns
6. **Modern tooling**: Active development, good documentation

### Negative

1. **New dependency**: Requires `just` to be installed
2. **Team learning**: Contributors must learn `just` syntax
3. **Ecosystem**: Less ubiquitous than Make
4. **IDE support**: Fewer plugins than Makefile support

### Migration Path

1. **Install just**: Added to mise config (`aqua:casey/just`)
2. **Create justfile**: Converted all Makefile recipes
3. **Update docs**: CLAUDE.md references `just` commands
4. **Remove Makefile**: Deleted after verification

### Command Mapping

| Old Command | New Command |
|-------------|-------------|
| `make` | `just` |
| `make apply` | `just apply` |
| `make lint` | `just lint` |
| `make test` | `just test` |
| `make setup` | `just setup` |
| `make update` | `just update` |
| `make info` | `just info` |

## Alternatives Considered

### Keep Makefile
Continue using Make with workarounds for its limitations.

**Rejected because**: Accumulated complexity, poor error messages, cross-platform issues.

### mise Tasks
Use mise's built-in task runner (`mise run`).

**Rejected because**: Less mature than just, TOML syntax less readable for complex recipes, mise already serves tool version management role.

### Task (go-task)
Use Taskfile.yml with go-task.

**Rejected because**: YAML syntax less readable than just, less active community.

### npm scripts / package.json
Use Node.js scripts pattern.

**Rejected because**: Requires Node.js, not appropriate for non-JS projects.

### Shell Scripts
Replace with individual shell scripts.

**Rejected because**: No unified interface, harder to discover available commands.

## Related Decisions

- [ADR-0002](0002-unified-tool-version-management-mise.md): mise for tool management (just installed via mise)
- [ADR-0010](0010-tiered-test-execution.md): Test execution strategy (smoke tests in justfile)

## References

- just documentation: https://just.systems/man/en/
- just GitHub: https://github.com/casey/just
- just vs Make: https://just.systems/man/en/chapter_18.html
- Configuration: `justfile` in repository root
