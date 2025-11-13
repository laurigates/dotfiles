return {
  {
    "sudo-tee/opencode.nvim",
    opts = {},
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MeanderingProgrammer/render-markdown.nvim", -- Configured in render-markdown.lua
      -- Optional, for file mentions and commands completion, pick only one
      "saghen/blink.cmp",
      -- Optional, for file mentions picker, pick only one
      "folke/snacks.nvim",
    },
  },
}
