--[[return {
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
]]
--

return {
  "roobert/palette.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("palette").setup({
      palettes = {
        main = "custom_main_palette",
        accent = "custom_accent_palette",
        state = "custom_state_palette",
      },

      custom_palettes = {
        main = {
          custom_main_palette = {
            color0 = "#f0d90e", -- Unknow color using Greent
            color1 = "#1A1E39", -- Current line color
            color2 = "#383f5e", -- Status bar color
            color3 = "#679ad1", -- keyword color
            color4 = "#7b7f94", -- bracket color
            color5 = "#a7a9b7", -- lazy vim command bottom
            color6 = "#608271", -- comment color
            color7 = "#dcdcaf", -- function name
            color8 = "#ffffff", -- string color
          },
        },
        accent = {
          custom_accent_palette = {
            accent0 = "#a4b597", -- red
            accent1 = "#D9AE7E", -- find color, visueal selection
            accent2 = "#02f00e", -- Unknow color using green
            accent3 = "#02f00e", -- Unknow color using green
            accent4 = "#5a84b2", -- boolean color
            accent5 = "#f00202", -- Unknow color using red
            accent6 = "#f0d90e", -- Unknow color using purple
          },
        },
        state = {
          custom_state_palette = {
            error = "#D97C8F",
            warning = "#D9AE7E",
            hint = "#D9D87E",
            ok = "#A5D9A7",
            info = "#8BB9C8",
          },
        },
      },
      transparent_background = true,
    })

    vim.cmd([[colorscheme palette]])
  end,
}
