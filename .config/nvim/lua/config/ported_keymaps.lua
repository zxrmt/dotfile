-- LazyVim's default keymaps, ported to plain Neovim (no plugins).
-- Loaded before config.keymaps, so anything defined there wins.
-- What could not be ported is listed in ../../KEYMAPS.md.

local function map(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  vim.keymap.set(mode, lhs, rhs, opts)
end

local function root()
  return vim.fs.root(0, { ".git", "lua" }) or vim.uv.cwd()
end

---------------------------------------------------------------------------
-- helpers (stand-ins for the Snacks utilities LazyVim uses)
---------------------------------------------------------------------------

local function bufdelete(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if vim.bo[buf].modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname(buf)), "&Yes\n&No\n&Cancel")
    if choice == 0 or choice == 3 then
      return
    end
    if choice == 1 then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("write")
      end)
    end
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
        return
      end
      local alt = vim.fn.bufnr("#")
      if alt ~= buf and alt ~= -1 and vim.fn.buflisted(alt) == 1 then
        vim.api.nvim_win_set_buf(win, alt)
        return
      end
      pcall(vim.cmd, "bprevious")
      if vim.api.nvim_win_get_buf(win) == buf then
        vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
      end
    end)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.cmd, "bdelete! " .. buf)
  end
end

local function bufdelete_where(pred)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and pred(buf) then
      bufdelete(buf)
    end
  end
end

local terms = {}

--- Toggle a floating terminal. `cmd` nil = $SHELL. Terminals are cached per cmd+cwd.
local function float_term(cmd, opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.uv.cwd()
  local key = vim.inspect({ cmd, cwd })
  local t = terms[key]
  if t and vim.api.nvim_buf_is_valid(t.buf) then
    if t.win and vim.api.nvim_win_is_valid(t.win) then
      vim.api.nvim_win_hide(t.win)
      t.win = nil
      return
    end
  else
    t = { buf = vim.api.nvim_create_buf(false, true), new = true }
    terms[key] = t
  end

  local w, h = math.floor(vim.o.columns * 0.8), math.floor(vim.o.lines * 0.8)
  t.win = vim.api.nvim_open_win(t.buf, true, {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((vim.o.columns - w) / 2),
    row = math.floor((vim.o.lines - h) / 2 - 1),
    style = "minimal",
    border = "rounded",
  })
  if t.new then
    t.new = nil
    vim.api.nvim_buf_call(t.buf, function()
      vim.fn.jobstart(cmd or vim.o.shell, {
        term = true,
        cwd = cwd,
        env = opts.env,
        on_exit = function()
          vim.schedule(function()
            if t.win and vim.api.nvim_win_is_valid(t.win) then
              vim.api.nvim_win_close(t.win, true)
            end
            if vim.api.nvim_buf_is_valid(t.buf) then
              vim.api.nvim_buf_delete(t.buf, { force = true })
            end
            terms[key] = nil
          end)
        end,
      })
    end)
  end
  vim.cmd.startinsert()
end

--- Run a git command through the pager in a floating terminal.
local function git_float(args, cwd)
  float_term(vim.list_extend({ "git", "--paginate" }, args), { cwd = cwd or root(), env = { LESS = "-R" } })
end

local function git_browse(copy)
  local cwd = root()
  local function git(...)
    local r = vim.system({ "git", ... }, { text = true, cwd = cwd }):wait()
    return r.code == 0 and vim.trim(r.stdout) or nil
  end
  local remote, top, branch = git("remote", "get-url", "origin"), git("rev-parse", "--show-toplevel"), git("rev-parse", "--abbrev-ref", "HEAD")
  if not (remote and top and branch) then
    return vim.notify("Not a git repository with an origin remote", vim.log.levels.WARN)
  end
  remote = remote:gsub("%.git$", "")
  remote = remote:gsub("^git@([^:]+):", "https://%1/")
  remote = remote:gsub("^ssh://git@([^/]+)/", "https://%1/")
  local l1, l2 = vim.fn.line("."), vim.fn.line(".")
  if vim.fn.mode():match("[vV\22]") then
    l1, l2 = vim.fn.line("v"), vim.fn.line(".")
    l1, l2 = math.min(l1, l2), math.max(l1, l2)
  end
  local rel = vim.api.nvim_buf_get_name(0):sub(#top + 2)
  local url = ("%s/blob/%s/%s#L%d%s"):format(remote, branch, rel, l1, l2 ~= l1 and ("-L" .. l2) or "")
  if copy then
    vim.fn.setreg("+", url)
    vim.notify(url)
  else
    vim.ui.open(url)
  end
end

local function toggle(lhs, name, get, set)
  map("n", lhs, function()
    local v = not get()
    set(v)
    vim.notify((v and "Enabled " or "Disabled ") .. name)
  end, { desc = "Toggle " .. name })
end

local function toggle_opt(lhs, name, opt, on, off)
  on, off = on == nil and true or on, off == nil and false or off
  toggle(lhs, name, function()
    return vim.o[opt] == on
  end, function(v)
    vim.o[opt] = v and on or off
  end)
end

local function zoom()
  if vim.t.zoom_restore then
    vim.cmd(vim.t.zoom_restore)
    vim.t.zoom_restore = nil
  else
    vim.t.zoom_restore = vim.fn.winrestcmd()
    vim.cmd("wincmd _ | wincmd |")
  end
end

local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end

local function toggle_list(winid, open, close)
  return function()
    local ok, err = pcall(winid ~= 0 and close or open)
    if not ok and err then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end

---------------------------------------------------------------------------
-- editing
---------------------------------------------------------------------------

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true })

-- move lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  if vim.snippet.active() then
    vim.snippet.stop()
  end
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- clear search, diff update and redraw
map("n", "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", { desc = "Redraw / Clear hlsearch / Diff Update" })

-- saner n/N
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- keywordprg
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

-- commenting (gc / gcc themselves are built in)
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- scratch buffer
local scratch
map("n", "<leader>.", function()
  if not (scratch and vim.api.nvim_buf_is_valid(scratch)) then
    scratch = vim.api.nvim_create_buf(false, true)
    vim.bo[scratch].bufhidden = "hide"
    vim.bo[scratch].swapfile = false
  end
  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(0, scratch)
end, { desc = "Toggle Scratch Buffer" })

---------------------------------------------------------------------------
-- windows, buffers, tabs
---------------------------------------------------------------------------

-- move between windows
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- resize windows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- window commands: <leader>w<x> == <C-w><x> (which-key's proxy)
map("n", "<leader>w", "<C-w>", { desc = "Windows", remap = true })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
map("n", "<leader>wm", zoom, { desc = "Toggle Zoom" })
map("n", "<leader>uZ", zoom, { desc = "Toggle Zoom" })

-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function()
  bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  local cur = vim.api.nvim_get_current_buf()
  bufdelete_where(function(b)
    return b ~= cur
  end)
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bi", function()
  bufdelete_where(function(b)
    return #vim.fn.win_findbuf(b) == 0
  end)
end, { desc = "Delete Invisible Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

local function buffers_side(dir)
  return function()
    local cur = vim.api.nvim_get_current_buf()
    local bufs = vim.tbl_filter(function(b)
      return vim.bo[b].buflisted
    end, vim.api.nvim_list_bufs())
    local seen = false
    for _, b in ipairs(bufs) do
      if b == cur then
        seen = true
      elseif (dir == "right") == seen then
        bufdelete(b)
      end
    end
  end
end
map("n", "<leader>br", buffers_side("right"), { desc = "Delete Buffers to the Right" })
map("n", "<leader>bl", buffers_side("left"), { desc = "Delete Buffers to the Left" })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

---------------------------------------------------------------------------
-- quickfix / location list / diagnostics
---------------------------------------------------------------------------

map("n", "<leader>xl", function()
  toggle_list(vim.fn.getloclist(0, { winid = 0 }).winid, vim.cmd.lopen, vim.cmd.lclose)()
end, { desc = "Location List" })
map("n", "<leader>xq", function()
  toggle_list(vim.fn.getqflist({ winid = 0 }).winid, vim.cmd.copen, vim.cmd.cclose)()
end, { desc = "Quickfix List" })
map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- stand-ins for Trouble
map("n", "<leader>xx", function()
  vim.diagnostic.setqflist()
end, { desc = "Diagnostics (quickfix)" })
map("n", "<leader>xX", function()
  vim.diagnostic.setloclist()
end, { desc = "Buffer Diagnostics (loclist)" })

---------------------------------------------------------------------------
-- formatting
---------------------------------------------------------------------------

map({ "n", "x" }, "<leader>cf", function()
  vim.lsp.buf.format()
end, { desc = "Format" })

---------------------------------------------------------------------------
-- toggles
---------------------------------------------------------------------------

toggle_opt("<leader>us", "Spelling", "spell")
toggle_opt("<leader>uw", "Wrap", "wrap")
toggle_opt("<leader>uL", "Relative Number", "relativenumber")
toggle_opt("<leader>uc", "Conceal Level", "conceallevel", vim.o.conceallevel > 0 and vim.o.conceallevel or 2, 0)
toggle_opt("<leader>uA", "Tabline", "showtabline", vim.o.showtabline > 0 and vim.o.showtabline or 2, 0)
toggle_opt("<leader>ub", "Dark Background", "background", "dark", "light")

local relnum = vim.wo.relativenumber
toggle("<leader>ul", "Line Numbers", function()
  return vim.wo.number or vim.wo.relativenumber
end, function(v)
  if not v then
    relnum = vim.wo.relativenumber
  end
  vim.wo.number = v
  vim.wo.relativenumber = v and relnum
end)
toggle("<leader>ud", "Diagnostics", function()
  return vim.diagnostic.is_enabled()
end, function(v)
  vim.diagnostic.enable(v)
end)
toggle("<leader>uT", "Treesitter Highlight", function()
  return vim.b.ts_highlight ~= nil
end, function(v)
  if v then
    vim.treesitter.start()
  else
    vim.treesitter.stop()
  end
end)
toggle("<leader>uh", "Inlay Hints", function()
  return vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
end, function(v)
  vim.lsp.inlay_hint.enable(v, { bufnr = 0 })
end)

-- inspect
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", function()
  vim.treesitter.inspect_tree()
  vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

---------------------------------------------------------------------------
-- terminal, git
---------------------------------------------------------------------------

map("n", "<leader>fT", function()
  float_term()
end, { desc = "Terminal (cwd)" })
map("n", "<leader>ft", function()
  float_term(nil, { cwd = root() })
end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-/>", function()
  float_term(nil, { cwd = root() })
end, { desc = "Terminal (Root Dir)" })
map({ "n", "t" }, "<c-_>", function()
  float_term(nil, { cwd = root() })
end, { desc = "which_key_ignore" })

if vim.fn.executable("lazygit") == 1 then
  map("n", "<leader>gg", function()
    float_term({ "lazygit" }, { cwd = root() })
  end, { desc = "Lazygit (Root Dir)" })
  map("n", "<leader>gG", function()
    float_term({ "lazygit" })
  end, { desc = "Lazygit (cwd)" })
end

local graph = { "log", "--oneline", "--graph", "--decorate" }
map("n", "<leader>gl", function()
  git_float(graph)
end, { desc = "Git Log" })
map("n", "<leader>gL", function()
  git_float(graph, vim.uv.cwd())
end, { desc = "Git Log (cwd)" })
map("n", "<leader>gb", function()
  local line, file = vim.fn.line("."), vim.fn.expand("%:p")
  git_float({ "log", ("-L%d,%d:%s"):format(line, line, file) })
end, { desc = "Git Blame Line" })
map("n", "<leader>gf", function()
  git_float({ "log", "-p", "--follow", "--", vim.fn.expand("%:p") })
end, { desc = "Git Current File History" })
map("n", "<leader>gs", function()
  git_float({ "status" })
end, { desc = "Git Status" })
map("n", "<leader>gd", function()
  git_float({ "diff" })
end, { desc = "Git Diff" })
map("n", "<leader>gS", function()
  git_float({ "stash", "list" })
end, { desc = "Git Stash" })
map({ "n", "x" }, "<leader>gB", function()
  git_browse(false)
end, { desc = "Git Browse (open)" })
map({ "n", "x" }, "<leader>gY", function()
  git_browse(true)
end, { desc = "Git Browse (copy)" })

---------------------------------------------------------------------------
-- file explorer / finding (netrw, :find, :grep instead of pickers)
---------------------------------------------------------------------------

local function explore(dir)
  return function()
    vim.cmd("Explore " .. vim.fn.fnameescape(dir()))
  end
end
map("n", "<leader>e", explore(root), { desc = "Explorer (root dir)" })
map("n", "<leader>fe", explore(root), { desc = "Explorer (root dir)" })
map("n", "<leader>E", explore(vim.uv.cwd), { desc = "Explorer (cwd)" })
map("n", "<leader>fE", explore(vim.uv.cwd), { desc = "Explorer (cwd)" })

map("n", "<leader><space>", ":find ", { desc = "Find Files", silent = false })
map("n", "<leader>ff", ":find ", { desc = "Find Files", silent = false })
map("n", "<leader>fc", ":edit " .. vim.fn.stdpath("config") .. "/", { desc = "Find Config File", silent = false })
map("n", "<leader>fr", "<cmd>browse oldfiles<cr>", { desc = "Recent" })
map("n", "<leader>,", ":ls<cr>:buffer ", { desc = "Buffers", silent = false })
map("n", "<leader>fb", ":ls<cr>:buffer ", { desc = "Buffers", silent = false })
map("n", "<leader>/", ":grep ", { desc = "Grep", silent = false })
map("n", "<leader>sg", ":grep ", { desc = "Grep", silent = false })
map("n", "<leader>fg", ":grep ", { desc = "Grep", silent = false })

local function grep_word()
  local word
  if vim.fn.mode():match("[vV\22]") then
    word = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() }), "\n")
    vim.cmd.normal({ "\27", bang = true })
  else
    word = vim.fn.expand("<cword>")
  end
  vim.cmd("silent grep! " .. vim.fn.shellescape(word))
  vim.cmd("copen")
end
map({ "n", "x" }, "<leader>sw", grep_word, { desc = "Visual selection or word" })

map("n", "<leader>:", "q:", { desc = "Command History" })
map("n", "<leader>sc", "q:", { desc = "Command History" })
map("n", "<leader>sC", "<cmd>command<cr>", { desc = "Commands" })
map("n", "<leader>sa", "<cmd>autocmd<cr>", { desc = "Autocmds" })
map("n", "<leader>sd", function()
  vim.diagnostic.setqflist()
end, { desc = "Diagnostics" })
map("n", "<leader>sD", function()
  vim.diagnostic.setloclist()
end, { desc = "Buffer Diagnostics" })
map("n", "<leader>sh", ":help ", { desc = "Help Pages", silent = false })
map("n", "<leader>fh", ":help ", { desc = "Help Pages", silent = false })
map("n", "<leader>sH", "<cmd>highlight<cr>", { desc = "Highlights" })
map("n", "<leader>sj", "<cmd>jumps<cr>", { desc = "Jumps" })
map("n", "<leader>sk", "<cmd>map<cr>", { desc = "Keymaps" })
map("n", "<leader>sl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>sq", "<cmd>copen<cr>", { desc = "Quickfix List" })
map("n", "<leader>sm", "<cmd>marks<cr>", { desc = "Marks" })
map("n", "<leader>sM", ":Man ", { desc = "Man Pages", silent = false })
map("n", "<leader>uC", ":colorscheme ", { desc = "Colorschemes", silent = false })
map("n", "<leader>n", "<cmd>messages<cr>", { desc = "Message History" })
map("n", "<leader>su", function()
  vim.cmd.packadd("nvim.undotree")
  require("undotree").open()
end, { desc = "Undotree" })

---------------------------------------------------------------------------
-- LSP (only active once a language server attaches)
---------------------------------------------------------------------------

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ported_lsp_keymaps", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local function lmap(mode, lhs, rhs, desc, method, extra)
      if method and not client:supports_method(method, ev.buf) then
        return
      end
      map(mode, lhs, rhs, vim.tbl_extend("force", { buffer = ev.buf, desc = desc }, extra or {}))
    end
    local buf = vim.lsp.buf
    lmap("n", "<leader>cl", "<cmd>checkhealth vim.lsp<cr>", "Lsp Info")
    lmap("n", "gd", buf.definition, "Goto Definition", "textDocument/definition")
    lmap("n", "gr", buf.references, "References", nil, { nowait = true })
    lmap("n", "gI", buf.implementation, "Goto Implementation")
    lmap("n", "gy", buf.type_definition, "Goto T[y]pe Definition")
    lmap("n", "gD", buf.declaration, "Goto Declaration")
    lmap("n", "gai", buf.incoming_calls, "C[a]lls Incoming")
    lmap("n", "gao", buf.outgoing_calls, "C[a]lls Outgoing")
    lmap("n", "K", buf.hover, "Hover")
    lmap("n", "gK", buf.signature_help, "Signature Help", "textDocument/signatureHelp")
    lmap("i", "<c-k>", buf.signature_help, "Signature Help", "textDocument/signatureHelp")
    lmap({ "n", "x" }, "<leader>ca", buf.code_action, "Code Action", "textDocument/codeAction")
    lmap({ "n", "x" }, "<leader>cc", vim.lsp.codelens.run, "Run Codelens", "textDocument/codeLens")
    lmap("n", "<leader>cC", vim.lsp.codelens.refresh, "Refresh & Display Codelens", "textDocument/codeLens")
    lmap("n", "<leader>cr", buf.rename, "Rename", "textDocument/rename")
    lmap("n", "<leader>cA", function()
      buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
    end, "Source Action", "textDocument/codeAction")
    lmap("n", "<leader>co", function()
      buf.code_action({ context = { only = { "source.organizeImports" }, diagnostics = {} }, apply = true })
    end, "Organize Imports", "textDocument/codeAction")
    -- stand-ins for Trouble's symbols / references views, and the outline plugin
    lmap("n", "<leader>cs", buf.document_symbol, "Symbols")
    lmap("n", "<leader>cS", buf.references, "References")
    lmap("n", "<leader>o", buf.document_symbol, "Outline")
  end,
})

---------------------------------------------------------------------------
-- filetype-local
---------------------------------------------------------------------------

-- close "utility" buffers with q
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ported_close_with_q", { clear = true }),
  pattern = { "checkhealth", "help", "lspinfo", "qf", "startuptime", "notify" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
    end)
  end,
})

-- run the buffer (or selection) as Lua
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ported_run_lua", { clear = true }),
  pattern = "lua",
  callback = function(ev)
    map({ "n", "x" }, "<localleader>r", function()
      local lines
      if vim.fn.mode():match("[vV\22]") then
        lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
        vim.cmd.normal({ "\27", bang = true })
      else
        lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      end
      local chunk, err = load(table.concat(lines, "\n"), "=run_lua")
      if not chunk then
        return vim.notify(err, vim.log.levels.ERROR)
      end
      local ok, res = pcall(chunk)
      if not ok then
        vim.notify(res, vim.log.levels.ERROR)
      end
    end, { buffer = ev.buf, desc = "Run Lua" })
  end,
})
