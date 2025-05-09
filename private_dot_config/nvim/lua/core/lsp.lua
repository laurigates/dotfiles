-- local navic = require("nvim-navic")
--
-- local on_attach = function(client, bufnr)
--   if client.server_capabilities.documentSymbolProvider then
--     navic.attach(client, bufnr)
--   end
-- end
--
-- local capabilities = require("blink.cmp").get_lsp_capabilities()
--
-- require("mason").setup()
-- require("mason-lspconfig").setup()
--
-- require("mason-lspconfig").setup_handlers({
--   -- The first entry (without a key) will be the default handler
--   -- and will be called for each installed server that doesn't have
--   -- a dedicated handler.
--   function(server_name) -- default handler (optional)
--     require("lspconfig")[server_name].setup({
--       on_attach = on_attach,
--       capabilities = capabilities,
--     })
--   end,
-- })

-- Add the same capabilities to ALL server configurations.
-- Refer to :h vim.lsp.config() for more information.
vim.lsp.config("*", {
  capabilities = vim.lsp.protocol.make_client_capabilities(),
})

require("mason").setup()
require("mason-lspconfig").setup({
  -- ensure_installed = { "rust_analyzer", "lua_ls" }
})

vim.keymap.set({ "n", "x" }, "<leader>a", '<cmd>lua require("fastaction").code_action()<CR>', { buffer = bufnr })
