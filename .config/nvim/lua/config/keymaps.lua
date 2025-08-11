-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.api.nvim_set_keymap("n", "q", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "m", ":w<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-m>", ":w<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", ";", ":", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "f", ":Telescope grep_string", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "q", ":q!<CR>", { noremap = true, silent = true })
-- Hex editing stuff
vim.api.nvim_set_keymap("n", "<leader>he", ":%!xxd<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>hu", ":%!xxd -r<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-u>", "5k", { noremap = true, silent = true, desc = "Move up 5 lines" })
vim.keymap.set("n", "<C-d>", "5j", { noremap = true, silent = true, desc = "Move up 5 lines" })

-- Jump list navigation remapping
vim.keymap.set("n", "<C-e>", "<C-o>", { noremap = true, silent = true, desc = "Go back in jump list" })
vim.keymap.set("n", "<C-i>", "<C-i>", { noremap = true, silent = true, desc = "Go forward in jump list" })
