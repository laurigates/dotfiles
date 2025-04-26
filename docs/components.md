# Dotfiles Components and Workflow Tools

This document outlines the key tools and components managed by these dotfiles and used in the development workflow.

## Core Management

-   **[chezmoi](https://www.chezmoi.io/)**: Manages the dotfiles themselves, handling installation, updates, and templating across different environments.
-   **[mise-en-place](https://mise.jdx.dev/)**: Manages versions of development tools (e.g., Node.js, Python, Go, Rust, `arduino-cli`). Ensures consistent tool versions across projects and the system. Activated automatically via shell integration.

## Shell Environment (Zsh)

-   **[Zsh](https://www.zsh.org/)**: The primary interactive shell.
    -   **[fzf](https://github.com/junegunn/fzf)**: A command-line fuzzy finder, integrated for:
        -   History search (`Ctrl+R`).
        -   Directory search/change (`Alt/Option+C`).
        -   File search (`Ctrl+T`).
        -   Command completions (potentially via `fzf-tab`).
    -   **[fzf-tab](https://github.com/Aloxaf/fzf-tab)** (Implied): Provides fzf-powered completions for various commands (e.g., `git`, `kubectl`).
    -   **[bat](https://github.com/sharkdp/bat)**: A `cat` clone with syntax highlighting, used for previewing files within `fzf`.
    -   **[zkbd](https://github.com/mattmc3/zkbd)**: Utility to configure Zsh key bindings, particularly for terminal emulators.

## Editor (Neovim)

Configuration is managed via Lua (`private_dot_config/nvim/lua/`).

-   **Core & UI:**
    -   **[Lazy.nvim](https://github.com/folke/lazy.nvim)** (Assumed): Likely used as the plugin manager (standard practice).
    -   **[Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)**: Provides advanced syntax parsing for features like highlighting, text objects, and navigation.
        -   `nvim-treesitter-textobjects`: Defines text objects based on Treesitter nodes (e.g., functions, loops).
        -   `nvim-treesitter-textsubjects`: Provides additional text subjects for selection/operation.
    -   **[Tabout](https://github.com/abecodes/tabout.nvim)**: Allows using `<Tab>` to navigate out of pairs (parentheses, brackets, etc.).
    -   **[Flash](https://github.com/folke/flash.nvim)**: Enhanced motion/search within the viewport.
    -   **[Snacks](https://github.com/folke/snacks.nvim)**: Used in conjunction with Flash for picker actions.
-   **Language Server Protocol (LSP):**
    -   **Built-in LSP Client**: Neovim's core LSP functionality.
    -   **[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)** (Implied): Standard configurations for various language servers.
    -   **[Navic](https://github.com/SmiteshP/nvim-navic)**: Displays LSP symbol context (like current function/class) in the status line or winbar.
-   **Completion & Snippets:**
    -   **[Blink](https://github.com/otavioschwanck/blink.nvim)**: Provides completion menu enhancements, including icons via `mini.icons`.
    -   **[LuaSnip](https://github.com/L3MON4D3/LuaSnip)**: Snippet engine.
-   **Formatting & Linting:**
    -   **[Conform](https://github.com/stevearc/conform.nvim)**: Manages and runs code formatters.
    -   **[nvim-lint](https://github.com/mfussenegger/nvim-lint)**: Asynchronous linting framework, running linters on events like saving.
-   **Git Integration:**
    -   **[Gitsigns](https://github.com/lewis6991/gitsigns.nvim)**: Shows Git status (added, modified, deleted lines) in the sign column and provides related actions (preview hunk, stage, reset, blame, etc.).
-   **AI / LLM Integration:**
    -   **[CodeCompanion.nvim](https://github.com/laurigates/codecompanion.nvim)** (Private Plugin): Integrates Large Language Models (LLMs) like Gemini into Neovim.
        -   **Strategies (`strategies.lua`)**: Defines different interaction modes (e.g., chat, workflow).
        -   **Tools**: Allows the LLM to invoke external commands securely:
            -   `git diff`, `git log`, `git status`, `git commit`, `git push`
            -   `arduino-cli compile`, `arduino-cli upload`, `arduino-cli monitor`
        -   **Prompts (`private_prompts/`)**: Pre-defined prompt templates and workflows (e.g., Arduino code generation).

## Terminal Utilities

-   **[ripgrep (rg)](https://github.com/BurntSushi/ripgrep)**: Fast line-oriented search tool, often used in scripts and debugging.

## Containerization (for Testing)

-   **[Docker](https://www.docker.com/) / [Podman](https://podman.io/)**: Used to build and run container images for testing the dotfiles environment in isolation.
