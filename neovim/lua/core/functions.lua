-- Ensure you have lua-curl installed: luarocks install lua-curl
local curl = require("cURL")

local function is_url(text)
  local url_pattern = "^https?://[%w-_%.%?%.:/%+=&]+$"
  return string.match(text, url_pattern) ~= nil
end

local function get_url_title(url)
  local easy = curl.easy {
    url = url,
    followlocation = true, -- Follow redirects if needed
    timeout = 5,           -- Set a timeout to avoid hanging
  }

  local title = ""
  easy:setopt_writefunction(function(data)
    -- Look for the title tag within chunks of data
    local match = data:match("<title>([^<]+)</title>")
    if match then title = match end
    return #data -- Return the number of bytes processed
  end)

  easy:perform()
  easy:close()

  if title == "" then
    return "No Title Found"
  else
    return title:gsub("\n", " "):gsub("%s+", " ") -- Clean up whitespace
  end
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
