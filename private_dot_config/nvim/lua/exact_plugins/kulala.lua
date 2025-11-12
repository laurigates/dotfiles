return {
  {
    "mistweaverco/kulala.nvim",
    keys = {
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Rb", desc = "Open scratchpad" },
    },
    ft = { "http", "rest" },
    opts = {
      -- your configuration comes here
      global_keymaps = false,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps_prefix = "",
    },
  },
}
