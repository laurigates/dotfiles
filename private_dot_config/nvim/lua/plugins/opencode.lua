return {
  {
    "sudo-tee/opencode.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = { "OpenCode" },
    keys = {
      { "<leader>oc", "<cmd>OpenCode<cr>", desc = "Open code" },
      { "<leader>od", "<cmd>OpenCode dir<cr>", desc = "Open code directory" },
      { "<leader>of", "<cmd>OpenCode file<cr>", desc = "Open code file" },
    },
    opts = {
      -- Default configuration options
      -- These can be customized based on the plugin's documentation
      default_command = "code", -- Default external editor command
      show_hidden = false, -- Show hidden files
      respect_gitignore = true, -- Respect .gitignore files
      max_depth = 10, -- Maximum directory depth for searches
      preview = true, -- Show preview of files
      auto_close = true, -- Auto-close when opening
      keymaps = {
        open = "<CR>",
        preview = "p",
        quit = "q",
      },
    },
    config = function(_, opts)
      require("opencode").setup(opts)
    end,
  },
}