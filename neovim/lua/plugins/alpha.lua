return {
  {
    "goolord/alpha-nvim",
    dependencies = {
      'nvim-tree/nvim-web-devicons',
      'nvim-lua/plenary.nvim'
    },
    config = function()
      require("alpha").setup(require("alpha.themes.theta").config)
    end,
  },
}
