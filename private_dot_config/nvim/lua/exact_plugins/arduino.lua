-- Arduino Language Server Protocol support
-- Install: arduino-cli config init && arduino-cli core install arduino:avr
-- Install LSP: go install github.com/arduino/arduino-language-server@latest
-- Or via Mason: :MasonInstall arduino-language-server
return {
  -- LSP configuration for Arduino is handled in core/lsp.lua
  -- Mason will handle installation of arduino-language-server
  -- The LSP will auto-attach to .ino files

  -- Optional: Install arduino-language-server via Mason automatically
  -- This ensures the LSP is available without manual installation
  {
    "williamboman/mason-lspconfig.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, "arduino_language_server")
    end,
  },
}
