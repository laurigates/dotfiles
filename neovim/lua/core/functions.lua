-- http://lua-users.org/wiki/GettingTheTitleFromHtmlFiles
-- https://benjamincongdon.me/blog/2020/06/27/Vim-Tip-Paste-Markdown-Link-with-Automatic-Title-Fetching/
-- https://vim.fandom.com/wiki/Make_an_HTML_anchor_and_href_tag
-- https://stackoverflow.com/questions/1115447/how-can-i-get-the-word-under-the-cursor-and-the-text-of-the-current-line-in-vim

local function is_url(text)
  local url_pattern = "^https?://[%w-_%.%?%.:/%+=&]+$"
  return string.match(text, url_pattern) ~= nil
end

local function get_url_title(url)
  local handle = io.popen("curl -s " .. url)
  if not handle then
    return "Error fetching URL"
  end

  local html = handle:read("*a")
  handle:close()

  if not html then
    return "Error reading HTML"
  end

  local title = html:match("<title>(.-)</title>")
  if title then
    title = title:gsub("\n", " "):gsub("%s+", " ")
  else
    title = "No Title Found"
  end
  return title
end

local function paste_md_link()
  local url = vim.fn.getreg('+')

  if not is_url(url) then
    print("Clipboard content is not a valid URL")
    return
  end

  local title = get_url_title(url)
  local markdown_link = string.format("[%s](%s)", title, url)

  vim.api.nvim_put({ markdown_link }, 'l', true, true)
end

-- Make a keybinding (mnemonic: "mark down paste")
vim.keymap.set('n', '<Leader>mdp', paste_md_link, { noremap = true, silent = true })
