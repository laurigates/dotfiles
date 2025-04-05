return {
  {
    "mfussenegger/nvim-lint", -- Plugin name (e.g., "author/repo")
    -- Plugin will only load on these events
    -- event = "VeryLazy", -- Load on startup
    -- event = "BufReadPre", -- Load before file is read
    -- event = "InsertEnter", -- Load when entering insert mode

    -- Load when these commands are run
    -- cmd = { "MyCommand", "MyOtherCommand" },

    -- Load when these keys are pressed
    -- keys = {
    --   { "<leader>p", "<cmd>MyPluginCmd<cr>", desc = "My Plugin" },
    --   { "<leader>P", mode = { "n", "v" } },
    -- },

    -- Load when these filetypes are opened
    -- ft = { "lua", "javascript" },

    -- Dependencies required by this plugin
    -- dependencies = {
    --   "nvim-lua/plenary.nvim",
    --   { "other/plugin", lazy = true },
    -- },

    -- Plugin priority (load before other plugins)
    -- priority = 1000,

    -- Prevent plugin from being lazy-loaded
    -- lazy = false,

    -- Version tag or commit hash
    -- version = "*", -- Use latest release
    -- version = "v2.0.0", -- Use specific version
    -- commit = "8826f397", -- Use specific commit

    -- Branch name
    -- branch = "main",

    -- Simple configuration using opts table (preferred)
    opts = {
      linters_by_ft = {
        terraform = { "trivy" },
        javascript = { "trivy" },
        typescript = { "trivy" },
        vue = { "trivy" },
      },
    },

    -- Complex configuration using config function
    config = function()
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          -- try_lint without arguments runs the linters defined in `linters_by_ft`
          -- for the current filetype
          require("lint").try_lint()

          -- You can call `try_lint` with a linter name or a list of names to always
          -- run specific linters, independent of the `linters_by_ft` configuration
          -- require("lint").try_lint("cspell")
        end,
      })
    end,

    -- Run build command after installing/updating
    -- build = "make",
    -- build = ":TSUpdate",

    -- Plugin settings for specific environment
    -- cond = function()
    --   return vim.fn.executable("git") == 1
    -- end,

    -- Uncomment section(s) above to enable them
  },
}
