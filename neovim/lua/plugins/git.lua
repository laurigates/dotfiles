-- Plugins related to working with Git
return {
  "tpope/vim-fugitive",
  { -- GitHub interface
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
    event = "VeryLazy",
  },
  { -- Colorize conflicts and enable jumping between them
    "akinsho/git-conflict.nvim",
    opts = {},
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gitsigns.nav_hunk('next')
          end
        end)

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gitsigns.nav_hunk('prev')
          end
        end)
      end
    },
    keys = {
      -- Actions
      {"<leader>hs", require("gitsigns").stage_hunk, mode = "n", desc = "Stage hunk"},
      {"<leader>hr", require("gitsigns").reset_hunk, mode = "n", desc = "Reset hunk"},
      {"<leader>hs", function() require("gitsigns").stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, mode = 'v', desc = "Stage hunk"},
      {"<leader>hr", function() require("gitsigns").reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, mode = 'v', desc = "Reset hunk"},
      {"<leader>hS", require("gitsigns").stage_buffer, mode = 'n', desc = "Stage buffer"},
      {"<leader>hu", require("gitsigns").undo_stage_hunk, mode = 'n', desc = "Undo stage hunk"},
      {"<leader>hR", require("gitsigns").reset_buffer, mode = 'n', desc = "Reset buffer"},
      {"<leader>hp", require("gitsigns").preview_hunk, mode = 'n', desc = "Preview hunk"},
      {"<leader>hb", function() require("gitsigns").blame_line { full = true } end, mode = 'n', desc = "Blame line"},
      {"<leader>tb", require("gitsigns").toggle_current_line_blame, mode = 'n', desc = "Toggle current line blame"},
      {"<leader>hd", require("gitsigns").diffthis, mode = 'n', desc = "Diff this"},
      {"<leader>hD", function() require("gitsigns").diffthis('~') end, mode = 'n', desc = "Diff this"},
      {"<leader>td", require("gitsigns").toggle_deleted, mode = 'n', desc = "Toggle deleted"},
      -- Text object
      {'ih', ':<C-U>Gitsigns select_hunk<CR>', mode = { 'o', 'x' }, desc = "Select hunk"},
    },
  },
  {
    "sindrets/diffview.nvim",
    opts = {},
  }
}
