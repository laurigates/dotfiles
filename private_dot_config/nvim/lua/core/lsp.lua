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
    -- Attach nvim-navic if available and client supports document symbols
    if client.server_capabilities.documentSymbolProvider then
      local navic_ok, navic = pcall(require, "nvim-navic")
      if navic_ok then
        navic.attach(client, bufnr)
      end
    end
    -- Set up fastaction keymap for this buffer if available
    local fastaction_ok, _ = pcall(require, "fastaction")
    if fastaction_ok then
      vim.keymap.set({ "n", "x" }, "<leader>a", '<cmd>lua require("fastaction").code_action()<CR>', { buffer = bufnr })
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

-- Configure jsonls with schemastore if available
local schemastore_ok, schemastore = pcall(require, "schemastore")
vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = schemastore_ok and schemastore.json.schemas() or {},
      validate = { enable = true },
    },
  },
})

-- Configure Arduino Language Server
-- Requires: arduino-cli and arduino-language-server installed via Mason
vim.lsp.config("arduino_language_server", {
  cmd = {
    "arduino-language-server",
    "-cli-config",
    vim.fn.expand("~/.arduino15/arduino-cli.yaml"),
    "-fqbn",
    "arduino:avr:uno", -- Default FQBN, can be overridden per project
    "-cli",
    "arduino-cli",
    "-clangd",
    "clangd",
  },
  filetypes = { "arduino", "ino" },
  root_markers = { "*.ino" },
})

-- Enable configured LSP servers
-- Note: Servers must be installed via Mason (:Mason) before they can be enabled
vim.lsp.enable("terraformls")
vim.lsp.enable("jsonls")
vim.lsp.enable("arduino_language_server")

-- Additional LSP server examples (uncomment and configure as needed):
--
-- Lua Language Server
-- vim.lsp.config("lua_ls", {
--   settings = {
--     Lua = {
--       runtime = { version = "LuaJIT" },
--       diagnostics = { globals = { "vim" } },
--       workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
--       telemetry = { enable = false },
--     },
--   },
-- })
-- vim.lsp.enable("lua_ls")
--
-- Rust Analyzer (Note: This repository uses rustaceanvim for rust-analyzer)
-- vim.lsp.enable("rust_analyzer")
--
-- Python LSP (pyright)
-- vim.lsp.enable("pyright")
--
-- TypeScript/JavaScript LSP
-- vim.lsp.enable("ts_ls")
--
-- Go LSP
-- vim.lsp.enable("gopls")
--
-- YAML LSP
-- vim.lsp.enable("yamlls")
--
-- For more LSP servers, see: https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/configs.lua
