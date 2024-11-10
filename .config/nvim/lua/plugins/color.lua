return {
  "folke/tokyonight.nvim",
  opts = {
    transparent = true,
    styles = {
      -- sidebars = "transparent",
      floats = "transparent",
    },
  },
  config = function(_, opts)
    require("tokyonight").setup(opts) -- calling setup is optional
    vim.cmd("colorscheme tokyonight-moon")
  end,
}
