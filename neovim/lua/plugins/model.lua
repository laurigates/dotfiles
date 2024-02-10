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
      require("model.providers.llamacpp").setup({
        binary = "~/repos/llama.cpp/server",
        models = "~/llm-models",
      })
      local openai = require("model.providers.openai")
      local llamacpp = require("model.providers.llamacpp")
      local llama2 = require("model.format.llama2")
      local mode = require('model').mode

      require("model").setup({
        default_prompt = {
          provider = llamacpp,
          options = {
            -- https://github.com/gsuuon/model.nvim
            -- https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md
            -- https://huggingface.co/TheBloke/CodeLlama-13B-oasst-sft-v10-GGUF
            model = "codellama-13b-oasst-sft-v10.Q5_K_M.gguf",
            args = {
              "-c",
              8192,
              "-ngl",
              32,
            },
          },
          builder = function(input)
            return function(build)
              vim.ui.input({ prompt = "Instruction: " }, function(user_input)
                build({
                  prompt = "<|im_start|>system\n"
                      .. (user_input or "You are a helpful assistant")
                      .. "<|im_end|>\n"
                      .. "<|im_start|>user\n"
                      .. input
                      .. "<|im_end|>\n"
                      .. "<|im_start|>assistant",
                })
              end)
            end
          end,
        },
        prompts = {
          ["openai"] = {
            provider = openai,
            builder = function(input)
              return {
                model = "gpt-4",
                temperature = 0.3,
                max_tokens = 400,
                messages = {
                  {
                    role = "system",
                    content = "You are helpful assistant.",
                  },
                  { role = "user", content = input },
                },
              }
            end
          },
          ["llamacpp:codellama"] = {
            provider = llamacpp,
            options = {
              -- https://github.com/gsuuon/model.nvim
              -- https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md
              -- https://huggingface.co/TheBloke/CodeLlama-13B-oasst-sft-v10-GGUF
              model = "codellama-13b-oasst-sft-v10.Q5_K_M.gguf",
              args = {
                "-c",
                8192,
                "-ngl",
                32,
              },
            },
            builder = function(input, context)
              return {
                prompt = "<|im_start|>system\n"
                    .. (context.args or "You are a helpful assistant")
                    .. "<|im_end|>\n"
                    .. "<|im_start|>user\n"
                    .. input
                    .. "<|im_end|>\n"
                    .. "<|im_start|>assistant",
              }
            end,
          },
          commit = {
            provider = openai,
            mode = mode.INSERT,
            builder = function()
              local git_diff = vim.fn.system({ 'git', 'diff', '--staged' })

              if not git_diff:match('^diff') then
                error('Git error:\n' .. git_diff)
              end

              return {
                messages = {
                  {
                    role = 'user',
                    content =
                        'Write a terse commit message according to the Conventional Commits specification. Try to stay below 80 characters total. Staged git diff: ```\n'
                        .. git_diff
                        .. '\n```',
                  },
                },
              }
            end,
          },
        },
      })
    end,
  },
}
