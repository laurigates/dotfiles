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
      local ollama = require('model.providers.ollama')
      local mode = require('model').mode
      local function input_if_selection(input, context)
        return context.selection and input or ''
      end
      local openai_chat = {
        provider = openai,
        system = 'You are a helpful assistant',
        params = {
          model = 'gpt-3.5-turbo-1106',
        },
        create = input_if_selection,
        run = function(messages, config)
          if config.system then
            table.insert(messages, 1, {
              role = 'system',
              content = config.system,
            })
          end

          return { messages = messages }
        end,
      }

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
          ['ollama:starling'] = {
            provider = ollama,
            params = {
              model = 'starling-lm'
            },
            builder = function(input)
              return {
                prompt = 'GPT4 Correct User: ' .. input .. '<|end_of_turn|>GPT4 Correct Assistant: '
              }
            end
          },
          ['ollama:dolphin-mixtral'] = {
            provider = ollama,
            params = {
              model = 'dolphin-mixtral:8x7b'
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
                    content = "You are a senior programmer in a pair programming setting.",
                  },
                  { role = "user", content = input },
                },
              }
            end
          },
          ["code:13b.Q5_K_M"] = {
            provider = llamacpp,
            options = {
              -- https://github.com/gsuuon/model.nvim
              -- https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md
              -- https://huggingface.co/TheBloke/CodeLlama-13B-oasst-sft-v10-GGUF
              -- Should test a lighter model to speed things up
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
          ["code:13b-instruct-balanced"] = {
            provider = llamacpp,
            options = {
              -- https://github.com/gsuuon/model.nvim
              -- https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md
              model = "codellama-13b-instruct.Q4_K_M.gguf",
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
                        .. (user_input or "You are a senior programmer in a pair programming setting.")
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
          mixcommit = {
            provider = ollama,
            mode = mode.INSERT,
            builder = function()
              local git_diff = vim.fn.system({ 'git', 'diff', '--staged' })

              if not git_diff:match('^diff') then
                error('Git error:\n' .. git_diff)
              end

              return {
                prompt = "<|im_start|>system\n"
                    .. "You are an expert programmer and git user.\n"
                    .. "<|im_end|>\n"
                    .. "<|im_start|>user\n"
                    ..
                    'Write a terse commit message according to the Conventional Commits specification. Try to stay below 80 characters total. Staged git diff: ```\n'
                    .. git_diff
                    .. '\n```'
                    .. "<|im_end|>\n"
                    .. "<|im_start|>assistant",
              }
            end,
          },
          commit = {
            provider = openai,
            system =
            "You are an expert programmer and git user.",
            mode = mode.INSERT,
            params = {
              model = 'gpt-4-0125-preview',
            },
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
                        'Write a terse commit message according to the Conventional Commits specification. Try to stay below 80 characters total. Dont surround the commit message with backticks. Staged git diff: ```\n'
                        .. git_diff
                        .. '\n```',
                  },
                },
              }
            end,
          },
        },
        chats = {
          ['gpt4:daily tips'] = {
            provider = openai,
            system =
            "You are an expert cloud engineer and teacher. You are the best at giving concise tips and suggestions about terminal tools, configuration management, automation, CI/CD pipelines and Linux.",
            params = {
              model = 'gpt-4-0125-preview',
            },
            create = function()
              -- local git_diff = vim.fn.system({ 'git', 'diff', '--staged' })
              -- ---@cast git_diff string
              --
              -- if not git_diff:match('^diff') then
              --   error('Git error:\n' .. git_diff)
              -- end
              --
              -- return git_diff
              return "Give me a tip-of-the day."
            end,
            run = openai_chat.run,
          },
          ['gpt4:commit review'] = {
            provider = openai,
            system =
            "You are an expert programmer that gives constructive feedback. Review the changes in the user's git diff.",
            params = {
              model = 'gpt-4-0125-preview',
            },
            create = function()
              local git_diff = vim.fn.system({ 'git', 'diff', '--staged' })
              ---@cast git_diff string

              if not git_diff:match('^diff') then
                error('Git error:\n' .. git_diff)
              end

              return git_diff
            end,
            run = openai_chat.run,
          },
        }
      })
    end,
  },
}
