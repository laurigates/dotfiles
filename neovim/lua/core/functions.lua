-- TODO: convert this to lua
-- http://lua-users.org/wiki/GettingTheTitleFromHtmlFiles

-- https://benjamincongdon.me/blog/2020/06/27/Vim-Tip-Paste-Markdown-Link-with-Automatic-Title-Fetching/
-- https://vim.fandom.com/wiki/Make_an_HTML_anchor_and_href_tag
-- https://stackoverflow.com/questions/1115447/how-can-i-get-the-word-under-the-cursor-and-the-text-of-the-current-line-in-vim
local function get_url_title(url)
  local html = os.execute("curl -s " .. url)
  local regex = ".*head.*<title[^>]*>%s*([^%s]*)%s*</title>"
  local title = string.gsub(string.match(html, regex), "\n", " ")
  return title
end

local function paste_md_link()
  local url = vim.fn.getreg('+')
  local title = get_url_title(url)
  vim.fn.put("[", title, "](", url, ")")
end

-- Make a keybinding (mnemonic: "mark down paste")
vim.keymap.set('n', '<Leader>mdp', paste_md_link(), {noremap = true})
