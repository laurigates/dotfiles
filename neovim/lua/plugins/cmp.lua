-- A completion plugin for neovim coded in Lua.
return {
  {
    "hrsh7th/nvim-cmp",
    -- event = "InsertEnter",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
      },
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      {
        "petertriho/cmp-git",
        dependencies = { "nvim-lua/plenary.nvim" },
      },
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind.nvim",
      {
        "vrslev/cmp-pypi",
        dependencies = { "nvim-lua/plenary.nvim" },
        ft = "toml",
      },
    },
    config = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")
      local luasnip = require("luasnip")

      cmp.setup({
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text", -- show only symbol annotations
            menu = {
              buffer = "[Buffer]",
              nvim_lsp = "[LSP]",
              luasnip = "[LuaSnip]",
              nvim_lua = "[Lua]",
              path = "[Path]",
              cmp_git = "[Git]",
              pypi = "[PyPI]",
            },
            maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
            -- can also be a function to dynamically calculate max width such as
            -- maxwidth = function() return math.floor(0.45 * vim.o.columns) end,
            ellipsis_char = "...",    -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
            show_labelDetails = true, -- show labelDetails in menu. Disabled by default

            -- The function below will be called before any actual modifications from lspkind
            -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
            -- before = function (entry, vim_item)
            --   ...
            --   return vim_item
            -- end
          }),
        },
        -- Load snippet support
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        -- Completion settings
        window = {
          completion = {
            completeopt = "menuone,noselect,noinsert", -- Autocomplete options
            --completeopt = 'menu,menuone,noselect'
            -- This option is nice to prevent the autocompletion from popping up for every character, but limits some forms of completion.
            keyword_length = 2,
          },
        },
        -- Key mapping
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          -- Tab mapping
          ["<Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end,
          ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end,
        }),

        -- Load sources, see: https://github.com/topics/nvim-cmp
        sources = cmp.config.sources({
          { name = "nvim_lua" },
          { name = "nvim_lsp" },
          { name = "cmp_git", keyword_length = 1 }, -- You can specify the `cmp_git` source if you were installed it.
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer",  keyword_length = 5 },
          { name = "pypi",    keyword_length = 4 },
        }),
      })
      -- Set configuration for specific filetype.
      cmp.setup.filetype("gitcommit", {
        sources = cmp.config.sources({
          { name = "cmp_git", keyword_length = 1 }, -- You can specify the `cmp_git` source if you were installed it.
        }, {
          { name = "buffer", keyword_length = 5 },
        }),
      })

      -- -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      -- cmp.setup.cmdline('/', {
      --   mapping = cmp.mapping.preset.cmdline(),
      --   sources = {
      --     { name = 'buffer' }
      --   }
      -- })

      -- -- `:` cmdline setup.
      -- cmp.setup.cmdline(':', {
      --   mapping = cmp.mapping.preset.cmdline(),
      --   sources = cmp.config.sources({
      --     { name = 'path' }
      --   }, {
      --     {
      --       name = 'cmdline',
      --       option = {
      --         ignore_cmds = { 'Man', '!' }
      --       }
      --     }
      --   })
      -- })

      -- Git source for nvim-cmp
      -- Completes :commits, #issues, @mentions, #pull_requests
      require("cmp_git").setup()

      -- If you want insert `(` after select function or method item
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

      -- Load friendly-snippets, a set of preconfigured snippets for different languages.
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
