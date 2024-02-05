-- A completion plugin for neovim coded in Lua.
return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
			{ "petertriho/cmp-git", dependencies = "nvim-lua/plenary.nvim" },
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				-- Load snippet support
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},

				-- Completion settings
				window = {
					completion = {
						--completeopt = 'menu,menuone,noselect'
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
					{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
					{ name = "luasnip" },
					{ name = "path" },
					{ name = "buffer" },
				}),
			})
			-- Set configuration for specific filetype.
			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "cmp_git" }, -- You can specify the `cmp_git` source if you were installed it.
				}, {
					{ name = "buffer" },
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

			require("cmp_git").setup()
			-- If you want insert `(` after select function or method item
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},
}
