return {
  "ibhagwan/fzf-lua",
  event = "VeryLazy",
  opts = {
    winopts = {
      height = 0.85,
      width = 0.80,
      preview = {
        default = "bat",
      },
    },
  },
  config = function(_, opts)
    require("fzf-lua").setup(opts)
  end,
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
  },
}