vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.laststatus = 3
vim.opt.cmdheight = 0
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

-- Clipboard (restored from LazyVim: `clipboard = unnamedplus`).
-- Yanks go to the system clipboard through OSC 52, which passes through tmux
-- (`set-clipboard on`) to the outer terminal, so they paste outside tmux too.
-- Paste reads from the local register: querying the terminal via OSC 52 hangs
-- inside tmux.
vim.opt.clipboard = "unnamedplus"
do
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
