-- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters.
return {
	{
		"williamboman/mason.nvim",
		opts = {},
		event = "VeryLazy",
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = {},
		event = "VeryLazy",
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"SmiteshP/nvim-navbuddy",
				dependencies = {
					"SmiteshP/nvim-navic",
					"MunifTanjim/nui.nvim",
				},
				opts = { lsp = { auto_attach = true } },
			},
		},
		-- your lsp config or other stuff
	},
}
