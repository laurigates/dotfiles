-----------------------------------------------------------
-- Neovim API aliases
-----------------------------------------------------------
local opt = vim.opt -- Set options (global/buffer/windows-scoped)

-----------------------------------------------------------
-- General
-----------------------------------------------------------
opt.mouse = "a"                               -- Enable mouse support
opt.swapfile = false                          -- Swap file isn't needed
opt.undofile = true                           -- But persistent undo is nice
-- Show autocomplete even when only one item is available, don't automatically select or insert an option. User must do the selection.
opt.completeopt = "menuone,noselect,noinsert" -- Autocomplete options
-- opt.clipboard = "unnamedplus"

-----------------------------------------------------------
-- Neovim UI
-----------------------------------------------------------
opt.number = true    -- Show line number
opt.showmatch = true -- Highlight matching parenthesis

-- Ignore case when searching or replacing when the search is only lower case
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "nosplit" -- Live preview of substitution results

opt.linebreak = true       -- Wrap on word boundary
opt.scrolloff = 12         -- Start scrolling before reaching the edge when moving with j/k
opt.diffopt:append("vertical,iwhite,algorithm:histogram,hiddenoff")
opt.listchars = "eol:↲,tab:» ,extends:›,precedes:‹,nbsp:☠,trail:·"

-----------------------------------------------------------
-- Tabs, indent
-----------------------------------------------------------
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 2   -- Shift 2 spaces when tab
opt.tabstop = 2      -- 1 tab == 2 spaces
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = "v:lua.vim.treesitter.foldtext()"
