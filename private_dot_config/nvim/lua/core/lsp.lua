-- Add the same capabilities to ALL server configurations.
-- Refer to :h vim.lsp.config() for more information.
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- Check if blink.cmp is available and merge capabilities
local ok, blink = pcall(require, "blink.cmp")
if ok then
  capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
end

-- Add onTypeFormatting capability for blink.cmp compatibility
capabilities.textDocument.onTypeFormatting = { dynamicRegistration = false }

vim.lsp.config("*", {
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    if client.server_capabilities.documentSymbolProvider then
      require("nvim-navic").attach(client, bufnr)
    end
  end,
})

-- Enable LSP on-type formatting
vim.lsp.on_type_formatting.enable()

-- Server-specific configurations
vim.lsp.config("terraformls", {
  settings = {
    ["terraform"] = {
      experimentalFeatures = { prefillRequiredFields = true, validateOnSave = true },
    },
  },
})

vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})

-- Enable configured LSP servers
-- Note: Servers must be installed via Mason (:Mason) before they can be enabled
vim.lsp.enable("terraformls")
vim.lsp.enable("jsonls")

vim.keymap.set({ "n", "x" }, "<leader>a", '<cmd>lua require("fastaction").code_action()<CR>', { buffer = bufnr })
