local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

require("lazy").setup(
  {
    "folke/which-key.nvim",
    {
      "folke/neoconf.nvim",
      cmd = "Neoconf",
      opts = {}
    },
    {
      "folke/neodev.nvim",
      opts = {}
    },
    -- {
    --   "navarasu/onedark.nvim",
    --   lazy = false,    -- make sure we load this during startup if it is your main colorscheme
    --   priority = 1000, -- make sure to load this before all the other start plugins
    --   init = function()
    --     -- Load colorscheme at startup
    --     require('onedark').load()
    --   end,
    -- },
    {
      "folke/tokyonight.nvim",
      lazy = false,
      priority = 1000,
      opts = {},
    },
    {
      "williamboman/mason.nvim",
      opts = {}
    },
    {
      "williamboman/mason-lspconfig.nvim",
      opts = {}
    },
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate"
    },
    {
      'numToStr/Comment.nvim',
      opts = {
        -- add any options here
      },
      lazy = false,
    },
    "tpope/vim-surround", -- mappings to delete, change and add surroundings
    -- "tpope/vim-unimpaired",
    -- "tpope/vim-repeat",
    "tpope/vim-speeddating",
    "tpope/vim-eunuch",
    -- vim-sleuth automatically adjusts 'shiftwidth' and 'expandtab' heuristically based on the current file, or, in the case the current file is new, blank, or otherwise insufficient, by looking at other files of the same type in the current and parent directories.
    -- "tpope/vim-sleuth",
    "tpope/vim-fugitive",
    "tpope/vim-rhubarb",
    -- targets.vim adds various text objects
    -- Commented out for now because it's quite outdated
    -- "wellle/targets.vim",
    "justinmk/vim-sneak",
    {
      "aaronhallaert/advanced-git-search.nvim",
      dependencies = { "nvim-telescope/telescope.nvim" }
    },
    {
      'pwntester/octo.nvim',
      dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope.nvim',
        'nvim-tree/nvim-web-devicons',
      },
      opts = {},
    },
    { "akinsho/git-conflict.nvim", opts = {} },
    {
      'nvim-telescope/telescope.nvim',
      tag = '0.1.4',
      -- or                              , branch = '0.1.x',
      dependencies = { 'nvim-lua/plenary.nvim' },
      -- keys = {
      --   { "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", desc = "Telescope find_files"},
      --   { "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<cr>", desc = "Telescope live_grep"},
      --   { "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<cr>", desc = "Telescope buffers"},
      --   { "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>", desc = "Telescope help_tags"},
      -- },
      opts = {
        fzf = {
          fuzzy = true,                   -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true,    -- override the file sorter
          case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        }
      }
    },
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make'
    },
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      opts = {
        theme = 'tokyonight',
        sections = {
          lualine_x = {
            {
              require("lazy.status").updates,
              cond = require("lazy.status").has_updates,
              color = { fg = "#ff9e64" },
            },
          },
        },
      }
    },
    {
      "lewis6991/gitsigns.nvim",
      opts = {}
    },
    {
      'goolord/alpha-nvim',
      config = function()
        require 'alpha'.setup(require 'alpha.themes.dashboard'.config)
      end
    },
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        {
          "SmiteshP/nvim-navbuddy",
          dependencies = {
            "SmiteshP/nvim-navic",
            "MunifTanjim/nui.nvim"
          },
          opts = { lsp = { auto_attach = true } }
        }
      },
      -- your lsp config or other stuff
    },
    {
      'windwp/nvim-autopairs',
      event = "InsertEnter",
      opts = {} -- this is equalent to setup({}) function
    },
    -- Autocomplete
    {
      'hrsh7th/nvim-cmp',
      dependencies = {
        'L3MON4D3/LuaSnip',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-buffer',
        { "petertriho/cmp-git", dependencies = "nvim-lua/plenary.nvim" },
        'saadparwaiz1/cmp_luasnip',
      },
    },
    {
      -- This plugin adds indentation guides to Neovim.
      "lukas-reineke/indent-blankline.nvim",
      main = "ibl",
      opts = {}
    },
    {
      'romgrk/barbar.nvim',
      dependencies = {
        'lewis6991/gitsigns.nvim',     -- OPTIONAL: for git status
        'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
      },
      init = function() vim.g.barbar_auto_setup = false end,
      opts = {
        -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
        -- animation = true,
        -- insert_at_start = true,
        -- …etc.
      },
      version = '^1.0.0', -- optional: only update when a new 1.x version is released
    },
    {
      "folke/trouble.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      },
    },
    {
      'stevearc/oil.nvim',
      opts = {},
      -- Optional dependencies
      dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    'gabrielpoca/replacer.nvim',
  })

vim.cmd [[colorscheme tokyonight]]

-- Set up neoconf before lspconfig
require("neoconf").setup({
  -- override any of the default settings here
})

-- require("lspconfig").lua_ls.setup {}

require("core/settings")
require("core/keymaps")
require("core/lsp")
-- require("core/functions")
require("plugins/nvim-barbar")
require("plugins/nvim-cmp")
require("plugins/nvim-telescope")
require("plugins/nvim-treesitter")
require("plugins/nvim-autopairs")
-- require("plugins/codegpt")
