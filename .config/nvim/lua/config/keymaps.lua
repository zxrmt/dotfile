-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.api.nvim_set_keymap("n", "q", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "m", ":w<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-m>", ":w<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", ";", ":", { noremap = true, silent = true })
