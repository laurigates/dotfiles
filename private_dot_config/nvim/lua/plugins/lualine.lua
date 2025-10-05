return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "SmiteshP/nvim-navic" },
    opts = {
      theme = "tokyonight",
      sections = {
        lualine_c = {
          {
            "navic",

            -- Component specific options
            color_correction = nil, -- Can be nil, "static" or "dynamic". This option is useful only when you have highlights enabled.
            -- Many colorschemes don't define same backgroud for nvim-navic as their lualine statusline backgroud.
            -- Setting it to "static" will perform a adjustment once when the component is being setup. This should
            --   be enough when the lualine section isn't changing colors based on the mode.
            -- Setting it to "dynamic" will keep updating the highlights according to the current modes colors for
            --   the current section.

            navic_opts = nil, -- lua table with same format as setup's option. All options except "lsp" options take effect when set here.
          },
        },
        lualine_x = {
          {
            function()
              return require("trouble").statusline({
                mode = "lsp_document_symbols",
                groups = {},
                title = false,
                filter = { range = true },
                format = "{kind_icon}{symbol.name:Normal}",
                -- The following line need to be set only if the `trouble` setup function
                -- is not yet called, so that statusline works properly before trouble is opened
                hl_group = "lualine_c_normal",
              })
            end,
            cond = function()
              return package.loaded["trouble"] and require("trouble").is_open()
            end,
          },
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
