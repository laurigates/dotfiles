local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

-- Load plugins from directory
require("lazy").setup("plugins")
vim.cmd([[colorscheme tokyonight]])

require("core/settings")
require("core/functions")
require("core/autocommands")
require("core/lsp")
require("core/keymaps")
