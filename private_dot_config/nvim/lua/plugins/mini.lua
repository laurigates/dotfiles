return {
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.surround").setup({
        custom_surroundings = {
          ["c"] = { output = { left = "`", right = "`" } },
          ["C"] = { output = { left = "```\n", right = "\n```" } },
        },
      })
      require("mini.ai").setup()
      require("mini.pairs").setup()
      require("mini.splitjoin").setup()
      require("mini.operators").setup()
      require("mini.icons").setup()
      require("mini.snippets").setup()
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
}
