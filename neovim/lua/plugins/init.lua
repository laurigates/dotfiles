return {
  -- "folke/which-key.nvim",
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
    opts = {
      library = { plugins = { "nvim-dap-ui" }, types = true },
    },
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
      local miniclue = require('mini.clue')
      miniclue.setup({
        triggers = {
          -- Leader triggers
          -- Disabled because it messes with <leader>f
          -- { mode = 'n', keys = '<Leader>' },
          -- { mode = 'x', keys = '<Leader>' },

          -- Built-in completion
          { mode = 'i', keys = '<C-x>' },

          -- `g` key
          { mode = 'n', keys = 'g' },
          { mode = 'x', keys = 'g' },

          -- Marks
          { mode = 'n', keys = "'" },
          { mode = 'n', keys = '`' },
          { mode = 'x', keys = "'" },
          { mode = 'x', keys = '`' },

          -- Registers
          { mode = 'n', keys = '"' },
          { mode = 'x', keys = '"' },
          { mode = 'i', keys = '<C-r>' },
          { mode = 'c', keys = '<C-r>' },

          -- Window commands
          { mode = 'n', keys = '<C-w>' },

          -- `z` key
          { mode = 'n', keys = 'z' },
          { mode = 'x', keys = 'z' },
        },

        clues = {
          -- Enhance this by adding descriptions for <Leader> mapping groups
          miniclue.gen_clues.builtin_completion(),
          miniclue.gen_clues.g(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers(),
          miniclue.gen_clues.windows(),
          miniclue.gen_clues.z(),
        },
      })
    end
  },
  "tpope/vim-speeddating",
  "tpope/vim-eunuch",
  "tpope/vim-rhubarb",
  {
    "code-biscuits/nvim-biscuits",
    opts = {
      cursor_line_only = true,
      default_config = {
        -- max_length = 12,
        -- min_distance = 5,
        prefix_string = "📎"
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
    }
  },
}
