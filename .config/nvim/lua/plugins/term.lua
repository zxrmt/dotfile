return {
  "akinsho/toggleterm.nvim",
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<c-\>]],
      shade_terminals = true,
      title_pos = "center",
      border = "double",
      -- add --login so ~/.zprofile is loaded
      -- https://vi.stackexchange.com/questions/16019/neovim-terminal-not-reading-bash-profile/16021#16021
      shell = "zsh",
      winbar = {
        enabled = true,
        name_formatter = function(term) --  term: Terminal
          return string.rep("-", vim.o.columns * 4)
        end
      },
    })
  end,
  keys = {
    { [[<C-\>]] },
    { "<leader>0", "<Cmd>2ToggleTerm<Cr>", desc = "Terminal #2" },
    {
      "<leader>td",
      "<cmd>ToggleTerm size=10 dir=~/Desktop direction=horizontal border=curved<cr>",
      desc = "Open a horizontal terminal at the Desktop directory",
    },
  },
}
