# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Neovim Configuration Architecture

This is a modern Neovim configuration using Lua with a modular architecture built on lazy.nvim for plugin management.

### Core Structure

The configuration follows a clear separation of concerns:
- `init.lua` - Entry point that bootstraps lazy.nvim and loads all modules
- `lua/core/` - Core configuration modules loaded in specific order
- `lua/plugins/` - Individual plugin configurations (auto-loaded by lazy.nvim)

### Module Loading Order

Modules in `lua/core/` are loaded explicitly in this order (from init.lua):
1. `core/settings` - Vim options and settings
2. `core/functions` - Custom utility functions
3. `core/commands` - Custom commands
4. `core/autocommands` - Auto commands
5. `core/lsp` - Language Server Protocol configuration
6. `core/keymaps` - Key mappings

### Plugin Management

**lazy.nvim** automatically loads all files from `lua/plugins/`. Each plugin file returns a table defining one or more plugin specifications with lazy-loading configurations.

Key plugin categories:
- **Completion**: blink.cmp with LSP integration
- **LSP/Formatting**: Mason for LSP server installation, conform.nvim for formatting, nvim-lint for linting
  - Uses native Neovim 0.11 LSP APIs (no nvim-lspconfig needed)
  - navic/navbuddy for code navigation and breadcrumbs
  - schemastore for JSON schema validation
- **Navigation**: fzf-lua, oil.nvim, aerial.nvim
- **Git**: gitsigns, git fugitive integration
- **UI**: tokyonight theme, lualine statusline, noice.nvim
- **Testing**: neotest framework
- **Debugging**: nvim-dap with language-specific adapters
- **AI**: VectorCode integration for code search

### Common Development Commands

```vim
" Plugin management
:Lazy                    " Open lazy.nvim UI
:Lazy sync              " Update all plugins
:Lazy health            " Check plugin health

" LSP commands
:LspInfo                " Show LSP status
:LspRestart             " Restart LSP servers
:Mason                  " Open Mason UI for LSP/tool management
<leader>a               " Code actions (fastaction)

" Formatting & Linting
:ConformInfo            " Show conform.nvim formatters
<leader>fo              " Format buffer
:LintInfo               " Show nvim-lint linters

" Navigation
<leader>ff              " Find files (fzf-lua)
<leader>fg              " Live grep (fzf-lua)
<leader>fb              " Browse buffers (fzf-lua)

" Git
:Git                    " Open fugitive
:Gitsigns               " Git signs commands

" Testing
:Neotest run            " Run tests
:Neotest summary        " Test summary

" File management
:Oil                    " Open oil.nvim file manager
```

### LSP Configuration

The LSP setup uses Neovim 0.11's native `vim.lsp.config()` and `vim.lsp.enable()` APIs with capabilities automatically extended for blink.cmp completion. Language servers are installed via Mason and configured in `lua/core/lsp.lua`.

**Important**: This configuration does NOT use nvim-lspconfig or mason-lspconfig plugins. It uses Neovim's built-in LSP configuration system introduced in 0.11.

#### Requirements
- **Neovim 0.11+** is required for native LSP configuration APIs

#### Adding a New LSP Server

To add a new LSP server:
1. Install it via Mason (`:Mason`)
2. Add configuration in `lua/core/lsp.lua` using `vim.lsp.config("server_name", { ... })`
3. Enable it with `vim.lsp.enable("server_name")`

Configured LSPs include:
- terraformls - Terraform with experimental features
- jsonls - JSON with SchemaStore integration
- Additional servers can be added following the pattern above
- See commented examples in `lua/core/lsp.lua` for more server configurations

#### Troubleshooting LSP Issues

**LSP server not starting:**
1. Check if the server is installed: `:Mason`
2. Verify it's enabled in `lua/core/lsp.lua` with `vim.lsp.enable("server_name")`
3. Check LSP status: `:LspInfo`
4. Restart LSP: `:LspRestart`

**Completion not working:**
1. Verify blink.cmp is loaded: `:Lazy`
2. Check capabilities are properly extended in `lua/core/lsp.lua`
3. Ensure the LSP server supports completion

**Code actions not appearing:**
1. Verify fastaction plugin is loaded: `:Lazy`
2. Check if LSP server supports code actions: `:LspInfo`
3. Try the keymap: `<leader>a` in normal or visual mode

**Navic breadcrumbs missing:**
1. Verify nvim-navic is loaded: `:Lazy`
2. Check if LSP server supports document symbols: `:LspInfo`
3. Ensure the file type is recognized: `:set filetype?`

**General debugging:**
1. Check for errors: `:checkhealth`
2. Review LSP logs: `:LspLog`
3. Verify plugin health: `:Lazy health`

### Formatting & Linting

**conform.nvim** handles formatting with format-on-save enabled:
- Lua: stylua
- Python: isort, ruff, autopep8
- JavaScript/TypeScript: eslint_d
- JSON: prettierd
- Terraform: terraform fmt
- And more per-filetype formatters

**nvim-lint** provides linting:
- Terraform: tflint, trivy
- YAML: yamllint
- JSON: jsonlint
- Gitcommit: commitlint

### Testing Configuration

To test Neovim configuration changes:
1. Source the file: `:source %`
2. Reload specific plugin: `:Lazy reload plugin-name`
3. Check for errors: `:checkhealth`
4. Validate LSP: `:LspInfo`

### Key Architectural Decisions

1. **Lazy Loading**: Plugins are loaded on-demand to optimize startup time
2. **Modular Configuration**: Each plugin has its own file for maintainability
3. **LSP-First**: Built around Neovim's native LSP client for best performance
4. **Modern Lua**: Fully Lua-based, no VimScript dependencies
5. **Cross-Platform**: Works on macOS/Linux with platform-specific handling

### Integration with Chezmoi

This configuration is managed by chezmoi. Always edit files in the source directory (`~/.local/share/chezmoi/private_dot_config/nvim/`) rather than the target directory (`~/.config/nvim/`).

### Performance Considerations

- Plugins are lazy-loaded based on events, commands, or filetypes
- Treesitter parsers are installed on-demand
- LSP servers start only when opening relevant file types
- Heavy plugins like nvim-dap load only when debugging is initiated
