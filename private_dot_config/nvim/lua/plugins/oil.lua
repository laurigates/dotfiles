-- Neovim file explorer: edit your filesystem like a buffer
return {
	{
		"stevearc/oil.nvim",
		opts = {},
		keys = {
			{
				"<leader>o",
				"<cmd>lua require('oil').open_float()<cr>",
				desc = "Oil open floating window",
			},
		},
	},
}
