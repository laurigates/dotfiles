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
  { "folke/neoconf.nvim", cmd = "Neoconf", opts = {} },
  "folke/neodev.nvim",
  { "navarasu/onedark.nvim",
      lazy = false, -- make sure we load this during startup if it is your main colorscheme
      priority = 1000, -- make sure to load this before all the other start plugins
      init = function()
        -- Load colorscheme at startup
	require('onedark').load()
      end,
  },
  {"williamboman/mason.nvim", opts = {}},
  {"williamboman/mason-lspconfig.nvim", opts = {}},
  "neovim/nvim-lspconfig",
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  "tpope/vim-commentary",
  "tpope/vim-surround", -- mappings to delete, change and add surroundings
  "tpope/vim-unimpaired",
  "tpope/vim-repeat",
  "tpope/vim-speeddating",
  "tpope/vim-eunuch",
  "tpope/vim-sleuth",
  "tpope/vim-fugitive",
  "wellle/targets.vim", --adds various text objects
  "justinmk/vim-sneak",
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.4',
    -- or                              , branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", desc = "Telescope find_files"},
      { "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<cr>", desc = "Telescope live_grep"},
      { "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<cr>", desc = "Telescope buffers"},
      { "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>", desc = "Telescope help_tags"},
    }
  },
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  {'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }, opts = {
    sections = {
      lualine_x = {
        {
          require("lazy.status").updates,
          cond = require("lazy.status").has_updates,
          color = { fg = "#ff9e64" },
        },
      },
    },
  }},
  {"lewis6991/gitsigns.nvim", opts = {}},
  {
    'goolord/alpha-nvim',
    config = function ()
      require'alpha'.setup(require'alpha.themes.dashboard'.config)
    end
  },
  {
    "SmiteshP/nvim-gps",
    dependencies = { "nvim-treesitter/nvim-treesitter" }
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
      'saadparwaiz1/cmp_luasnip',
    },
  },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
})

require("lspconfig").lua_ls.setup {}
