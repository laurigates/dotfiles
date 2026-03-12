# CLAUDE.md - Neovim Configuration

Modern Neovim configuration using Lua with lazy.nvim plugin management.

## Core Structure

- `init.lua` — Entry point; bootstraps lazy.nvim and loads core modules
- `lua/core/` — Core modules loaded in explicit order
- `lua/exact_plugins/` — Plugin specs auto-loaded by lazy.nvim (`exact_` for chezmoi orphan cleanup)

### Module Loading Order (from init.lua)

1. `core/settings` — Vim options
2. `core/functions` — Utility functions
3. `core/commands` — Custom commands
4. `core/autocommands` — Autocommands
5. `core/lsp` — LSP configuration
6. `core/keymaps` — Key mappings

## Plugin Categories

- **Completion**: blink.cmp with LSP
- **LSP/Formatting**: Mason (installs), conform.nvim (format), nvim-lint (lint), navic/navbuddy (navigation)
- **Navigation**: fzf-lua, oil.nvim, aerial.nvim
- **Git**: gitsigns, fugitive
- **UI**: tokyonight, lualine, noice.nvim
- **Testing**: neotest
- **Debugging**: nvim-dap
- **AI**: VectorCode

## LSP Approach

Uses **native Neovim 0.11 APIs** (`vim.lsp.config()` / `vim.lsp.enable()`). Does NOT use nvim-lspconfig or mason-lspconfig. Requires Neovim 0.11+.

### Adding a New LSP Server

1. Install via `:Mason`
2. Configure in `lua/core/lsp.lua`: `vim.lsp.config("server_name", { ... })`
3. Enable: `vim.lsp.enable("server_name")`

See existing examples and commented configs in `lua/core/lsp.lua`.

## Chezmoi Integration

Always edit in source directory (`~/.local/share/chezmoi/private_dot_config/nvim/`), not `~/.config/nvim/`. The plugins directory uses `exact_plugins/` prefix so chezmoi removes deleted plugin files automatically.
