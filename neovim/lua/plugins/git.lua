-- Plugins related to working with Git
return {
	{ -- GitHub interface
		"pwntester/octo.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
		event = "VeryLazy",
	},
	{ -- Colorize conflicts and enable jumping between them
		"akinsho/git-conflict.nvim",
		opts = {},
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {},
	},
}
