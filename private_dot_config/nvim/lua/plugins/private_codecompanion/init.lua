local strategies = require("plugins.codecompanion.strategies")
local prompts = {
  require("plugins.codecompanion.prompts.custom"),
  require("plugins.codecompanion.prompts.arduino"),
  require("plugins.codecompanion.prompts.deployment"),
}

-- Combine all prompts into a single prompt_library table
local prompt_library = {}
for _, prompt_table in ipairs(prompts) do
  for name, config in pairs(prompt_table) do
    prompt_library[name] = config
  end
end

return {
  {
    "olimorris/codecompanion.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
    },
    opts = {
      -- display = {
      --   action_palette = {
      --     provider = "snacks",
      --   },
      -- },
      prompt_library = prompt_library,
      strategies = strategies,
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true,
          },
        },
      },
    },
    keys = {
      {
        "<leader>ch",
        "<cmd>CodeCompanionChat Toggle<cr>",
        desc = "CodeCompanionChat",
      },
      {
        "<leader>cx",
        "<cmd>CodeCompanionActions<cr>",
        desc = "CodeCompanionActions",
      },
    },
  },
}
