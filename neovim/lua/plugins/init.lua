return {
  "folke/which-key.nvim",
  {
    "folke/neoconf.nvim",
    cmd = "Neoconf",
    opts = {},
  },
  {
    -- Plugin completions don't seem to work
    -- An addition that would be nice: Support goto-definition (gd/gD) on plugin names. This could jump to the plugin code.
    -- If K is pressed, display popup with info about plugin e.g. description
    "folke/neodev.nvim",
    opts = {},
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.surround').setup()
      require('mini.pick').setup()
      require('mini.ai').setup()
      require('mini.indentscope').setup()
      require('mini.pairs').setup()
      require('mini.splitjoin').setup()
      require('mini.jump').setup()
      require('mini.jump2d').setup()
    end
  },
  "tpope/vim-speeddating",
  "tpope/vim-eunuch",
  "tpope/vim-rhubarb",
}
