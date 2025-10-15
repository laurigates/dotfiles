# My Dotfiles

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
# Add this repository as a plugin marketplace
/plugin marketplace add laurigates/dotfiles

# Install the dotfiles toolkit plugin
/plugin install dotfiles-toolkit
```

**What you get**: 30+ specialized agents and 20+ slash commands for development, infrastructure, documentation, and more.

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

Run `./update-ai-tools.sh` or `chezmoi apply update-ai-tools.sh` to apply MCP server changes.

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
