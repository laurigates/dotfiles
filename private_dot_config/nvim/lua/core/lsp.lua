-- Add the same capabilities to ALL server configurations.
-- Refer to :h vim.lsp.config() for more information.
vim.lsp.config("*", {
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  on_attach = function(client, bufnr)
    if client.server_capabilities.documentSymbolProvider then
      require("nvim-navic").attach(client, bufnr)
    end
  end,
})

require("mason").setup()
require("mason-lspconfig").setup({
  -- ensure_installed = { "rust_analyzer", "lua_ls" }
})

vim.lsp.config("terraformls", {
  settings = {
    ["terraform"] = {
      experimentalFeatures = { prefillRequiredFields = true, validateOnSave = true },
    },
  },
})

vim.keymap.set({ "n", "x" }, "<leader>a", '<cmd>lua require("fastaction").code_action()<CR>', { buffer = bufnr })
