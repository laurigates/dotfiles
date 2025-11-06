-----------------------------------------------------------
-- Core utility functions for Neovim configuration
-----------------------------------------------------------

-----------------------------------------------------------
-- JSON to Lua conversion helper functions
-----------------------------------------------------------

-- Get selected or current line text
-- @return string|nil The selected text or nil if empty
local function get_selected_text()
  local mode = vim.fn.mode()
  local json_text

  if mode == "v" or mode == "V" or mode == "\22" then -- visual modes
    -- Get visually selected text
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    -- Use vim.fn.getregion for accurate visual selection (Neovim 0.10+)
    -- Safer version check to prevent errors
    if vim.fn.has("nvim-0.10") == 1 and type(vim.fn.getregion) == "function" then
      local region = vim.fn.getregion(start_pos, end_pos, { type = mode })
      json_text = table.concat(region, "\n")
    else
      -- Fallback for older versions
      local lines = vim.fn.getline(start_pos[2], end_pos[2])

      if #lines == 1 then
        -- Single line selection
        local start_col = start_pos[3]
        local end_col = mode == "v" and end_pos[3] or #lines[1]
        json_text = string.sub(lines[1], start_col, end_col)
      else
        -- Multi-line selection
        lines[1] = string.sub(lines[1], start_pos[3])
        if mode == "v" then
          lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
        end
        json_text = table.concat(lines, "\n")
      end
    end
  else
    -- Normal mode: get current line
    json_text = vim.fn.getline(".")
  end

  return json_text
end

-- Serialize a Lua object to Lua code string representation
-- @param obj any The Lua object to serialize
-- @param indent number The current indentation level
-- @return string The serialized Lua code
local function serialize_lua_object(obj, indent)
  indent = indent or 0
  local spacing = string.rep("  ", indent)

  if type(obj) == "table" then
    local result = {}
    table.insert(result, "{\n")

    local is_array = true
    local max_index = 0

    -- Check if it's an array (consecutive integer keys starting from 1)
    local count = 0
    for k, _ in pairs(obj) do
      if type(k) ~= "number" or k <= 0 or k ~= math.floor(k) then
        is_array = false
        break
      end
      count = count + 1
      max_index = math.max(max_index, k)
    end

    -- Additional check: ensure no gaps (consecutive keys)
    if is_array and count > 0 and count ~= max_index then
      is_array = false
    end

    if is_array then
      for i = 1, max_index do
        table.insert(result, spacing .. "  ")
        table.insert(result, serialize_lua_object(obj[i], indent + 1))
        table.insert(result, ",\n")
      end
    else
      for k, v in pairs(obj) do
        local key = type(k) == "string" and (k:match("^[%a_][%w_]*$") and k or '["' .. k .. '"]') or "[" .. k .. "]"
        table.insert(result, spacing .. "  " .. key .. " = ")
        table.insert(result, serialize_lua_object(v, indent + 1))
        table.insert(result, ",\n")
      end
    end

    table.insert(result, spacing .. "}")
    return table.concat(result)
  elseif type(obj) == "string" then
    return string.format("%q", obj)
  else
    return tostring(obj)
  end
end

-- Replace buffer content with the converted Lua string
-- @param lua_str string The Lua code string to insert
-- @param mode string The current Vim mode
local function replace_buffer_content(lua_str, mode)
  if mode == "v" or mode == "V" or mode == "\22" then -- visual modes
    -- Replace selected text safely
    vim.cmd("normal! d")

    -- Split multiline strings and use line mode for proper insertion
    local lines = vim.split(lua_str, "\n", { plain = true })
    vim.api.nvim_put(lines, "l", true, true)
  else
    -- Replace current line - handle multiline output
    local lines = vim.split(lua_str, "\n", { plain = true })
    local current_line = vim.fn.line(".")

    -- Replace current line with first line
    vim.fn.setline(current_line, lines[1])

    -- Insert additional lines if multiline
    if #lines > 1 then
      for i = 2, #lines do
        vim.fn.append(current_line + i - 2, lines[i])
      end
    end
  end
end

-- JSON to Lua conversion using vim.json.decode()
-- Converts JSON text to Lua table representation
-- Works in both normal mode (current line) and visual modes (selection)
local function json_to_lua()
  local mode = vim.fn.mode()

  -- Get the text to convert
  local json_text = get_selected_text()

  -- Input validation: check for empty or whitespace-only content
  if not json_text or json_text:match("^%s*$") then
    vim.notify("No JSON content to convert", vim.log.levels.WARN)
    return
  end

  -- Try to decode JSON
  local success, lua_obj = pcall(vim.json.decode, json_text)

  if not success then
    vim.notify("Invalid JSON: " .. lua_obj, vim.log.levels.ERROR)
    return
  end

  -- Convert Lua object to string representation
  local lua_str = serialize_lua_object(lua_obj)

  -- Replace the buffer content
  replace_buffer_content(lua_str, mode)

  vim.notify("JSON converted to Lua", vim.log.levels.INFO)
end

-- Expose the function globally so it can be called from keymaps
_G.json_to_lua = json_to_lua

-- Ensure you have lua-curl installed: luarocks install lua-curl
-- local curl = require("cURL")
--
-- local function is_url(text)
--   local url_pattern = "^https?://[%w-_%.%?%.:/%+=&]+$"
--   return string.match(text, url_pattern) ~= nil
-- end
--
-- local function get_url_title(url)
--   local easy = curl.easy {
--     url = url,
--     followlocation = true, -- Follow redirects if needed
--     timeout = 5,           -- Set a timeout to avoid hanging
--   }
--
--   local title = ""
--   easy:setopt_writefunction(function(data)
--     -- Look for the title tag within chunks of data
--     local match = data:match("<title>([^<]+)</title>")
--     if match then title = match end
--     return #data -- Return the number of bytes processed
--   end)
--
--   easy:perform()
--   easy:close()
--
--   if title == "" then
--     return "No Title Found"
--   else
--     return title:gsub("\n", " "):gsub("%s+", " ") -- Clean up whitespace
--   end
-- end
--
-- local function paste_md_link()
--   local url = vim.fn.getreg('+')
--
--   if not is_url(url) then
--     print("Clipboard content is not a valid URL")
--     return
--   end
--
--   local title = get_url_title(url)
--   local markdown_link = string.format("[%s](%s)", title, url)
--
--   vim.api.nvim_put({ markdown_link }, 'l', true, true)
-- end
--
-- -- Make a keybinding (mnemonic: "mark down paste")
-- vim.keymap.set('n', '<Leader>mdp', paste_md_link, { noremap = true, silent = true })
