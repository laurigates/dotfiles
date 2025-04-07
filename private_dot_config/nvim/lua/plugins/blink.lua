return {
  "saghen/blink.cmp",
  version = "*",
  opts = {
    completion = {
      menu = {
        draw = {
          components = {
            kind_icon = {
              ellipsis = false,
              text = function(ctx)
                local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                return kind_icon
              end,
              -- Optionally, you may also use the highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
          },
        },
      },
      -- Show documentation when selecting a completion item
      documentation = { auto_show = true, auto_show_delay_ms = 500 },
      -- Display a preview of the selected item on the current line
      ghost_text = { enabled = true },
    },
    -- Experimental signature help support
    signature = { enabled = true },
    enabled = function()
      return not vim.tbl_contains({ "gitcommit" }, vim.bo.filetype)
    end,
  },
}
