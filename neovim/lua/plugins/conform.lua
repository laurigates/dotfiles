return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- lua = { "stylua" },
        -- Conform will run multiple formatters sequentially
        python = { "isort", "ruff", "autopep8" },
        dockerfile = { "hadolint" },
        gitconfig = { "taplo" },
        ["_"] = { "trim_whitespace" },
        -- Use a sub-list to run only the first available formatter
        -- javascript = { { "prettierd", "prettier" } },
      },
      format_on_save = {
        -- I recommend these options. See :help conform.format for details.
        lsp_fallback = true,
        timeout_ms = 500,
      },
    },
  },
}
