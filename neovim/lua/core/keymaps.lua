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
map("n", "<leader>c", ":nohl<CR>")

-- Map Esc to jj
map("i", "jj", "<Esc>")

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
map("n", "<leader>gc", ":G commit -v<CR>")
map("n", "<leader>gp", ":G push<CR>")
map("n", "<leader>gw", ":Gwrite<CR>")

-- vim-easy-align
-- map('n', 'ga', '<Plug>(EasyAlign)')
-- map('x', 'ga', '<Plug>(EasyAlign)')

-- Surround like delete/change surrounding function calls
-- map('n', 'dsf', 'ds)db', { noremap = false })
-- map('n', 'csf', '[(cb')
