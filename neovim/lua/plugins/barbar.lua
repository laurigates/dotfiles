return {
	{
		"romgrk/barbar.nvim",
		-- We want this available after startup
		lazy = false,
		dependencies = {
			"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
			"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {
			-- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
			-- animation = true,
			-- insert_at_start = true,
			-- …etc.
			hide = { extensions = true, inactive = false },
		},
		keys = {
			{ "<A-,>", "<Cmd>BufferPrevious<CR>", { noremap = true, silent = true } },
			{ "<A-.>", "<Cmd>BufferNext<CR>", { noremap = true, silent = true } },
			{ "<A-<>", "<Cmd>BufferMovePrevious<CR>", { noremap = true, silent = true } },
			{ "<A->>", "<Cmd>BufferMoveNext<CR>", { noremap = true, silent = true } },
			{ "<A-1>", "<Cmd>BufferGoto 1<CR>", { noremap = true, silent = true } },
			{ "<A-2>", "<Cmd>BufferGoto 2<CR>", { noremap = true, silent = true } },
			{ "<A-3>", "<Cmd>BufferGoto 3<CR>", { noremap = true, silent = true } },
			{ "<A-4>", "<Cmd>BufferGoto 4<CR>", { noremap = true, silent = true } },
			{ "<A-5>", "<Cmd>BufferGoto 5<CR>", { noremap = true, silent = true } },
			{ "<A-6>", "<Cmd>BufferGoto 6<CR>", { noremap = true, silent = true } },
			{ "<A-7>", "<Cmd>BufferGoto 7<CR>", { noremap = true, silent = true } },
			{ "<A-8>", "<Cmd>BufferGoto 8<CR>", { noremap = true, silent = true } },
			{ "<A-9>", "<Cmd>BufferGoto 9<CR>", { noremap = true, silent = true } },
			{ "<A-0>", "<Cmd>BufferLast<CR>", { noremap = true, silent = true } },
			{ "<A-p>", "<Cmd>BufferPin<CR>", { noremap = true, silent = true } },
			{ "<A-c>", "<Cmd>BufferClose<CR>", { noremap = true, silent = true } },
			{ "<C-p>", "<Cmd>BufferPick<CR>", { noremap = true, silent = true } },
			{ "<Space>bb", "<Cmd>BufferOrderByBufferNumber<CR>", { noremap = true, silent = true } },
			{ "<Space>bd", "<Cmd>BufferOrderByDirectory<CR>", { noremap = true, silent = true } },
			{ "<Space>bl", "<Cmd>BufferOrderByLanguage<CR>", { noremap = true, silent = true } },
			{ "<Space>bw", "<Cmd>BufferOrderByWindowNumber<CR>", { noremap = true, silent = true } },
			{ "<leader>bc", "<cmd>BufferClose<cr>", { noremap = true, silent = true } },
			{ "<leader>bn", "<cmd>BufferNext<cr>", { noremap = true, silent = true } },
			{ "<leader>bp", "<cmd>BufferPrevious<cr>", { noremap = true, silent = true } },
		},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
	},
}
