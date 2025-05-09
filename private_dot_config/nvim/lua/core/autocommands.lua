-----------------------------------------------------------
-- Autocommands
-----------------------------------------------------------
local cmd = vim.cmd -- Execute Vim commands

-- Open files above the fugitive buffer
-- cmd([[au BufEnter FugitiveIndex setlocal splitbelow=false]])

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
-- Don't auto commenting new lines
-- cmd([[au BufEnter * set fo-=c fo-=r fo-=o]])

-- Remove line lenght marker for selected filetypes
-- cmd [[autocmd FileType text,markdown,html,xhtml,javascript setlocal cc=0]]

-- Return to last edit position when opening files
cmd([[
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
]])

-- Configure file to load automatically if changed outside vim
cmd([[
  autocmd FocusGained * checktime
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

-- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
--     pattern = { "Dockerfile" },
--     desc = "Autoformat Dockerfile",
--     callback = function()
--         local fileName = vim.api.nvim_buf_get_name(0)
--         vim.cmd(":silent !hadolint " .. fileName)
--         -- vim.cmd(":silent !isort --profile black --float-to-top -q " .. fileName)
--         -- vim.cmd(":silent !docformatter --in-place --black " .. fileName)
--     end,
--     group = autocmd_group,
-- })

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

cmd([[
  au BufRead *zshrc setlocal foldmethod=marker
]])

cmd([[
  augroup SmartCommitMessage
    autocmd!
    autocmd BufRead,BufNewFile COMMIT_EDITMSG call SmartCommitMessage()
  augroup END

  function! SmartCommitMessage()
    " Move the cursor to the start of the buffer
    execute 'normal! gg0'

    " Execute the CodeCompanion command
    CodeCompanion gemini Write a terse commit message conforming to conventional commit standards. Specify the target or area of concern of the change in parentheses after the change type e.g. fix(helm/moodle) or feat(apps/moodleb)). #buffer
  endfunction
]])
