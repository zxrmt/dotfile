vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.laststatus = 3
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.list = false

-- built-in stand-ins for the file/grep pickers (<leader>ff, <leader>/ ...)
vim.opt.path:append("**")
if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep --smart-case"
  vim.opt.grepformat = "%f:%l:%c:%m"
end

-- tokyonight-moon, transparent (colors/tokyonight-moon.lua). No background is
-- painted, so tmux's window-style shows through on unfocused panes.
vim.cmd.colorscheme("tokyonight-moon")
