-- noice.lua
return {
  "folke/noice.nvim",
  opts = {
    cmdline = {
      enabled = false,
    },
    messages = {
      enabled = false,
    },
  },
}
-- lsp.lua
return {
  "neovim/nvim-lspconfig",
  opts = {
    inlay_hints = { enabled = false },
  },
}
