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
			{ "<C-m>d", ":Mdelete<cr>", mode = "n" },
			{ "<C-m>s", ":Mselect<cr>", mode = "n" },
			{ "<C-m><space>", ":Mchat<cr>", mode = "n" },
		},
		config = function()
			require("model.providers.llamacpp").setup({
				binary = "~/repos/llama.cpp/server",
				models = "~/llm-models",
			})

			local llamacpp = require("model.providers.llamacpp")
			local llama2 = require("model.format.llama2")

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
				},
			})
		end,
	},
}
