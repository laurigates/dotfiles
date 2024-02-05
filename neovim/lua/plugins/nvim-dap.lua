return {
	{
		"mfussenegger/nvim-dap",
		keys = {
			{ "<F8>", "<cmd>DapContinue<cr>" },
			{ "<F9>", "<cmd>DapStepInto<cr>" },
			{ "<F10>", "<cmd>DapToggleBreakpoint<cr>" },
		},
	},
	{
		"mfussenegger/nvim-dap-python",
		config = function()
			require("dap-python").setup()
		end,
	},
}
