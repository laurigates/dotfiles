return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    -- You can add configuration options for neotest here later if needed,
    -- for example, using the 'opts' key or a 'config' function.
    opts = {},
    -- config = function()
    --   require("neotest").setup({
    --     -- your neotest config
    --   })
    -- end,
  },
}
