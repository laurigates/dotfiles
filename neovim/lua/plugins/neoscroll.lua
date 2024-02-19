-- Smooth scrolling neovim plugin written in lua
return {
  "karb94/neoscroll.nvim",
  config = function ()
    require('neoscroll').setup {}
  end
}
