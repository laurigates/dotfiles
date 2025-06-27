-- Define the autocommand logic first
local function trigger_smart_commit_message_prompt()
  -- Check if we are in a git repository before running git commands
  if vim.fn.isdirectory(".git") == 0 then
    return
  end

  local staged_diff_lines = vim.fn.systemlist("git diff --staged --word-diff --diff-algorithm histogram")

  if vim.v.shell_error ~= 0 then
    local error_message = "CodeCompanion (SmartCommit): Failed to get git diff --staged."
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

  -- Use the CodeCompanion API to run the prompt directly.
  -- This is safer and avoids issues with special characters in the command line.
  require("codecompanion").prompt("SmartCommitMessage", {
    buffer = staged_diff,
  })
end

-- Renamed augroup slightly to avoid conflict if an old one is somehow still lingering from other files
local smart_commit_augroup = vim.api.nvim_create_augroup("SmartCommitMessageLuaInPromptFile", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*/.git/COMMIT_EDITMSG",
  group = smart_commit_augroup,
  callback = trigger_smart_commit_message_prompt,
})

-- Now, return the prompts table
return {
  ["SmartCommitMessage"] = {
    strategy = "chat",
    opts = {
      adapter = "gemini",
      model = "gemini-1.5-flash", -- Or your preferred fast model like gemini-flash
    },
    description = "Generates a conventional commit message from staged git changes.",
    prompts = {
      {
        role = "system",
        content = [[You are an expert at writing concise and conventional commit messages.
The user will provide a git diff. Based on this diff, generate a terse commit message that strictly adheres to conventional commit standards.
The commit message should be a single line if possible, or a short summary line followed by a blank line and then a more detailed body if necessary.
Output *only* the commit message itself, without any additional explanations, greetings, or markdown formatting such as backticks.
Focus on summarizing the changes clearly and concisely.
For example:
feat: add user authentication endpoint
fix: resolve issue with null pointer in payment processing
docs: update README with setup instructions]],
      },
      {
        role = "user",
        content = "", -- This will be populated by the git diff via the #buffer mechanism
      },
    },
  },
}
