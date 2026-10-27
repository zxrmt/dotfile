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

-- Disable diagnostics
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.diagnostic.config({
      virtual_text = false,
      signs = false,
      underline = false,
      update_in_insert = false,
    })
  end,
})
