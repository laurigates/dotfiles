-----------------------------------------------------------
-- Define keymaps of Neovim and installed plugins.
-----------------------------------------------------------

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Change leader to space
vim.g.mapleader = " "

-----------------------------------------------------------
-- Neovim shortcuts
-----------------------------------------------------------
-- Visual select most recently changed or pasted content
map("n", "gp", "`[v`]")

-- Clear search highlighting with <leader> and c
-- map("n", "<leader>c", ":nohl<CR>")

-- Map Esc to jj
-- map("i", "jj", "<Esc>")

-- Don't use arrow keys
map("", "<up>", "<nop>")
map("", "<down>", "<nop>")
map("", "<left>", "<nop>")
map("", "<right>", "<nop>")

-- Move around splits using Ctrl + {h,j,k,l}
-- map("n", "<C-h>", "<C-w>h")
-- map("n", "<C-j>", "<C-w>j")
-- map("n", "<C-k>", "<C-w>k")
-- map("n", "<C-l>", "<C-w>l")

-- Switch between buffers using H and L
map("n", "H", ":BufferPrevious<CR>")
map("n", "L", ":BufferNext<CR>")

-- Terminal mappings
-- map("n", "<C-t>", ":Term<CR>", { noremap = true }) -- open
map("t", "<Esc>", "<C-\\><C-n>") -- exit

-- map("n", "<leader>g", ":G<CR>")
-- map("n", "<leader>gc", ":G commit -v<CR>")
-- map("n", "<leader>gp", ":G push<CR>")
-- map("n", "<leader>gw", ":Gwrite<CR>")

-- vim-easy-align
-- map('n', 'ga', '<Plug>(EasyAlign)')
-- map('x', 'ga', '<Plug>(EasyAlign)')

-- JSON to Lua conversion using vim.json.decode()
function json_to_lua()
  local mode = vim.fn.mode()
  local json_text

  if mode == 'v' or mode == 'V' or mode == '\22' then -- visual modes
    -- Get visually selected text using treesitter method for accurate selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    
    -- Use vim.fn.getregion for accurate visual selection
    if vim.fn.has('nvim-0.10') == 1 and vim.fn.getregion then
      local region = vim.fn.getregion(start_pos, end_pos, { type = mode })
      json_text = table.concat(region, "\n")
    else
      -- Fallback for older versions
      local lines = vim.fn.getline(start_pos[2], end_pos[2])
      
      if #lines == 1 then
        -- Single line selection - fix the column handling
        local start_col = start_pos[3]
        local end_col = mode == 'v' and end_pos[3] or #lines[1]
        json_text = string.sub(lines[1], start_col, end_col)
      else
        -- Multi-line selection
        if #lines > 1 then
          -- Fix first line (from start position to end)
          lines[1] = string.sub(lines[1], start_pos[3])
          -- Fix last line (from start to end position)
          if mode == 'v' then
            lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
          end
        end
        json_text = table.concat(lines, "\n")
      end
    end
  else
    -- Normal mode: get current line
    json_text = vim.fn.getline('.')
  end

  -- Try to decode JSON
  local success, lua_obj = pcall(vim.json.decode, json_text)
  
  if not success then
    vim.notify("Invalid JSON: " .. lua_obj, vim.log.levels.ERROR)
    return
  end

  -- Convert Lua object to string representation
  local function serialize_lua(obj, indent)
    indent = indent or 0
    local spacing = string.rep("  ", indent)
    
    if type(obj) == "table" then
      local result = "{\n"
      local is_array = true
      local max_index = 0
      
      -- Check if it's an array
      for k, _ in pairs(obj) do
        if type(k) ~= "number" then
          is_array = false
          break
        else
          max_index = math.max(max_index, k)
        end
      end
      
      if is_array then
        for i = 1, max_index do
          if obj[i] ~= nil then
            result = result .. spacing .. "  " .. serialize_lua(obj[i], indent + 1) .. ",\n"
          end
        end
      else
        for k, v in pairs(obj) do
          local key = type(k) == "string" and (k:match("^[%a_][%w_]*$") and k or '["' .. k .. '"]') or "[" .. k .. "]"
          result = result .. spacing .. "  " .. key .. " = " .. serialize_lua(v, indent + 1) .. ",\n"
        end
      end
      
      result = result .. spacing .. "}"
      return result
    elseif type(obj) == "string" then
      return string.format('%q', obj)
    else
      return tostring(obj)
    end
  end

  local lua_str = serialize_lua(lua_obj)
  
  -- Replace the text
  if mode == 'v' or mode == 'V' or mode == '\22' then -- visual modes
    -- Replace selected text safely
    vim.cmd('normal! d')
    vim.api.nvim_put({lua_str}, 'c', true, true)
  else
    -- Replace current line
    vim.fn.setline('.', lua_str)
  end
  
  vim.notify("JSON converted to Lua", vim.log.levels.INFO)
end

-- Map <leader>jl for "JSON to Lua"
map('n', '<leader>jl', '<cmd>lua json_to_lua()<CR>', { desc = "Convert JSON to Lua using vim.json.decode()" })
map('v', '<leader>jl', '<cmd>lua json_to_lua()<CR>', { desc = "Convert JSON to Lua using vim.json.decode()" })

-- Surround like delete/change surrounding function calls
-- map('n', 'dsf', 'ds)db', { noremap = false })
-- map('n', 'csf', '[(cb')
--
--     :tnoremap <Esc> <C-\><C-n>
--
-- To simulate |i_CTRL-R| in terminal-mode: >vim
--     :tnoremap <expr> <C-R> '<C-\><C-N>"'.nr2char(getchar()).'pi'
--
-- To use `ALT+{h,j,k,l}` to navigate windows from any mode: >vim
--     :tnoremap <A-h> <C-\><C-N><C-w>h
--     :tnoremap <A-j> <C-\><C-N><C-w>j
--     :tnoremap <A-k> <C-\><C-N><C-w>k
--     :tnoremap <A-l> <C-\><C-N><C-w>l
--     :inoremap <A-h> <C-\><C-N><C-w>h
--     :inoremap <A-j> <C-\><C-N><C-w>j
--     :inoremap <A-k> <C-\><C-N><C-w>k
--     :inoremap <A-l> <C-\><C-N><C-w>l
--     :nnoremap <A-h> <C-w>h
--     :nnoremap <A-j> <C-w>j
--     :nnoremap <A-k> <C-w>k
--     :nnoremap <A-l> <C-w>l
