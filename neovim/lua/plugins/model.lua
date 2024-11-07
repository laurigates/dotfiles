-- Neovim plugin for interacting with LLM's and building editor integrated prompts.
return {
  {
    "gsuuon/model.nvim",
    -- Don't need these if lazy = false
    cmd = { "M", "Model", "Mchat" },
    init = function()
      vim.filetype.add({
        extension = {
          mchat = "mchat",
        },
      })
    end,
    ft = "mchat",
    keys = {
      { "<C-m>d",       ":Mdelete<cr>", mode = "n" },
      { "<C-m>s",       ":Mselect<cr>", mode = "n" },
      { "<C-m><space>", ":Mchat<cr>",   mode = "n" },
    },
    config = function()
      local gemini = require('model.providers.gemini')
      local mode = require('model').mode
      require("model").setup({
        prompts = {
          -- https://ai.google.dev/gemini-api/docs/text-generation?lang=rest
          ['commit:gemini'] = {
            provider = gemini,
            mode = mode.INSERT,
            builder = function()
              local git_diff = vim.fn.system({ 'git', 'diff', '--staged' })

              if not git_diff:match('^diff') then
                error('Git error:\n' .. git_diff)
              end
              return {
                contents = {
                  {
                    parts = {
                      {
                        text =
                            'Write a concise, terse commit message according to the Conventional Commits specification. Staged git diff: ```\n'
                            .. git_diff
                            .. '\n```',
                      },
                    }
                  },
                },
                generationConfig = {
                  -- stopSequences = {
                  --   "Title"
                  -- },
                  temperature = 1.0,
                  maxOutputTokens = 100,
                  topP = 0.8,
                  topK = 10
                }
              }
            end
          },
        }
      })
    end,
  },
}
