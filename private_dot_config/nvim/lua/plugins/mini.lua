return {
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
      require("mini.ai").setup()
      require("mini.pairs").setup()
      require("mini.splitjoin").setup()
      -- mini.operators keymaps conflict with default mappings added in neovim 0.11
      -- https://neovim.io/doc/user/news-0.11.html
      -- require("mini.operators").setup()

      require("mini.icons").setup()
      MiniIcons.mock_nvim_web_devicons()

      local gen_loader = require("mini.snippets").gen_loader
      require("mini.snippets").setup({
        snippets = {
          -- Load custom file with global snippets first (adjust for Windows)
          gen_loader.from_file("~/.config/nvim/snippets/global.json"),

          -- Load snippets based on current language by reading files from
          -- "snippets/" subdirectories from 'runtimepath' directories.
          gen_loader.from_lang(),
        },
      })
      require("mini.keymap").setup()

      -- Setup that works well with 'mini.completion' and 'mini.pairs':
      local map_multistep = require("mini.keymap").map_multistep

      map_multistep("i", "<Tab>", { "pmenu_next" })
      map_multistep("i", "<S-Tab>", { "pmenu_prev" })
      map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
      map_multistep("i", "<BS>", { "minipairs_bs" })

      local map_combo = require("mini.keymap").map_combo

      -- "Better escape" to Normal mode without having to reach for <Esc> key:
      -- Support most common modes. This can also contain 't', but would
      -- only mean to press `<Esc>` inside terminal.
      local mode = { "i", "c", "x", "s" }
      map_combo(mode, "jk", "<BS><BS><Esc>")

      -- To not have to worry about the order of keys, also map "kj"
      map_combo(mode, "kj", "<BS><BS><Esc>")

      -- Escape into Normal mode from Terminal mode
      map_combo("t", "jk", "<BS><BS><C-\\><C-n>")
      map_combo("t", "kj", "<BS><BS><C-\\><C-n>")

      vim.g.minipick_disable = true
    end,
  },
}
