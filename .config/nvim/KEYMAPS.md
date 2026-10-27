# Keymaps ported from LazyVim

LazyVim's default keymaps now live in `lua/config/ported_keymaps.lua` as plain
Neovim (no plugins). It is loaded **before** `lua/config/keymaps.lua`, so your
own mappings still override it. `<leader>` is `<Space>` (set in `options.lua`).

Source of truth for the port: LazyVim `config/keymaps.lua`, the LSP keymaps in
`plugins/lsp/init.lua`, and the keys declared by the plugins/extras this setup
used (python, rust, neo-tree, bufferline, trouble, gitsigns, snacks picker, ...).

## Ported 1:1

Same keys, same behaviour, native implementation.

| Area | Keys |
| --- | --- |
| Movement | `j`/`k`/`<Down>`/`<Up>` (wrapped lines), `n`/`N` (direction-aware, open folds) |
| Windows | `<C-h/j/k/l>` focus, `<C-Up/Down>` height, `<leader>-` / `<leader>\|` split, `<leader>wd` close, `<leader>w<x>` = `<C-w><x>` |
| Move lines | `<A-j>` / `<A-k>` in normal, insert and visual |
| Buffers | `<S-h>`/`<S-l>`, `[b`/`]b`, `<leader>bb`, `` <leader>` ``, `<leader>bd`, `<leader>bo`, `<leader>bi`, `<leader>bD`, `<leader>br`, `<leader>bl` |
| Tabs | `<leader><tab>` + `l o f <tab> ] d [` |
| Editing | `<esc>` (clears search, stops snippet), `<C-s>` save, `<`/`>` keep selection, `,` `.` `;` undo break-points, `gco`/`gcO`, `<leader>K`, `<leader>fn`, `<leader>ur` |
| Lists | `<leader>xl`, `<leader>xq`, `[q`/`]q` |
| Diagnostics | `<leader>cd`, `]d`/`[d`, `]e`/`[e`, `]w`/`[w` |
| Format | `<leader>cf` (LSP format) |
| Toggles | `<leader>us` spell, `uw` wrap, `uL` relativenumber, `ul` line numbers, `ud` diagnostics, `uc` conceal, `uA` tabline, `ub` background, `uT` treesitter, `uh` inlay hints, `uZ`/`<leader>wm` zoom |
| Inspect | `<leader>ui`, `<leader>uI` |
| Terminal | `<leader>ft`, `<leader>fT`, `<C-/>` (also `<C-_>`) as a floating terminal; `<C-/>` again hides it |
| Git | `<leader>gg`/`gG` lazygit (if installed), `gl`/`gL` log, `gb` line history, `gf` file history, `gB`/`gY` open/copy permalink |
| Quit | `<leader>qq` |
| LSP (on attach) | `gd`, `gr`, `gI`, `gy`, `gD`, `gai`, `gao`, `K`, `gK`, `<C-k>` (insert), `<leader>ca`, `cc`, `cC`, `cr`, `cA`, `co`, `cl` |
| Filetype | `q` closes help/quickfix/checkhealth/...; `<localleader>r` runs the Lua buffer or selection |

## Ported, but approximated

The LazyVim version needs a plugin, so these use a built-in equivalent.

| Keys | LazyVim | Here |
| --- | --- | --- |
| `<leader>ff`, `<leader><space>`, `<leader>fc` | file picker | `:find ` (`path+=**`), config dir prompt |
| `<leader>/`, `<leader>sg`, `<leader>fg`, `<leader>sw` | live grep | `:grep ` prompt (ripgrep when installed), results in quickfix; `sw` greps word/selection |
| `<leader>,`, `<leader>fb` | buffer picker | `:ls` then `:buffer ` prompt |
| `<leader>fr` | recent files | `:browse oldfiles` |
| `<leader>:`, `<leader>sc` | command history picker | `q:` |
| `<leader>e`, `<leader>E`, `<leader>fe`, `<leader>fE` | neo-tree | netrw `:Explore` (root dir / cwd) |
| `<leader>sh`, `fh` `sM` `uC` | help / man / colorscheme pickers | `:help `, `:Man `, `:colorscheme ` prompts |
| `<leader>sC sa sH sj sk sl sm sq n` | pickers for commands, autocmds, highlights, jumps, keymaps, loclist, marks, quickfix, notifications | the matching `:command`, `:autocmd`, `:highlight`, `:jumps`, `:map`, `:lopen`, `:marks`, `:copen`, `:messages` |
| `<leader>sd`, `<leader>sD`, `<leader>xx`, `<leader>xX` | diagnostics pickers / Trouble | `vim.diagnostic.setqflist()` / `setloclist()` |
| `<leader>cs`, `<leader>cS`, `<leader>o` | Trouble symbols / outline.nvim | `vim.lsp.buf.document_symbol()` / `references()` (location list / quickfix) |
| `<leader>su` | undotree picker | built-in `nvim.undotree` |
| `<leader>gs`, `gd`, `gS` | git status / diff / stash pickers | `git status/diff/stash list` in the floating terminal |
| `<leader>.` | Snacks scratch (per-project, persisted) | one throwaway `nofile` buffer in a split |
| `<leader>gB`, `<leader>gY` | `Snacks.gitbrowse` | GitHub-style URLs only (`/blob/<branch>/<path>#L1-L2`) |
| Root dir | LSP root, then `.git`/`lua` | `.git`/`lua`, then cwd (no LSP root) |
| `<leader>bd` | Snacks.bufdelete | own implementation: prompts if modified, keeps the window |

## Differences from LazyVim defaults

- `<C-Left>` / `<C-Right>` resize windows in LazyVim. `keymaps.lua` already maps
  them to word motions, so the resize keys are **overridden** (`<C-Up>` /
  `<C-Down>` still resize height).
- `<C-s>` can be swallowed by terminal flow control. Add `stty -ixon` to your
  shell rc if it does nothing.
- Diagnostics are switched off in `autocmds.lua`, so `<leader>ud` toggles them
  but nothing becomes visible until you re-enable `virtual_text`/`signs`.
  `]d`, `<leader>cd` and the list keys still work.
- LSP keys only exist once a server attaches. No server is configured any more
  (mason/lspconfig are gone), so they are inert until you add one with
  `vim.lsp.config()` / `vim.lsp.enable()`.
- Keys from your old plugin specs: `<leader>ff` `fg` `fb` `fh` (fzf-lua) and
  `<leader>o` (outline.nvim) are ported to the same approximations above. neo-tree's
  `/` -> noop in the tree window has no equivalent.

## Not ported

Everything below needs a plugin or UI that does not exist in plain Neovim.
Nothing here is bound; the keys fall through to Neovim's own behaviour.

**which-key**: the leader popup menu, group labels and `<leader>?` (buffer
keymaps). Use `:map <leader>` or `<leader>sk`.

**flash.nvim**: `s`, `S`, `r` (remote), `R`, `<C-s>` in command-line search.
`s` / `S` keep their built-in meaning.

**Treesitter text objects / selection**: `<C-Space>` / `<BS>` incremental
selection, `]f [f ]c [c ]a [a` function/class/parameter motions, mini.ai's
extended `a`/`i` objects. Related: mini.pairs auto-pairing, ts-comments,
ts-autotag (no keys, but behaviour is gone).

**blink.cmp** (completion menu): `<C-Space>`, `<C-y>`, `<C-e>`, `<C-n>`/`<C-p>`,
`<C-b>`/`<C-f>` doc scroll, `<CR>` accept presets. Neovim 0.11+ keeps its native
snippet `<Tab>`/`<S-Tab>`; `<C-x><C-o>` is plain omni-completion.

**noice.nvim**: `<S-Enter>` command-line redirect, `<leader>sn{l,h,a,d,t}`,
`<C-f>`/`<C-b>` LSP-doc scrolling (the built-in `<C-f>`/`<C-b>` remain).

**Snacks**:
- reference jumping `]]` `[[` `<A-n>` `<A-p>`
- `<leader>uz` zen, `uD` dim, `ua` animate, `ug` indent guides, `uS` smooth scroll
- `<leader>un` dismiss notifications
- `<leader>S` scratch picker, `<leader>cR` rename file (LSP-aware)
- `<leader>dpp` `dph` `dps` profiler
- picker-only views: `<leader>sb` buffer lines, `sB` grep open buffers,
  `sR` resume, `si` icons, `sp` plugin specs, `fp` projects, `fg` git files
  (your `fg` is live grep), `gi` GitHub issues, `gp` GitHub PRs
- `<leader>uf` / `<leader>uF` toggle autoformat (there is no autoformat now)

**gitsigns**: hunk motions `]h [h ]H [H`, `<leader>gh{s,r,S,u,R,p,b,B,d,D}`,
the `ih` text object, `<leader>uG` toggle signs.

**Trouble / todo-comments**: the Trouble windows themselves (`xx`/`xX`/`cs`/`cS`/
`xL`/`xQ` are approximated above), `<leader>xt` `xT`, `]t` `[t`, `<leader>st`
`sT`.

**Other plugins**
- `<leader>sr` grug-far search and replace (use `:%s` or `:cdo`)
- `<leader>qs` `qS` `ql` `qd` persistence sessions (use `:mksession`)
- `<leader>bp` `bP` `bj` and `[B` `]B` bufferline pin / pick / move
- `<leader>ge` `be` neo-tree git and buffer explorers
- `<leader>l` Lazy, `<leader>L` LazyVim changelog, `<leader>cm` Mason
- `<leader>cv` venv-selector (python extra)
- `<leader>dPt` `dPc` dap-python (python extra)
- `<leader>cR`, `<leader>dr` rustaceanvim code actions / debuggables (rust extra)
