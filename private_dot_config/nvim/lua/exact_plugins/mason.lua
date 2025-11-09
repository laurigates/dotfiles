-- Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters.
return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {},
    dependencies = {
      "williamboman/mason.nvim",
    },
    event = "VeryLazy",
  },
  {
    "williamboman/mason.nvim",
    opts = {
      -- Ensure compilers can be found
      PATH = "prepend",
      -- Try to use system compilers first
      registries = {
        "github:mason-org/mason-registry",
      },
      providers = {
        "mason.providers.registry-api",
        "mason.providers.client",
      },
    },
    event = "VeryLazy",
  },
  {
    "hasansujon786/nvim-navbuddy",
    dependencies = {
      "SmiteshP/nvim-navic",
      "MunifTanjim/nui.nvim",
    },
    opts = { lsp = { auto_attach = true } },
    event = "VeryLazy",
  },
  {
    "b0o/schemastore.nvim",
    event = "VeryLazy",
  },
}
