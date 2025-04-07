return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      theme = "tokyonight",
      sections = {
        lualine_x = {
          {
            require("lazy.status").updates,
            cond = require("lazy.status").has_updates,
            color = { fg = "#ff9e64" },
          },
        },
      },
    },
  },
}
