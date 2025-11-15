return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "Avante", "copilot-chat", "opencode_output" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      preset = "obsidian", -- Optimized for obsidian.nvim integration
      render_modes = { "n", "c" }, -- Render in normal and command modes
      anti_conceal = {
        enabled = true, -- Hide virtual text on cursor line for better editing
      },
      heading = {
        width = "block",
        border = true,
      },
      code = {
        width = "block",
        border = "thin",
      },
      file_types = { "markdown", "opencode_output" },
    },
  },
}
