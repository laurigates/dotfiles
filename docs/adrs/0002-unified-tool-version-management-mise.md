# ADR-0002: Unified Tool Version Management with Mise

## Status

Accepted (Migration In Progress)

## Date

2024-12 (retroactively documented 2025-12)

## Context

The dotfiles repository manages a complex development environment spanning multiple languages and tool ecosystems:

### The Tool Sprawl Problem

**Before mise**, tools were managed by multiple package managers:

| Tool Type | Package Manager | Config Location |
|-----------|-----------------|-----------------|
| System utilities | Homebrew | `Brewfile` |
| Python runtimes | Homebrew | `Brewfile` |
| Python CLI tools | uv (pipx-style) | `.chezmoidata.toml` |
| Node.js runtime | nvm/Homebrew | Various |
| Rust tools | cargo | `dot_default-cargo-packages` |
| Go tools | go install | Manual |
| Kubernetes tools | Homebrew | `Brewfile` |

**Problems with multi-manager approach:**

1. **Version inconsistency**: `brew install kubectl` on different days = different versions
2. **No lockfile**: No way to pin exact tool versions across machines
3. **Slow installations**: `cargo install bat` compiles from source (5+ minutes)
4. **Context switching**: Different commands for different tool types
5. **CI/local drift**: CI might use different tool versions than local
6. **Security gaps**: Homebrew only provides SHA256 checksums

### Tool Categories Analysis

We identified distinct tool categories with different requirements:

**Bootstrap Tools** (must exist before anything else):
- chezmoi, git, fish, mise itself

**Language Runtimes** (need version switching per-project):
- Python 3.11/3.13, Node.js, Go, Rust, Bun

**Python CLI Tools** (Python-based utilities):
- ruff, ansible, pre-commit, glances, etc.

**System CLI Tools** (standalone binaries):
- kubectl, helm, terraform, ripgrep, fd, bat, jq, etc.

**GUI Applications** (macOS/Linux desktop apps):
- Ghostty, Obsidian, VS Code (Homebrew casks)

**Services/Daemons** (background processes):
- PostgreSQL, Mosquitto, Ollama

### Mise Capabilities

[mise](https://mise.jdx.dev/) (formerly rtx) provides:

1. **Unified interface**: Single command for all tool types
2. **Multiple backends**:
   - Core: Language runtimes (python, node, go, rust)
   - `pipx:`: Python tools via uvx (fast!)
   - `aqua:`: CLI tools with security attestations
   - `npm:`, `cargo:`: Ecosystem-specific tools
3. **Lockfile**: `mise.lock` for reproducible builds
4. **Per-directory versions**: Auto-switch based on `.mise.toml`
5. **Task runner**: Replace Makefile with cross-platform tasks
6. **Security**: aqua backend provides checksums + SLSA provenance + Cosign signatures

## Decision

**Adopt mise as the primary tool version manager** while keeping Homebrew for bootstrap tools, GUI apps, and services.

### Tool Distribution Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    Tool Management Strategy                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Homebrew (Brewfile)           mise (config.toml.tmpl)       │
│  ─────────────────────         ────────────────────────       │
│  • Bootstrap: chezmoi,         • Runtimes: python, node,     │
│    git, fish, uv, mise           go, rust, bun               │
│  • GUI Apps: casks             • Python tools: pipx:ruff,    │
│  • Services: postgresql,         pipx:ansible, etc.          │
│    mosquitto                   • CLI tools: aqua:kubectl,    │
│  • Platform-specific:            aqua:helm, aqua:terraform   │
│    lldpd, mas                  • Search: aqua:ripgrep,       │
│  • Build tools: cmake,           aqua:fd, aqua:bat           │
│    ninja, autoconf             • Git tools: aqua:lazygit,    │
│                                  aqua:gh, aqua:delta         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Configuration Structure

**Primary config**: `private_dot_config/mise/config.toml.tmpl`

```toml
# Runtimes
[tools]
python = ["3.11", "3.13"]
node = "latest"
go = "1.23"
rust = "stable"
bun = "latest"

# Python tools (uses uvx automatically when uv installed)
"pipx:ruff" = "latest"
"pipx:ansible" = "latest"
"pipx:pre-commit" = "latest"

# CLI tools with security verification
"aqua:kubernetes/kubectl" = "latest"
"aqua:helm/helm" = "latest"
"aqua:hashicorp/terraform" = "latest"
"aqua:BurntSushi/ripgrep" = "latest"
```

### Backend Selection Criteria

| Backend | Use When | Security |
|---------|----------|----------|
| Core | Language runtimes | Standard |
| `pipx:` | Python CLI tools | Via uv |
| `aqua:` | Standalone binaries | Checksums + SLSA + Cosign |
| `npm:` | Node.js tools | Via npm |
| `cargo:` | Must compile from source | Standard |

### Task Runner Migration

Replace Makefile with mise tasks:

```toml
[tasks.lint]
description = "Run all linters"
run = "shellcheck **/*.sh && luacheck nvim/lua && actionlint"

[tasks.update]
description = "Update all tools"
depends = ["update:brew", "update:mise", "update:nvim"]
```

**Command mapping**:
- `make lint` → `mise run lint`
- `make update` → `mise run update`
- `make setup` → `mise run setup`

## Consequences

### Positive

1. **Reproducible environments**: `mise.lock` ensures identical versions
2. **Faster installations**: aqua uses pre-built binaries (seconds vs minutes)
3. **Enhanced security**: aqua provides SLSA provenance and attestations
4. **Automatic version switching**: Per-project `.mise.toml` files
5. **Unified interface**: Single tool for runtimes + CLI tools + tasks
6. **Cross-platform tasks**: TOML-based tasks work on macOS/Linux/Windows

### Negative

1. **Migration complexity**: Gradual transition from existing tools
2. **Learning curve**: Team must learn mise commands
3. **Dual management**: Homebrew still needed for some categories
4. **Trust requirement**: Must trust `.mise.toml` files in new directories

### Migration Path

**Phase 1** (Complete): Create mise config alongside existing tools
**Phase 2** (In Progress): Install tools via mise, verify functionality
**Phase 3** (Planned): Remove duplicates from Homebrew
**Phase 4** (Future): Deprecate legacy tool configs

### Packages Migrated to mise

| Category | Count | Examples |
|----------|-------|----------|
| Python tools | 18 | ruff, ansible, pre-commit |
| Kubernetes | 6 | kubectl, helm, argocd, k9s |
| Search tools | 5 | ripgrep, fd, bat, lsd, delta |
| Infrastructure | 2 | terraform, skaffold |
| Data processing | 2 | jq, yq |
| Other CLI | 4 | gh, lazygit, zoxide, atuin |

**Total**: ~37 tools migrated from Homebrew/cargo/manual

### Packages Remaining in Homebrew

- **Bootstrap**: chezmoi, git, fish, uv, mise
- **Build tools**: cmake, ninja, autoconf
- **GUI apps**: All casks
- **Services**: postgresql, mosquitto, ollama
- **Platform-specific**: lldpd (macOS), mas (macOS)
- **Specialized**: arduino-cli, platformio, wireshark

## Alternatives Considered

### asdf
The original polyglot version manager.

**Rejected because**: Slower than mise, less active development, no built-in task runner.

### nix/home-manager
Declarative system configuration.

**Rejected because**: Steeper learning curve, overkill for tool versions, less portable.

### Keep Multi-Manager Approach
Continue with Homebrew + uv + cargo + manual.

**Rejected because**: No reproducibility, version drift, slow installations.

### devbox
Nix-based development environments.

**Rejected because**: Requires Nix understanding, less flexible backends.

## Related Decisions

- ADR-0001: Chezmoi exact_ Directory Strategy (shared philosophy of explicit state)
- Homebrew for bootstrap tools (mise depends on Homebrew-installed mise)

## References

- mise documentation: https://mise.jdx.dev/
- aqua registry: https://github.com/aquaproj/aqua-registry
- Migration guide: `docs/mise-migration-guide.md`
- Analysis: `docs/homebrew-mise-migration-analysis.md`
- Configuration: `private_dot_config/mise/config.toml.tmpl`
