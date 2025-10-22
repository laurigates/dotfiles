---@module "lazy"
---@type LazySpec
return {
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
      "Kaiser-Yang/blink-cmp-git",
      "mikavilpas/blink-ripgrep.nvim",
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = 'default',
        -- Tab/S-Tab: Navigate snippets first, then completion menu, then fallback to tabout/indent
        ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
      },
      completion = {
        menu = {
          draw = {
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)

                  return kind_icon .. " (" .. ctx.source_name .. ")"
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
      -- enabled = function()
      -- -- Disable in gitcommits because it messes up codecompanion commit message input
      --   return not vim.tbl_contains({ "gitcommit" }, vim.bo.filetype)
      -- end,
      snippets = { preset = "mini_snippets" },
      sources = {
        -- add lazydev to your completion providers
        default = { "lsp", "path", "snippets", "buffer", "ripgrep" },
        per_filetype = {
          -- optionally inherit from the `default` sources
          lua = { inherit_defaults = true, "lazydev" },
          -- use git source in git commits only
          gitcommit = { inherit_defaults = true, "git" },
        },
        providers = {
          ripgrep = {
            module = "blink-ripgrep",
            name = "Ripgrep",
          },
          git = {
            module = "blink-cmp-git",
            name = "Git",
            opts = {
              -- options for the blink-cmp-git
            },
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
  },
}
