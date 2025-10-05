-----------------------------------------------------------
-- Autocommands
-----------------------------------------------------------
local cmd = vim.cmd -- Execute Vim commands

-- Open files above the fugitive buffer
cmd([[au BufEnter FugitiveIndex setlocal splitbelow=false]])

-- Highlight on yank
cmd([[
augroup YankHighlight
autocmd!
autocmd TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=800}
augroup end
]])

vim.filetype.add({
  pattern = {
    ["Dockerfile%.[%w_]+"] = "dockerfile", -- Matches Dockerfile.nginx, Dockerfile.django, etc.
  },
})
-- Don't auto comment new lines
-- cmd([[au BufEnter * set fo-=c fo-=r fo-=o]])

-- Remove line lenght marker for selected filetypes
-- cmd [[autocmd FileType text,markdown,html,xhtml,javascript setlocal cc=0]]

-- Return to last edit position when opening files
cmd([[
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
]])

cmd([[
  au BufRead,BufNewFile */playbooks/*.yml setlocal ft=yaml.ansible
  au BufRead,BufNewFile */playbooks/*.yaml setlocal ft=yaml.ansible
  au BufRead,BufNewFile */roles/*/tasks/*.yml setlocal ft=yaml.ansible
  au BufRead,BufNewFile */roles/*/tasks/*.yaml setlocal ft=yaml.ansible
  au BufRead,BufNewFile */roles/*/handlers/*.yml setlocal ft=yaml.ansible
  au BufRead,BufNewFile */roles/*/handlers/*.yaml setlocal ft=yaml.ansible
]])

-- local autocmd_group = vim.api.nvim_create_augroup("Custom auto-commands", { clear = true })

-- Open a terminal pane on the right using :Term
-- cmd([[command Term :botright vsplit term://$SHELL]])

-- Terminal visual tweaks:
-- - enter insert mode when switching to terminal
-- - close terminal buffer on process exit
-- cmd [[
--     autocmd TermOpen * setlocal listchars= nonumber norelativenumber nocursorline
--     autocmd TermOpen * startinsert
--     autocmd BufLeave term://* stopinsert
-- ]]

-- Smart commit message generation using Claude
local smart_commit_augroup = vim.api.nvim_create_augroup("SmartCommitMessage", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  group = smart_commit_augroup,
  callback = function()
    -- Only run for COMMIT_EDITMSG files and if buffer is empty
    local bufname = vim.api.nvim_buf_get_name(0)
    if not bufname:match("COMMIT_EDITMSG") then
      return
    end

    -- Check if buffer already has content (don't overwrite)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local has_content = false
    for _, line in ipairs(lines) do
      if line:match("%S") and not line:match("^#") then
        has_content = true
        break
      end
    end
    if has_content then
      return
    end

    -- Get staged diff
    local diff = vim.fn.system("git diff --staged --word-diff --diff-algorithm=histogram")
    if vim.v.shell_error ~= 0 or diff == "" then
      return -- No staged changes or git error
    end

    -- Prepare the prompt with proper escaping
    local prompt = [[Generate a concise conventional commit message from this git diff.
Output only the commit message itself, without any additional explanations or formatting.
Focus on summarizing the changes clearly and concisely following conventional commit standards.

Examples:
feat: add user authentication endpoint
fix: resolve issue with null pointer in payment processing
docs: update README with setup instructions

Git diff:
]] .. diff

    -- Execute claude command synchronously with proper quoting
    local escaped_prompt = vim.fn.shellescape(prompt)
    local gen_cmd = "claude --print --model Sonnet " .. escaped_prompt
    local result = vim.fn.system(gen_cmd)

    if vim.v.shell_error == 0 and result ~= "" then
      -- Clean up the result and insert into buffer
      local message = vim.trim(result)
      if message ~= "" then
        vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(message, "\n"))
      end
    end
  end,
})
