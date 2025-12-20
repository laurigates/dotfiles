# Neovim configuration
# Extrapolated from dotfiles: private_dot_config/nvim/

{ config, pkgs, lib, inputs, ... }:

{
  programs.neovim = {
    enable = true;
    # Use nightly overlay for latest features
    package = pkgs.neovim;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Extra packages available to Neovim
    extraPackages = with pkgs; [
      # Clipboard support
      xclip
      wl-clipboard

      # Telescope dependencies
      ripgrep
      fd

      # Treesitter compilation
      gcc
      tree-sitter

      # Language servers (from dotfiles LSP config)
      nil                    # Nix
      lua-language-server   # Lua
      pyright               # Python
      ruff                   # Python linter
      rust-analyzer         # Rust
      gopls                  # Go
      terraform-ls          # Terraform
      nodePackages.typescript-language-server  # TypeScript
      nodePackages.vscode-langservers-extracted  # JSON, HTML, CSS
      yaml-language-server  # YAML
      marksman              # Markdown
      taplo                  # TOML
      sqls                   # SQL
      arduino-language-server  # Arduino

      # Formatters (from conform.nvim config)
      stylua                # Lua
      nixpkgs-fmt           # Nix
      nodePackages.prettier # JS/TS/JSON/etc
      prettierd             # Prettier daemon
      shfmt                  # Shell
      ruff                   # Python
      black                  # Python
      isort                  # Python imports
      gofumpt               # Go
      golines               # Go line length
      rustfmt               # Rust

      # Linters (from nvim-lint config)
      shellcheck            # Shell
      hadolint              # Dockerfile
      yamllint              # YAML
      actionlint            # GitHub Actions
      tflint                 # Terraform
      trivy                  # Security scanning

      # Debug adapters (from nvim-dap config)
      delve                  # Go
      lldb                   # C/C++/Rust

      # Other tools
      gnumake               # For Makefile support
      cmake                  # CMake
    ];

    # Python provider
    withPython3 = true;
    extraPython3Packages = ps: with ps; [
      pynvim
      debugpy  # Python debugging
    ];

    # Node provider (for some plugins)
    withNodeJs = true;
  };

  # Neovim configuration files
  # Option 1: Link existing config (recommended if using chezmoi)
  # xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
  #   "${config.home.homeDirectory}/.local/share/chezmoi/private_dot_config/nvim";

  # Option 2: Define minimal config in Nix (bootstrap for lazy.nvim)
  xdg.configFile."nvim/init.lua".text = ''
    -- Bootstrap lazy.nvim
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
      })
    end
    vim.opt.rtp:prepend(lazypath)

    -- Leader key (before lazy)
    vim.g.mapleader = " "
    vim.g.maplocalleader = "\\"

    -- Core settings (from dotfiles)
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.mouse = "a"
    vim.opt.clipboard = "unnamedplus"
    vim.opt.breakindent = true
    vim.opt.undofile = true
    vim.opt.ignorecase = true
    vim.opt.smartcase = true
    vim.opt.signcolumn = "yes"
    vim.opt.updatetime = 250
    vim.opt.timeoutlen = 300
    vim.opt.splitright = true
    vim.opt.splitbelow = true
    vim.opt.inccommand = "split"
    vim.opt.cursorline = true
    vim.opt.scrolloff = 10
    vim.opt.hlsearch = true
    vim.opt.termguicolors = true
    vim.opt.showmode = false

    -- Indentation
    vim.opt.expandtab = true
    vim.opt.shiftwidth = 2
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.smartindent = true

    -- Whitespace display
    vim.opt.list = true
    vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

    -- Key mappings
    vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
    vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Quickfix list" })
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

    -- Window navigation
    vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Focus left window" })
    vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Focus right window" })
    vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Focus lower window" })
    vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Focus upper window" })

    -- Load lazy.nvim with plugins
    require("lazy").setup({
      -- Colorscheme (TokyoNight from dotfiles)
      {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = { style = "night" },
        config = function(_, opts)
          require("tokyonight").setup(opts)
          vim.cmd.colorscheme("tokyonight-night")
        end,
      },

      -- Treesitter
      {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        opts = {
          ensure_installed = {
            "bash", "c", "cpp", "css", "dockerfile", "fish", "go", "html",
            "javascript", "json", "lua", "luadoc", "markdown", "markdown_inline",
            "nix", "python", "query", "regex", "rust", "sql", "terraform",
            "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
          },
          auto_install = true,
          highlight = { enable = true },
          indent = { enable = true },
        },
        config = function(_, opts)
          require("nvim-treesitter.configs").setup(opts)
        end,
      },

      -- Fuzzy finder (from dotfiles: fzf-lua)
      {
        "ibhagwan/fzf-lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = { "telescope" },
        keys = {
          { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
          { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
          { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
          { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help tags" },
          { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
          { "<leader>fc", "<cmd>FzfLua commands<cr>", desc = "Commands" },
          { "<leader>/", "<cmd>FzfLua grep_curbuf<cr>", desc = "Search in buffer" },
        },
      },

      -- File explorer (from dotfiles: oil.nvim)
      {
        "stevearc/oil.nvim",
        opts = {
          view_options = { show_hidden = true },
        },
        keys = {
          { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
        },
      },

      -- Git signs (from dotfiles)
      {
        "lewis6991/gitsigns.nvim",
        opts = {
          signs = {
            add = { text = "+" },
            change = { text = "~" },
            delete = { text = "_" },
            topdelete = { text = "‾" },
            changedelete = { text = "~" },
          },
          on_attach = function(bufnr)
            local gs = require("gitsigns")
            local function map(mode, l, r, opts)
              opts = opts or {}
              opts.buffer = bufnr
              vim.keymap.set(mode, l, r, opts)
            end
            map("n", "]h", gs.next_hunk, { desc = "Next hunk" })
            map("n", "[h", gs.prev_hunk, { desc = "Prev hunk" })
            map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
            map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
            map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
            map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, { desc = "Blame line" })
          end,
        },
      },

      -- LSP (native LSP with blink.cmp from dotfiles)
      {
        "saghen/blink.cmp",
        version = "1.*",
        opts = {
          keymap = { preset = "default" },
          appearance = {
            nerd_font_variant = "mono",
          },
          completion = {
            documentation = { auto_show = true },
          },
          sources = {
            default = { "lsp", "path", "snippets", "buffer" },
          },
          signature = { enabled = true },
        },
      },

      -- Formatting (from dotfiles: conform.nvim)
      {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
          {
            "<leader>cf",
            function()
              require("conform").format({ async = true, lsp_fallback = true })
            end,
            desc = "Format buffer",
          },
        },
        opts = {
          formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "ruff_format" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
            json = { "prettierd", "prettier", stop_after_first = true },
            yaml = { "prettierd", "prettier", stop_after_first = true },
            markdown = { "prettierd", "prettier", stop_after_first = true },
            nix = { "nixpkgs_fmt" },
            go = { "gofumpt", "golines" },
            rust = { "rustfmt" },
            sh = { "shfmt" },
            terraform = { "terraform_fmt" },
          },
          format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
          },
        },
      },

      -- Linting (from dotfiles: nvim-lint)
      {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
          local lint = require("lint")
          lint.linters_by_ft = {
            sh = { "shellcheck" },
            bash = { "shellcheck" },
            dockerfile = { "hadolint" },
            yaml = { "yamllint" },
            terraform = { "tflint" },
          }
          vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
            callback = function()
              lint.try_lint()
            end,
          })
        end,
      },

      -- Status line (from dotfiles: lualine)
      {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
          options = {
            theme = "tokyonight",
            globalstatus = true,
          },
          sections = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = { { "filename", path = 1 } },
            lualine_x = { "encoding", "fileformat", "filetype" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
          },
        },
      },

      -- Which-key
      {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
          preset = "modern",
        },
        keys = {
          {
            "<leader>?",
            function()
              require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
          },
        },
      },

      -- Trouble (diagnostics)
      {
        "folke/trouble.nvim",
        opts = {},
        cmd = "Trouble",
        keys = {
          { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
          { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
        },
      },

      -- Mini.nvim (various utilities from dotfiles)
      {
        "echasnovski/mini.nvim",
        config = function()
          require("mini.ai").setup({ n_lines = 500 })
          require("mini.surround").setup()
          require("mini.pairs").setup()
          require("mini.comment").setup()
        end,
      },

      -- Undotree
      {
        "mbbill/undotree",
        keys = {
          { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle Undotree" },
        },
      },

      -- Additional plugins from dotfiles
      { "nvim-lua/plenary.nvim", lazy = true },
      { "nvim-tree/nvim-web-devicons", lazy = true },
    }, {
      ui = {
        icons = vim.g.have_nerd_font and {} or {
          cmd = "⌘", config = "🛠", event = "📅", ft = "📂",
          init = "⚙", keys = "🗝", plugin = "🔌", runtime = "💻",
          require = "🌙", source = "📄", start = "🚀", task = "📌",
          lazy = "💤 ",
        },
      },
    })

    -- LSP setup (native Neovim 0.11+ style from dotfiles)
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then return end

        -- Enable completion
        if client:supports_method("textDocument/completion") then
          vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end

        -- Keymaps
        local opts = { buffer = args.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      end,
    })

    -- Enable language servers (from dotfiles LSP config)
    vim.lsp.enable({
      "nil_ls",       -- Nix
      "lua_ls",       -- Lua
      "pyright",      -- Python
      "rust_analyzer", -- Rust
      "gopls",        -- Go
      "ts_ls",        -- TypeScript
      "terraformls",  -- Terraform
      "jsonls",       -- JSON
      "yamlls",       -- YAML
    })

    -- Diagnostics configuration
    vim.diagnostic.config({
      virtual_text = { spacing = 4, prefix = "●" },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = "rounded",
        source = true,
      },
    })
  '';
}
