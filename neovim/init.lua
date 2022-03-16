--[[

Neovim init file
Version: 0.50.0 - 2022/03/07
Maintainer: brainf+ck
Website: https://github.com/brainfucksec/neovim-lua

--]]

-- Bootstrap packer
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

-- Import Lua modules
require('core/settings')
require('core/keymaps')
require('packer_init')
require('plugins/nvim-tree')
require('plugins/indent-blankline')
require('plugins/feline')
require('plugins/vista')
require('plugins/nvim-cmp')
require('plugins/nvim-lspconfig')
require('plugins/nvim-treesitter')
require('plugins/nvim-telescope')
require('plugins/alpha-nvim')
require('plugins/nvim-gps')
