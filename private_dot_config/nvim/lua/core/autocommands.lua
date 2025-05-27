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

cmd([[
  augroup SmartCommitMessage
    autocmd!
    autocmd BufRead,BufNewFile COMMIT_EDITMSG call SmartCommitMessage()
  augroup END

  function! SmartCommitMessage()
    " Execute the CodeCompanion command
    CodeCompanion gemini-2.0-flash-lite Write a terse commit message conforming to conventional commit standards. #buffer
  endfunction
]])
