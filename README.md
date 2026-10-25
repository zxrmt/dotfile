# dotfile
dot

## Updating Neovim plugins

Plugin versions are pinned in `.config/nvim/lazy-lock.json`. Every plugin is
locked to an exact commit SHA, and a SHA is content-addressed, so it cannot be
swapped out upstream later. The `Dockerfile` installs those exact commits at
build time, so a fresh container never fetches plugin code on first launch.

`:Lazy update` / `:Lazy sync` (and `U`/`S` in the Lazy UI) move every plugin to
its newest commit and run build hooks immediately. The update counter in the
statusline invites exactly that. Treat an update as a release instead:

1. Update on the host, not in a container that holds keys.
2. Read `:Lazy log` and the `lazy-lock.json` diff. Unexplained new
   dependencies, build steps or postinstall hooks are the thing to look for.
3. Wait a few days before adopting. Most hijacked releases are caught within
   hours to days.
4. Commit the new lockfile and rebuild the image.

If the `lazy.nvim` entry in the lockfile changes, update `lazy_commit` in
`.config/nvim/lua/config/lazy.lua` to match. That pin covers the bootstrap
clone, which runs before the lockfile is ever read.

The Mason UI's update button carries the same risk for LSP binaries; those
versions are pinned in the `Dockerfile`.
