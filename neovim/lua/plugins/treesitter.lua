return {
	{ -- Additional text-objects using treesitter. Needs to be configured.
		"nvim-treesitter/nvim-treesitter-textobjects",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			local configs = require("nvim-treesitter.configs")

			configs.setup({
				ensure_installed = {
					"lua",
					"query",
					"vimdoc",
					"vim",
					"c",
					"python",
					"bash",
					"markdown",
					"markdown_inline",
					"dockerfile",
					"terraform",
					"json",
					"yaml",
					"toml",
				},
				sync_install = false,
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
}
