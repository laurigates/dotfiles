-----------------------------------------------------------
-- Define keymaps of Neovim and installed plugins.
-----------------------------------------------------------

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend('force', options, opts)
  end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Change leader to space
vim.g.mapleader = ' '

-----------------------------------------------------------
-- Neovim shortcuts
-----------------------------------------------------------
-- Visual select most recently changed or pasted content
map('n', 'gp', '`[v`]')

-- Clear search highlighting with <leader> and c
map('n', '<leader>c', ':nohl<CR>')

-- Map Esc to jj
map('i', 'jj', '<Esc>')

-- Don't use arrow keys
map('', '<up>', '<nop>')
map('', '<down>', '<nop>')
map('', '<left>', '<nop>')
map('', '<right>', '<nop>')

-- Fast saving with <leader> and s
-- map('n', '<leader>s', ':w<CR>')
-- map('i', '<leader>s', '<C-c>:w<CR>')

-- Move around splits using Ctrl + {h,j,k,l}
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- Switch between buffers using H and L
map('n', 'L', ':bp<CR>')
map('n', 'H', ':bn<CR>')

-- Close all windows and exit from Neovim with <leader> and q
-- map('n', '<leader>q', ':qa!<CR>')

-----------------------------------------------------------
-- Applications and Plugins shortcuts
-----------------------------------------------------------

-- Terminal mappings
map('n', '<C-t>', ':Term<CR>', { noremap = true })  -- open
map('t', '<Esc>', '<C-\\><C-n>')                    -- exit

-- Vista tag-viewer
-- map('n', '<C-m>', ':Vista!!<CR>') -- open/close

-- Telescope
map('n', '<leader>ff', '<cmd>lua require("telescope.builtin").find_files()<cr>')
map('n', '<leader>fr', '<cmd>lua require("telescope.builtin").git_files()<cr>')
map('n', '<leader>fg', '<cmd>lua require("telescope.builtin").live_grep()<cr>')
map('n', '<leader>fb', '<cmd>lua require("telescope.builtin").buffers()<cr>')
map('n', '<leader>fh', '<cmd>lua require("telescope.builtin").help_tags()<cr>')
map('n', '<leader>fm', '<cmd>lua require("telescope.builtin").keymaps()<cr>')

-- vim-easy-align
-- map('n', 'ga', '<Plug>(EasyAlign)')
-- map('x', 'ga', '<Plug>(EasyAlign)')
map('n', '<leader>h', '<cmd>lua require("replacer").run()<cr>')
