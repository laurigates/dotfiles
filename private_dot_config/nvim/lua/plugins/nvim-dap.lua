return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    keys = {
      { "<F8>",  "<cmd>DapContinue<cr>" },
      { "<F9>",  "<cmd>DapStepInto<cr>" },
      { "<F10>", "<cmd>DapToggleBreakpoint<cr>" },
    },
  },
  {
    "mfussenegger/nvim-dap-python",
    lazy = true,
    config = function()
      require("dap-python").setup()
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" }
  }
}
