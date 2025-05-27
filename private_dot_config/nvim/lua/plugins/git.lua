-- lua/plugins/git.lua
return {
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gc", "<cmd>G commit -v<cr>", desc = "Git commit" },
      { "<leader>gp", "<cmd>G push<cr>", desc = "Git push" },
    },
  },
  { -- GitHub interface
    "pwntester/octo.nvim",
    cmd = "Octo",
    event = { { event = "BufReadCmd", pattern = "octo://*" } },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      default_merge_method = "squash",
      default_to_projects_v2 = true,
    },
    keys = {
      -- Octo Mappings
      { "<leader>go", "<cmd>Octo actions<cr>", desc = "Open Octo" },
      { "<leader>goc", "<cmd>Octo comment add<cr>", desc = "Add Octo Comment" },
      { "<leader>goi", "<cmd>Octo issue create<cr>", desc = "Create Octo Issue" },
      { "<leader>gop", "<cmd>Octo pr create<cr>", desc = "Create Octo PR" },
      { "<leader>gos", "<cmd>Octo search <cr>", desc = "Search Octo" },
      { "<leader>gor", "<cmd>Octo repo browser<cr>", desc = "Octo Repo Browser" },
    },
  },
  { "akinsho/git-conflict.nvim", version = "*", config = true },
  { "sindrets/diffview.nvim" },
  -- {
  -- 	"NeogitOrg/neogit",
  -- 	dependencies = {
  -- 		"nvim-lua/plenary.nvim", -- required
  -- 		"sindrets/diffview.nvim",
  -- 	},
  -- 	config = true,
  -- 	opts = {
  -- 		-- disable_insert_on_commit = true,
  -- 		graph_style = "kitty",
  -- 		-- integrations = {
  -- 		-- 	mini_pick = true,
  -- 		-- },
  -- 	},
  -- 	cmd = "Neogit",
  -- 	keys = {
  -- 		-- Neogit Mappings
  -- 		{ "<leader>ng", "<cmd>Neogit<cr>", desc = "Open Neogit" },
  -- 		{ "<leader>ngl", "<cmd>NeogitLog<cr>", desc = "Neogit Log" },
  -- 		{ "<leader>nb", "<cmd>NeogitBranch<cr>", desc = "Neogit Branch" },
  -- 		{ "<leader>ns", "<cmd>NeogitStash<cr>", desc = "Neogit Stash" },
  -- 	},
  -- },
}
