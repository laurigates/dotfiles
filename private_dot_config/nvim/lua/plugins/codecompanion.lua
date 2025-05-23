return {
  {
    "olimorris/codecompanion.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
    },
    opts = function()
      return require("plugins.codecompanion.init")[1].opts
    end,
    keys = {
      {
        "<leader>ch",
        "<cmd>CodeCompanionChat Toggle<cr>",
        desc = "CodeCompanionChat",
      },
      {
        "<leader>cx",
        "<cmd>CodeCompanionActions<cr>",
        desc = "CodeCompanionActions",
      },
    },
  },
}
