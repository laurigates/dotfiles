return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
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
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "folke/neoconf.nvim",
    cmd = "Neoconf",
    opts = {},
  },
  -- "tpope/vim-speeddating",
  -- "tpope/vim-eunuch",
  -- "tpope/vim-rhubarb",
  -- nvim-bisquits makes large files load extremely slowly
  {
    "code-biscuits/nvim-biscuits",
    opts = {
      cursor_line_only = true,
      default_config = {
        -- max_length = 12,
        -- min_distance = 5,
        prefix_string = "📎",
      },
      -- language_config = {
      --   html = {
      --     prefix_string = " 🌐 "
      --   },
      --   javascript = {
      --     prefix_string = " ✨ ",
      --     max_length = 80
      --   },
      --   python = {
      --     disabled = true
      --   }
      -- }
    },
  },
  {
    "brenoprata10/nvim-highlight-colors",
    opts = {},
  },
  "towolf/vim-helm", -- Required for helm filetype detection (could probably just copy the ftdetect file)
  -- {
  --   'altermo/ultimate-autopair.nvim',
  --   event = { 'InsertEnter', 'CmdlineEnter' },
  --   branch = 'v0.6',   --recommended as each new version will have breaking changes
  --   opts = {
  --     --Config goes here
  --   },
  -- }
  -- {
  --   "nvimtools/none-ls.nvim",
  --   dependencies = {
  --     "nvimtools/none-ls-extras.nvim",
  --   },
  --   config = function()
  --     local null_ls = require("null-ls")
  --
  --     null_ls.setup({
  --       sources = {
  --         null_ls.builtins.formatting.stylua,
  --         null_ls.builtins.completion.spell,
  --         require("none-ls.formatting.jq"),
  --         require("none-ls.diagnostics.eslint"), -- requires none-ls-extras.nvim
  --       },
  --     })
  --   end,
  -- },
  {
    "nmac427/guess-indent.nvim",
    opts = {},
  },
  { "meznaric/key-analyzer.nvim", opts = {} },
}
