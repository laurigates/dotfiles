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

-- Define the autocommand logic first
local function trigger_smart_commit_message_prompt()
  -- Debug info
  vim.notify("Smart commit autocommand triggered!", vim.log.levels.INFO)

  -- Check if we are in a git repository before running git commands
  if vim.fn.isdirectory(".git") == 0 then
    vim.notify("Not in a git repository", vim.log.levels.WARN)
    return
  end

  local staged_diff_lines = vim.fn.systemlist("git diff --staged --word-diff --diff-algorithm histogram")

  if vim.v.shell_error ~= 0 then
    local error_message = "Claude SmartCommit: Failed to get git diff --staged."
    if staged_diff_lines and #staged_diff_lines > 0 then
      error_message = error_message .. " Error: " .. table.concat(staged_diff_lines, "\n")
    end
    vim.notify(error_message, vim.log.levels.ERROR)
    return
  end

  -- If there are no staged changes, do nothing.
  if #staged_diff_lines == 0 then
    return
  end

  local staged_diff = table.concat(staged_diff_lines, "\n")

  -- Create a prompt for the claude CLI
  local commit_prompt = [[Generate a concise conventional commit message from this git diff.
Output only the commit message itself, without any additional explanations or formatting.
Focus on summarizing the changes clearly and concisely following conventional commit standards.

Examples:
feat: add user authentication endpoint
fix: resolve issue with null pointer in payment processing
docs: update README with setup instructions

Git diff:
]] .. staged_diff

  -- Use claude CLI to generate the commit message
  local claude_cmd = { "claude", "--model", "sonnet", commit_prompt }

  vim.fn.jobstart(claude_cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local message = table.concat(data, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
        if message ~= "" then
          vim.notify("Generated commit message:\n" .. message)
          -- Optionally, insert the message into the commit buffer
          if vim.bo.filetype == "gitcommit" then
            vim.api.nvim_buf_set_lines(0, 0, 0, false, vim.split(message, "\n"))
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, "\n")
        vim.notify("Claude SmartCommit Error: " .. error_msg, vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify("Claude CLI exited with code: " .. code, vim.log.levels.ERROR)
      end
    end,
  })
end

-- Renamed augroup slightly to avoid conflict if an old one is somehow still lingering from other files
local smart_commit_augroup = vim.api.nvim_create_augroup("SmartCommitMessageLuaInPromptFile", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufEnter" }, {
  pattern = { "*/.git/COMMIT_EDITMSG", "COMMIT_EDITMSG" },
  group = smart_commit_augroup,
  callback = trigger_smart_commit_message_prompt,
})

-- Also add a filetype-based autocommand as backup
vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  group = smart_commit_augroup,
  callback = function()
    -- Only trigger if the buffer name contains COMMIT_EDITMSG
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname:match("COMMIT_EDITMSG") then
      trigger_smart_commit_message_prompt()
    end
  end,
})
