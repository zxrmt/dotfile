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


vim.o.autoread = true

-- Trigger autoread when switching buffers, gaining focus, or reading from file
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  command = "checktime",
})

-- Notify if file changed
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  callback = function()
    vim.notify("File changed on disk. Buffer reloaded!", vim.log.levels.WARN)
  end,
})


