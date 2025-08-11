return {
  {
    "williamboman/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
      },
      ensure_installed = {
        "pyright",
        "ruff",
      },
    },
  },
}
