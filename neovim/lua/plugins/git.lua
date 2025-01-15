return {
  "tpope/vim-fugitive",
  { -- GitHub interface
    "pwntester/octo.nvim",
    cmd = "Octo",
    event = { { event = "BufReadCmd", pattern = "octo://*" } },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      default_merge_method = "squash",
      default_to_projects_v2 = true,
    },
    keys = {
      -- Add maps for create issue & pr
    },
  },
  { "akinsho/git-conflict.nvim", version = "*", config = true },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim",
    },
    config = true,
  },
}
