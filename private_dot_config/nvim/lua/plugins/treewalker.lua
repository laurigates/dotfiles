return {
  "aaronik/treewalker.nvim",

  -- The following options are the defaults.
  -- Treewalker aims for sane defaults, so these are each individually optional,
  -- and setup() does not need to be called, so the whole opts block is optional as well.
  opts = {
    -- Whether to briefly highlight the node after jumping to it
    highlight = true,

    -- How long should above highlight last (in ms)
    highlight_duration = 250,

    -- The color of the above highlight. Must be a valid vim highlight group.
    -- (see :h highlight-group for options)
    highlight_group = "CursorLine",
  },

  keys = {
    -- movement
    { "<C-k>", "<cmd>Treewalker Up<cr>", mode = { "n", "v" }, desc = "Move Up" },
    { "<C-j>", "<cmd>Treewalker Down<cr>", mode = { "n", "v" }, desc = "Move Down" },
    { "<C-h>", "<cmd>Treewalker Left<cr>", mode = { "n", "v" }, desc = "Move Left" },
    { "<C-l>", "<cmd>Treewalker Right<cr>", mode = { "n", "v" }, desc = "Move Right" },

    -- swapping
    { "<C-S-k>", "<cmd>Treewalker SwapUp<cr>", mode = "n", desc = "Swap Up" },
    { "<C-S-j>", "<cmd>Treewalker SwapDown<cr>", mode = "n", desc = "Swap Down" },
    { "<C-S-h>", "<cmd>Treewalker SwapLeft<cr>", mode = "n", desc = "Swap Left" },
    { "<C-S-l>", "<cmd>Treewalker SwapRight<cr>", mode = "n", desc = "Swap Right" },
  },
}
