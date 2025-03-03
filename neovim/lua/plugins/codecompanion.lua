return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      strategies = {
        chat = {
          adapter = "githubmodels",
        },
        inline = {
          adapter = "githubmodels",
        },
        cmd = {
          adapter = "githubmodels",
        },
      },
    },
  },
}
