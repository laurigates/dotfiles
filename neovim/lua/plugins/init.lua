return {
  {
    "mrjones2014/legendary.nvim",
    -- since legendary.nvim handles all your keymaps/commands,
    -- its recommended to load legendary.nvim before other plugins
    priority = 10000,
    lazy = false,
    -- sqlite is only needed if you want to use frecency sorting
    dependencies = { "kkharji/sqlite.lua" },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      picker = { enabled = true },
      git = { enabled = true },
      gitbrowse = { enabled = true },
      bigfile = { enabled = true },
      scroll = { enabled = true },
      animate = { enabled = true },
      bufdelete = { enabled = true },
      dim = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      rename = { enabled = true },
      scope = { enabled = true },
      util = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      quickfile = { enabled = true },
      dashboard = { enabled = true },
      -- statuscolumn = { enabled = true },
      words = { enabled = true },
      styles = {
        notification = {
          wo = { wrap = true }, -- Wrap notifications
        },
      },
    },
    keys = {
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
      },
      {
        "<leader>bd",
        function()
          Snacks.bufdelete()
        end,
        desc = "Delete Buffer",
      },
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>gb",
        function()
          Snacks.git.blame_line()
        end,
        desc = "Git Blame Line",
      },
      {
        "<leader>gB",
        function()
          Snacks.gitbrowse()
        end,
        desc = "Git Browse",
      },
      {
        "<leader>gf",
        function()
          Snacks.lazygit.log_file()
        end,
        desc = "Lazygit Current File History",
      },
      {
        "<leader>gl",
        function()
          Snacks.lazygit.log()
        end,
        desc = "Lazygit Log (cwd)",
      },
      {
        "<leader>cR",
        function()
          Snacks.rename.rename_file()
        end,
        desc = "Rename File",
      },
      {
        "<c-/>",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle Terminal",
      },
      {
        "<c-_>",
        function()
          Snacks.terminal()
        end,
        desc = "which_key_ignore",
      },
      {
        "]]",
        function()
          Snacks.words.jump(vim.v.count1)
        end,
        desc = "Next Reference",
        mode = { "n", "t" },
      },
      {
        "[[",
        function()
          Snacks.words.jump(-vim.v.count1)
        end,
        desc = "Prev Reference",
        mode = { "n", "t" },
      },
      {
        "<leader>N",
        desc = "Neovim News",
        function()
          Snacks.win({
            file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
            width = 0.6,
            height = 0.6,
            wo = {
              spell = false,
              wrap = false,
              signcolumn = "yes",
              statuscolumn = " ",
              conceallevel = 3,
            },
          })
        end,
      },
      -- https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#-examples
      --     { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader><space>",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      -- find
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find Config File",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Find Git Files",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent",
      },
      {
        "<leader>fh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help",
      },
      {
        "<leader>fm",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Create some toggle mappings
          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.line_number():map("<leader>ul")
          Snacks.toggle
            .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
            :map("<leader>uc")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
          Snacks.toggle.inlay_hints():map("<leader>uh")
        end,
      })
    end,
  },
  -- "folke/which-key.nvim",
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "folke/neoconf.nvim",
    cmd = "Neoconf",
    opts = {},
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
  },
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.surround").setup({
        custom_surroundings = {
          ["c"] = { output = { left = "`", right = "`" } },
          ["C"] = { output = { left = "```\n", right = "\n```" } },
        },
      })
      -- require("mini.pick").setup()
      require("mini.ai").setup()
      -- require("mini.indentscope").setup()
      require("mini.pairs").setup()
      require("mini.splitjoin").setup()
      require("mini.operators").setup()
      -- require('mini.jump').setup()
      -- require('mini.jump2d').setup()
      -- local miniclue = require('mini.clue')
      -- miniclue.setup({
      --   triggers = {
      --     -- Leader triggers
      --     -- Disabled because it messes with <leader>f
      --     -- { mode = 'n', keys = '<Leader>' },
      --     -- { mode = 'x', keys = '<Leader>' },
      --
      --     -- Built-in completion
      --     { mode = 'i', keys = '<C-x>' },
      --
      --     -- `g` key
      --     { mode = 'n', keys = 'g' },
      --     { mode = 'x', keys = 'g' },
      --
      --     -- Marks
      --     { mode = 'n', keys = "'" },
      --     { mode = 'n', keys = '`' },
      --     { mode = 'x', keys = "'" },
      --     { mode = 'x', keys = '`' },
      --
      --     -- Registers
      --     { mode = 'n', keys = '"' },
      --     { mode = 'x', keys = '"' },
      --     { mode = 'i', keys = '<C-r>' },
      --     { mode = 'c', keys = '<C-r>' },
      --
      --     -- Window commands
      --     { mode = 'n', keys = '<C-w>' },
      --
      --     -- `z` key
      --     { mode = 'n', keys = 'z' },
      --     { mode = 'x', keys = 'z' },
      --   },
      --
      --   clues = {
      --     -- Enhance this by adding descriptions for <Leader> mapping groups
      --     miniclue.gen_clues.builtin_completion(),
      --     miniclue.gen_clues.g(),
      --     miniclue.gen_clues.marks(),
      --     miniclue.gen_clues.registers(),
      --     miniclue.gen_clues.windows(),
      --     miniclue.gen_clues.z(),
      --   },
      -- })
    end,
  },
  "tpope/vim-speeddating",
  "tpope/vim-eunuch",
  "tpope/vim-rhubarb",
  -- nvim-bisquits makes large files load extremely slowly
  -- {
  --   "code-biscuits/nvim-biscuits",
  --   opts = {
  --     cursor_line_only = true,
  --     default_config = {
  --       -- max_length = 12,
  --       -- min_distance = 5,
  --       prefix_string = "📎"
  --     },
  --     -- language_config = {
  --     --   html = {
  --     --     prefix_string = " 🌐 "
  --     --   },
  --     --   javascript = {
  --     --     prefix_string = " ✨ ",
  --     --     max_length = 80
  --     --   },
  --     --   python = {
  --     --     disabled = true
  --     --   }
  --     -- }
  --   }
  -- },
  {
    "brenoprata10/nvim-highlight-colors",
    opts = {},
  },
  "tris203/precognition.nvim",
  "towolf/vim-helm", -- Required for helm filetype detection (could probably just copy the ftdetect file)
  -- {
  --   'altermo/ultimate-autopair.nvim',
  --   event = { 'InsertEnter', 'CmdlineEnter' },
  --   branch = 'v0.6',   --recommended as each new version will have breaking changes
  --   opts = {
  --     --Config goes here
  --   },
  -- }
  "stevearc/vim-arduino",
  -- {
  --   "nvimtools/none-ls.nvim",
  --   dependencies = {
  --     "nvimtools/none-ls-extras.nvim",
  --   },
  --   config = function()
  --     local null_ls = require("null-ls")
  --
  --     null_ls.setup({
  --       sources = {
  --         null_ls.builtins.formatting.stylua,
  --         null_ls.builtins.completion.spell,
  --         require("none-ls.formatting.jq"),
  --         require("none-ls.diagnostics.eslint"), -- requires none-ls-extras.nvim
  --       },
  --     })
  --   end,
  -- },
  {
    "nmac427/guess-indent.nvim",
    opts = {},
  },
}
