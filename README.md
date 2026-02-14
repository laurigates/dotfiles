# My Dotfiles

[![Smoke Test CI](https://github.com/laurigates/dotfiles/workflows/Smoke%20Test%20CI/badge.svg)](https://github.com/laurigates/dotfiles/actions/workflows/smoke.yml)
[![SBOM Generation](https://github.com/laurigates/dotfiles/workflows/SBOM%20Generation/badge.svg)](https://github.com/laurigates/dotfiles/actions/workflows/sbom.yml)
[![Link Checker](https://github.com/laurigates/dotfiles/workflows/Link%20Checker/badge.svg)](https://github.com/laurigates/dotfiles/actions/workflows/link-checker.yml)
[![Performance Benchmarks](https://github.com/laurigates/dotfiles/workflows/Performance%20Benchmarks/badge.svg)](https://github.com/laurigates/dotfiles/actions/workflows/benchmarks.yml)
[![Test Coverage](https://github.com/laurigates/dotfiles/workflows/Test%20Coverage/badge.svg)](https://github.com/laurigates/dotfiles/actions/workflows/coverage.yml)

## Overview

This repository contains my personal dotfiles, managed using [chezmoi](https://www.chezmoi.io/). It sets up my development environment, including configurations for Zsh, Neovim, Git, and various development tools. Tool versions are managed using [mise-en-place](https://mise.jdx.dev/).

## Installation

1.  **Install chezmoi:** Follow the instructions on the [chezmoi installation guide](https://www.chezmoi.io/install/).
2.  **Initialize chezmoi with this repository:**
    ```bash
    chezmoi init https://github.com/laurigates/dotfiles.git
    ```
3.  **Review the changes:** Check which files chezmoi plans to create or modify.
    ```bash
    chezmoi diff
    ```
4.  **Apply the changes:**
    ```bash
    chezmoi apply -v
    ```

## Tool Management with mise-en-place

This setup uses [mise-en-place](https://mise.jdx.dev/) (formerly `rtx`) to manage development tool versions (like Node.js, Python, Go, etc.).

- Tool versions are defined in the `.config/mise/config.toml` file (managed by chezmoi).
- After cloning or updating the dotfiles, run `mise install` in your shell to install the specified tool versions.
- `mise` automatically activates the correct tool versions when you enter a directory containing a `mise.toml` or `.tool-versions` file.

## Claude Code Plugins 🔌

This repository now includes **Claude Code plugins** for easy installation and management of AI agents and slash commands!

### Quick Start

```bash
# Add the marketplace
claude /plugin marketplace add laurigates/claude-plugins

# Install and enable all plugins via justfile
just plugins-install
just plugins-enable
```

Or install individually:
```bash
claude /plugin install git-plugin@lgates-claude-plugins
```

### Bulk Plugin Management

```bash
just plugins-install     # Install all plugins from marketplace
just plugins-enable      # Enable all installed plugins
just plugins-update      # Update all plugins to latest
just plugins-reinstall   # Full cycle: uninstall → install → enable
just plugins-list        # Show installed plugins and status
```

📖 **Full guide**: See [PLUGINS.md](./PLUGINS.md) for complete documentation.

## AI Tools & MCP Configuration

AI tools and MCP (Model Context Protocol) servers are configured through the `.chezmoidata.toml` file and automatically installed via the `update-ai-tools.sh` script.

### MCP Server Configuration

MCP servers for Claude Code are dynamically configured from `.chezmoidata.toml`. To manage servers:

- **Enable/disable servers**: Set `enabled = true/false` in the `[mcp_servers]` section
- **Add new servers**: Create a new `[mcp_servers.name]` section with required fields
- **Configure options**: `scope`, `command`, `args`, and optional `transport`

Example configuration:
```toml
[mcp_servers.my-server]
  enabled = true
  scope = "user"
  command = "npx"
  args = ["-y", "my-mcp-package"]
  transport = "stdio"  # optional
```

**Adding/updating servers** (safe during active Claude sessions):
```bash
./update-ai-tools.sh  # or: chezmoi apply update-ai-tools.sh
```

**Cleaning up disabled servers** (WARNING: disrupts active Claude sessions):
```bash
./cleanup-mcp-servers.sh  # Run only when no Claude sessions are active
```

> **Note**: `update-ai-tools.sh` only adds new servers without removing existing ones, making it safe to run during active Claude sessions. Use `cleanup-mcp-servers.sh` only when you need to remove disabled servers and no Claude Code sessions are running.

## Claude Code Configuration

### Plugins

The repository provides three Claude Code plugins via a local marketplace for instant development feedback:

```bash
# Plugins auto-load from: ~/.local/share/chezmoi/plugins/
# Check available plugins:
/plugin list
```

**Available plugins:**
- **dotfiles-core**: Essential development workflows (git, code review, testing, docs, CI/CD)
- **dotfiles-experimental**: Testing new automation features (devloop, modernization) - can disable if unstable
- **dotfiles-fvh**: Work-specific Podio integrations - disable for personal projects

**Enable/Disable in settings:**
```json
"enabledPlugins": {
  "dotfiles-core@dotfiles": true,
  "dotfiles-experimental@dotfiles": true,  // Set to false to disable
  "dotfiles-fvh@dotfiles": false           // Disabled for personal use
}
```

**Development workflow:**
```bash
# Edit plugin/skill files directly in source directory
vim ~/.local/share/chezmoi/.claude/skills/python-development/SKILL.md
vim ~/.local/share/chezmoi/plugins/dotfiles-core/commands/git/git:commit.md

# Apply changes to ~/.claude after editing
chezmoi apply -v ~/.claude  # Or use alias: ca-claude
```

**Why `exact_dot_claude/` instead of symlink?**
The `.claude` directory uses chezmoi's `exact_` prefix for atomic updates and auto-cleanup of orphaned files. This prevents race conditions with running Claude processes and ensures predictable state. Run `chezmoi apply -v ~/.claude` after editing skills or commands.

Full guide: See [PLUGINS.md](./PLUGINS.md) and [CLAUDE.md](./CLAUDE.md)

### Skills

32 auto-discovered skills provide contextual guidance:
- **Core Tools**: chezmoi-expert, shell-expert, fd-file-finding, rg-code-search, jq-json-processing, yq-yaml-processing, ast-grep-search, vectorcode-search
- **Version Control**: git-branch-pr-workflow, git-commit-workflow, git-security-checks, git-repo-detection, release-please-protection
- **GitHub Actions**: claude-code-github-workflows, github-actions-mcp-config, github-actions-auth-security, github-actions-inspection
- **Languages**: python-development, rust-development, nodejs-development, cpp-development, neovim-configuration
- **Infrastructure**: container-development, kubernetes-operations, infrastructure-terraform, embedded-systems
- **Agent/Memory**: agent-coordination-patterns, agent-file-coordination, multi-agent-workflows, graphiti-episode-storage, graphiti-learning-workflows, graphiti-memory-retrieval

Skills activate automatically based on your work context. See [CLAUDE.md](./CLAUDE.md) for the skills catalog.

## Further Documentation

## Components Overview

For a detailed breakdown of the tools and components managed by these dotfiles (like chezmoi, mise, Zsh plugins, Neovim setup, etc.), see:

- [Components and Workflow Tools](./docs/components.md)

## Further Documentation

For more specific guides, see the following documents:

- [Platform Specific Notes](./docs/platform_specific.md)
- [Container Testing](./docs/container_testing.md)
- [Debugging Guide](./docs/debugging.md)
- [Verifying Environment Setup](./docs/verifying_environment.md)
