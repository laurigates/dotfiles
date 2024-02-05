return {
	{
		"nvim-telescope/telescope.nvim",
		-- tag = '0.1.4',
		branch = "0.1.x",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{
				"<leader>ff",
				"<cmd>lua require('telescope.builtin').find_files({ hidden = true })<cr>",
				desc = "Telescope find_files",
			},
			{
				"<leader>fg",
				"<cmd>lua require('telescope.builtin').live_grep()<cr>",
				desc = "Telescope live_grep",
			},
			{
				"<leader>fb",
				"<cmd>lua require('telescope.builtin').buffers()<cr>",
				desc = "Telescope buffers",
			},
			{
				"<leader>fh",
				"<cmd>lua require('telescope.builtin').help_tags()<cr>",
				desc = "Telescope help_tags",
			},
			{
				"<leader>fr",
				'<cmd>lua require("telescope.builtin").git_files()<cr>',
				desc = "Telescope git_files",
			},
			{
				"<leader>fm",
				'<cmd>lua require("telescope.builtin").keymaps()<cr>',
				desc = "Telescope keymaps",
			},
			{
				"<leader>ft",
				'<cmd>lua require("search").open()<cr>',
				desc = "Telescope search",
			},
		},
	},
	{ -- Add tabs to Telescope search
		"FabianWirth/search.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
	},
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
		opts = {
			-- don't use `defaults = { }` here, do this in the main telescope spec
			extensions = {
				fzf = {
					fuzzy = true, -- false will only do exact matching
					override_generic_sorter = true, -- override the generic sorter
					override_file_sorter = true, -- override the file sorter
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
					-- the default case_mode is "smart_case"
				},
				-- no other extensions here, they can have their own spec too
			},
		},
		config = function(_, opts)
			-- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
			-- configs for us. We won't use data, as everything is in it's own namespace (telescope
			-- defaults, as well as each extension).
			require("telescope").setup(opts)
			require("telescope").load_extension("fzf")
		end,
	},
	{
		-- It sets vim.ui.select to telescope. That means for example that neovim core stuff can fill the telescope picker. Example would be lua vim.lsp.buf.code_action().
		"nvim-telescope/telescope-ui-select.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
	},
	{
		"debugloop/telescope-undo.nvim",
		dependencies = { -- note how they're inverted to above example
			{
				"nvim-telescope/telescope.nvim",
				dependencies = { "nvim-lua/plenary.nvim" },
			},
		},
		keys = {
			{ -- lazy style key map
				"<leader>u",
				"<cmd>Telescope undo<cr>",
				desc = "undo history",
			},
		},
		opts = {
			-- don't use `defaults = { }` here, do this in the main telescope spec
			extensions = {
				undo = {
					-- telescope-undo.nvim config, see below
				},
				-- no other extensions here, they can have their own spec too
			},
		},
		config = function(_, opts)
			-- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
			-- configs for us. We won't use data, as everything is in it's own namespace (telescope
			-- defaults, as well as each extension).
			require("telescope").setup(opts)
			require("telescope").load_extension("undo")
		end,
	},
	{
		"aaronhallaert/advanced-git-search.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			-- don't use `defaults = { }` here, do this in the main telescope spec
			extensions = {
				advanced_git_search = {
					-- advanced_git_search config, see below
				},
				-- no other extensions here, they can have their own spec too
			},
		},
		config = function(_, opts)
			-- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
			-- configs for us. We won't use data, as everything is in it's own namespace (telescope
			-- defaults, as well as each extension).
			require("telescope").setup(opts)
			require("telescope").load_extension("advanced_git_search")
		end,
	},
	{
		"aznhe21/actions-preview.nvim",
		opts = {},
	},
}
