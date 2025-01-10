-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Define a function to simplify mapping
local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, unpack(opts or {}) }
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- Insert mode mappings
map("i", ",", ",<C-g>u", {})
map("i", ".", ".<C-g>u", {})
map("i", "(", "(<C-g>u", {})
map("i", "[", "[<C-g>u", {})
map("i", "=", "=<C-g>u", {})
map("i", '"', '"<C-g>u', {})
map("i", "<space>", "<space><C-g>u", {})
map("i", "<CR>", "<CR><C-g>u", {})
