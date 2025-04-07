return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      "<leader>fo",
      function()
        require("conform").format({ async = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  -- This will provide type hinting with LuaLS
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "ruff", "autopep8" },
      dockerfile = { "hadolint" },
      gitconfig = { "taplo" },
      vue = { "eslint_d" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      javascript = { "eslint_d" },
      json = { "prettierd", "prettier", stop_after_first = true },
      jsonc = { "prettierd", "prettier", stop_after_first = true },
      ["*"] = { "codespell" },
      ["_"] = { "trim_whitespace" },
    },
    -- Set default options
    default_format_opts = {
      lsp_format = "fallback",
    },
    -- Set up format-on-save
    format_on_save = { timeout_ms = 500 },
    -- Customize formatters
    formatters = {
      shfmt = {
        prepend_args = { "-i", "2" },
      },
    },
  },
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
-- return {
--   {
--     "stevearc/conform.nvim",
--     opts = {
--       formatters_by_ft = {
--         lua = { "stylua" },
--         python = { "isort", "ruff", "autopep8" },
--         dockerfile = { "hadolint" },
--         gitconfig = { "taplo" },
--         vue = { "eslint_d" },
--         typescript = { "eslint_d" },
--         typescriptreact = { "eslint_d" },
--         javascript = { "eslint_d" },
--         json = { { "prettierd", "prettier" } },
--         jsonc = { { "prettierd", "prettier" } },
--         ["*"] = { "codespell" },
--         ["_"] = { "trim_whitespace" },
--       },
--       format_on_save = function(bufnr)
--         -- Disable with a global or buffer-local variable
--         if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
--           return
--         end
--         return { timeout_ms = 500, lsp_fallback = true }
--       end,
--     },
--     config = function()
--       vim.api.nvim_create_user_command("FormatDisable", function(args)
--         if args.bang then
--           -- FormatDisable! will disable formatting just for this buffer
--           vim.b.disable_autoformat = true
--         else
--           vim.g.disable_autoformat = true
--         end
--       end, {
--         desc = "Disable autoformat-on-save",
--         bang = true,
--       })
--       vim.api.nvim_create_user_command("FormatEnable", function()
--         vim.b.disable_autoformat = false
--         vim.g.disable_autoformat = false
--       end, {
--         desc = "Re-enable autoformat-on-save",
--       })
--     end,
--   },
-- }
