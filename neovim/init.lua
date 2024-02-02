local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
require("lazy").setup({
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
	-- lazy.nvim
	-- {
	--   "folke/noice.nvim",
	--   event = "VeryLazy",
	--   opts = {
	--     -- add any options here
	--   },
	--   dependencies = {
	--     -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
	--     "MunifTanjim/nui.nvim",
	--     -- OPTIONAL:
	--     --   `nvim-notify` is only needed, if you want to use the notification view.
	--     --   If not available, we use `mini` as the fallback
	--     "rcarriga/nvim-notify",
	--     }
	-- },
	-- {
	--   "navarasu/onedark.nvim",
	--   lazy = false,    -- make sure we load this during startup if it is your main colorscheme
	--   priority = 1000, -- make sure to load this before all the other start plugins
	--   init = function()
	--     -- Load colorscheme at startup
	--     require('onedark').load()
	--   end,
	-- },
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},
	{
		"williamboman/mason.nvim",
		opts = {},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		opts = {},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				-- Conform will run multiple formatters sequentially
				python = { "isort", "ruff", "autopep8" },
				dockerfile = { "hadolint" },
				["_"] = { "trim_whitespace" },
				-- Use a sub-list to run only the first available formatter
				-- javascript = { { "prettierd", "prettier" } },
			},
			format_on_save = {
				-- I recommend these options. See :help conform.format for details.
				lsp_fallback = true,
				timeout_ms = 500,
			},
		},
	},
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
	{
		"numToStr/Comment.nvim",
		opts = {
			-- add any options here
		},
		lazy = false,
	},
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup()
		end,
	},
	-- "tpope/vim-surround", -- mappings to delete, change and add surroundings
	-- "tpope/vim-unimpaired",
	-- "tpope/vim-repeat",
	-- vim-sleuth automatically adjusts 'shiftwidth' and 'expandtab' heuristically based on the current file, or, in the case the current file is new, blank, or otherwise insufficient, by looking at other files of the same type in the current and parent directories.
	-- "tpope/vim-sleuth",
	"tpope/vim-speeddating",
	"tpope/vim-eunuch",
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	-- targets.vim adds various text objects
	-- Commented out for now because it's quite outdated
	-- "wellle/targets.vim",
	"justinmk/vim-sneak",
	-- {
	--   "aaronhallaert/advanced-git-search.nvim",
	--   dependencies = {
	--     "nvim-telescope/telescope.nvim",
	--   },
	-- opts = {
	-- 	-- don't use `defaults = { }` here, do this in the main telescope spec
	-- 	extensions = {
	-- 		advanced_git_search = {
	-- 			-- advanced_git_search config, see below
	-- 		},
	-- 		-- no other extensions here, they can have their own spec too
	-- 	},
	-- },
	-- config = function(_, opts)
	-- 	-- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
	-- 	-- configs for us. We won't use data, as everything is in it's own namespace (telescope
	-- 	-- defaults, as well as each extension).
	-- 	require("telescope").setup(opts)
	-- 	require("telescope").load_extension("advanced_git_search")
	-- end,
	-- },
	{ -- GitHub interface
		"pwntester/octo.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {},
	},
	{ -- Colorize conflicts and enable jumping between them
		"akinsho/git-conflict.nvim",
		opts = {},
	},
	{
		"nvim-telescope/telescope.nvim",
		-- tag = '0.1.4',
		branch = "0.1.x",
		dependencies = { "nvim-lua/plenary.nvim" },
		-- keys = {
		--   { "<leader>ff", "<cmd>lua require('telescope.builtin').find_files()<cr>", desc = "Telescope find_files"},
		--   { "<leader>fg", "<cmd>lua require('telescope.builtin').live_grep()<cr>", desc = "Telescope live_grep"},
		--   { "<leader>fb", "<cmd>lua require('telescope.builtin').buffers()<cr>", desc = "Telescope buffers"},
		--   { "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>", desc = "Telescope help_tags"},
		-- },
		opts = {
			extensions = {
				-- advanced_git_search = {},
				fzf = {
					fuzzy = true, -- false will only do exact matching
					override_generic_sorter = true, -- override the generic sorter
					override_file_sorter = true, -- override the file sorter
					case_mode = "smart_case", -- or "ignore_case" or "respect_case"
					-- the default case_mode is "smart_case"
				},
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
					-- fzf config, see below
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
		-- Neovim plugin to improve the default vim.ui interfaces
		"stevearc/dressing.nvim",
		opts = {},
	},
	{
		"aznhe21/actions-preview.nvim",
		opts = {},
	},
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			theme = "tokyonight",
			sections = {
				lualine_x = {
					{
						require("lazy.status").updates,
						cond = require("lazy.status").has_updates,
						color = { fg = "#ff9e64" },
					},
				},
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {},
	},
	{
		"goolord/alpha-nvim",
		config = function()
			require("alpha").setup(require("alpha.themes.dashboard").config)
		end,
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
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {}, -- this is equalent to setup({}) function
	},
	-- Autocomplete
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"L3MON4D3/LuaSnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-buffer",
			{ "petertriho/cmp-git", dependencies = "nvim-lua/plenary.nvim" },
			"saadparwaiz1/cmp_luasnip",
		},
	},
	{
		-- This plugin adds indentation guides to Neovim.
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {},
	},
	{
		"romgrk/barbar.nvim",
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
		},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
	},
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	{
		"gsuuon/model.nvim",
		-- Don't need these if lazy = false
		cmd = { "M", "Model", "Mchat" },
		init = function()
			vim.filetype.add({
				extension = {
					mchat = "mchat",
				},
			})
		end,
		ft = "mchat",
		keys = {
			{ "<C-m>d", ":Mdelete<cr>", mode = "n" },
			{ "<C-m>s", ":Mselect<cr>", mode = "n" },
			{ "<C-m><space>", ":Mchat<cr>", mode = "n" },
		},
		config = function()
			require("model.providers.llamacpp").setup({
				binary = "~/repos/llama.cpp/server",
				models = "~/llm-models",
			})

			local llamacpp = require("model.providers.llamacpp")
			local llama2 = require("model.format.llama2")

			require("model").setup({
				default_prompt = {
					provider = llamacpp,
					options = {
						-- https://github.com/gsuuon/model.nvim
						-- https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md
						-- https://huggingface.co/TheBloke/CodeLlama-13B-oasst-sft-v10-GGUF
						model = "codellama-13b-oasst-sft-v10.Q5_K_M.gguf",
						args = {
							"-c",
							8192,
							"-ngl",
							32,
						},
					},
					builder = function(input)
						return function(build)
							vim.ui.input({ prompt = "Instruction: " }, function(user_input)
								build({
									prompt = "<|im_start|>system\n"
										.. (user_input or "You are a helpful assistant")
										.. "<|im_end|>\n"
										.. "<|im_start|>user\n"
										.. input
										.. "<|im_end|>\n"
										.. "<|im_start|>assistant",
								})
							end)
						end
					end,
				},
				prompts = {
					["llamacpp:codellama"] = {
						provider = llamacpp,
						options = {
							-- https://github.com/gsuuon/model.nvim
							-- https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md
							-- https://huggingface.co/TheBloke/CodeLlama-13B-oasst-sft-v10-GGUF
							model = "codellama-13b-oasst-sft-v10.Q5_K_M.gguf",
							args = {
								"-c",
								8192,
								"-ngl",
								32,
							},
						},
						builder = function(input, context)
							return {
								prompt = "<|im_start|>system\n"
									.. (context.args or "You are a helpful assistant")
									.. "<|im_end|>\n"
									.. "<|im_start|>user\n"
									.. input
									.. "<|im_end|>\n"
									.. "<|im_start|>assistant",
							}
						end,
					},
				},
			})
		end,
	},
	{
		"stevearc/oil.nvim",
		opts = {},
		-- Optional dependencies
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	"gabrielpoca/replacer.nvim",
	{
		"mfussenegger/nvim-dap",
	},
	{
		"mfussenegger/nvim-dap-python",
		config = function()
			require("dap-python").setup()
		end,
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
	-- "wellle/targets.vim",
	-- {
	--   'linux-cultist/venv-selector.nvim',
	--   dependencies = { 'neovim/nvim-lspconfig', 'nvim-telescope/telescope.nvim', 'mfussenegger/nvim-dap-python' },
	--   opts = {
	--     -- Your options go here
	--     -- name = "venv",
	--     -- auto_refresh = false
	--   },
	--   event = 'VeryLazy', -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
	--   keys = {
	--     -- Keymap to open VenvSelector to pick a venv.
	--     { '<leader>vs', '<cmd>VenvSelect<cr>' },
	--     -- Keymap to retrieve the venv from a cache (the one previously used for the same project directory).
	--     { '<leader>vc', '<cmd>VenvSelectCached<cr>' },
	--   },
	-- }
})

vim.cmd([[colorscheme tokyonight]])

-- require("lspconfig").lua_ls.setup {}

require("core/settings")
require("core/autocommands")
require("core/lsp")
-- require("core/functions")
require("plugins/nvim-barbar")
require("plugins/nvim-cmp")
require("plugins/nvim-telescope")
require("plugins/nvim-autopairs")
-- require("plugins/codegpt")
require("core/keymaps")
