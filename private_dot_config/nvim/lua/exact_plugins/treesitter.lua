-- Nvim Treesitter — main-branch rewrite (the old master branch and its
-- nvim-treesitter.configs module are archived). Parsers install via
-- require("nvim-treesitter").install(); highlighting and indentation are
-- enabled per-buffer in the FileType autocommand below using Neovim's
-- built-in vim.treesitter. Requires nvim 0.12+ and the tree-sitter CLI
-- (installed via mise: aqua:tree-sitter/tree-sitter).
--
-- Dropped relative to the master-branch config:
-- - incremental_selection: removed upstream; flash.nvim's `S` (Treesitter)
--   covers it.
-- - textsubjects (`.` / `;` / `i;`): master-only, incompatible with the
--   main branch (RRethy/nvim-treesitter-textsubjects#52).
-- - lsp_interop peek (`<leader>df` / `<leader>dF`): removed upstream.

local ensure_installed = {
  "regex",
  "bash",
  "c",
  "diff",
  "dockerfile",
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "graphql",
  "http",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "terraform",
  "toml",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

return {
  {
    "windwp/nvim-ts-autotag",
    opts = {},
  },
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- upstream: does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      -- Async; no-op for parsers that are already installed
      require("nvim-treesitter").install(ensure_installed)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match) or args.match
          local function start(buf)
            if not pcall(vim.treesitter.start, buf, lang) then
              return false
            end
            -- Experimental treesitter indentation (old `indent = { enable = true }`)
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            return true
          end
          if start(args.buf) then
            return
          end
          -- Parser not installed yet: auto-install supported languages,
          -- then retry (replaces the old `auto_install = true`)
          if require("nvim-treesitter.parsers")[lang] then
            require("nvim-treesitter").install(lang):await(function()
              if vim.api.nvim_buf_is_valid(args.buf) then
                start(args.buf)
              end
            end)
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "V", -- linewise
            ["@class.outer"] = "<c-v>", -- blockwise
          },
          include_surrounding_whitespace = true,
        },
      })

      local function select_textobject(query, group)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, group or "textobjects")
        end
      end
      vim.keymap.set({ "x", "o" }, "af", select_textobject("@function.outer"), { desc = "Select outer function" })
      vim.keymap.set({ "x", "o" }, "if", select_textobject("@function.inner"), { desc = "Select inner function" })
      vim.keymap.set({ "x", "o" }, "ac", select_textobject("@class.outer"), { desc = "Select outer class" })
      vim.keymap.set({ "x", "o" }, "ic", select_textobject("@class.inner"), { desc = "Select inner class" })
      vim.keymap.set(
        { "x", "o" },
        "as",
        select_textobject("@local.scope", "locals"),
        { desc = "Select language scope" }
      )
    end,
  },
}
