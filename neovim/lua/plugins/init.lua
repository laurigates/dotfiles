return {
	"folke/which-key.nvim",
	{
		"folke/neoconf.nvim",
		cmd = "Neoconf",
		opts = {},
	},
	{
		-- Plugin completions don't seem to work
		-- An addition that would be nice: Support goto-definition (gd/gD) on plugin names. This could jump to the plugin code.
		-- If K is pressed, display popup with info about plugin e.g. description
		"folke/neodev.nvim",
		opts = {},
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			-- add any options here
		},
		dependencies = {
			-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
			"MunifTanjim/nui.nvim",
			-- OPTIONAL:
			--   `nvim-notify` is only needed, if you want to use the notification view.
			--   If not available, we use `mini` as the fallback
			"rcarriga/nvim-notify",
		},
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},
	-- targets.vim adds various text objects
	-- Commented out for now because it's quite outdated
	-- "wellle/targets.vim",
	-- "justinmk/vim-sneak",
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {}, -- this is equalent to setup({}) function
	},
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.surround').setup()
      -- require('mini.completion').setup()
      require('mini.ai').setup()
      require('mini.indentscope').setup()
    end
  },
}
