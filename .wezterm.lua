local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()



-- This is where you actually apply your config choices

config.scrollback_lines = 10000
-- For example, changing the color scheme:
config.enable_scroll_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.max_fps = 200
config.front_end = "WebGpu"

config.audible_bell = "Disabled"

config.colors = {
  foreground = '#ffffff',
  --background = '#1a1b26',
  background = '#101010',
}

config.window_decorations = "RESIZE"
--config.use_fancy_tab_bar = true

--config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.window_frame = {
        -- no idea how to make these transparent
        inactive_titlebar_bg = "#1a1b26",
        active_titlebar_bg = "#1a1b26",
}
config.window_background_opacity = 0.95
config.macos_window_background_blur = 50
-- cmd + a to copy to clipboard
config.keys = {
{ key = 'a', mods = 'CMD', action = wezterm.action_callback(function(window, pane)
    local dims = pane:get_dimensions()
    local txt = pane:get_text_from_region(0, dims.scrollback_top, 0, dims.scrollback_top + dims.scrollback_rows)
    window:copy_to_clipboard(txt:match('^%s*(.-)%s*$')) -- trim leading and trailing whitespace
    end)
}

}



-- and finally, return the configuration to wezterm
return config
