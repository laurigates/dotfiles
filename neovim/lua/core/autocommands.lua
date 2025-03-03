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

-- AI commit message suggestion
-- Make functions available globally so they can be called from the autocommand
_G.is_commit_message_empty = function()
  -- Get all lines up to the first comment
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    if string.match(line, "^#") then
      -- Only check lines before the first comment
      for j = 1, i - 1 do
        -- If we find any non-empty line before comments, message isn't empty
        if not string.match(lines[j], "^%s*$") then
          return false
        end
      end
      return true
    end
  end
  return true
end

_G.get_commit_type = function()
  local buffer_name = vim.fn.bufname()

  if string.match(buffer_name, "COMMIT_EDITMSG") then
    -- Check for rebase
    if vim.fn.search([[^# This is a combination of]], "n") > 0 then
      return "rebase"
      -- Check for merge
    elseif vim.fn.search([[^# This is the commit message for a merge]], "n") > 0 then
      return "merge"
      -- Check for regular commit
    elseif vim.fn.search([[^# Please enter the commit message for your changes]], "n") > 0 and
        vim.fn.search([[^# This is a combination of]], "n") == 0 then
      return "commit"
    end
  end
  return "unknown"
end

_G.prompt_user = function(msg)
  local response = vim.fn.input(msg .. " (y/n): ")
  return string.lower(response) == "y"
end

_G.smart_commit_message = function()
  -- Only proceed if commit message area is empty
  if not _G.is_commit_message_empty() then
    return
  end

  local commit_type = _G.get_commit_type()

  -- Handle different commit types
  if commit_type == "commit" then
    if _G.prompt_user("Generate commit message using Gemini?") then
      vim.cmd('M commit:gemini')
    end
  elseif commit_type == "rebase" then
    -- Do nothing during rebase
    return
  elseif commit_type == "merge" then
    -- Optionally handle merge commits differently
    if _G.prompt_user("Generate merge commit message using Gemini?") then
      vim.cmd('M commit:gemini')
    end
  end
end

-- Set up the autocommand
vim.cmd([[
  augroup SmartCommitMessage
    autocmd!
    autocmd BufRead,BufNewFile *.git/COMMIT_EDITMSG lua smart_commit_message()
  augroup END
]])
