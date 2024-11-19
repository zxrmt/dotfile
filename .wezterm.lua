local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20

config.scrollback_lines = 10000
-- For example, changing the color scheme:
config.enable_scroll_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.max_fps = 200
config.front_end = "WebGpu"

config.colors = {
  foreground = '#ffffff',
  background = '#1a1b26',
}

config.window_decorations = "RESIZE"
-- config.use_fancy_tab_bar = true

--config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.window_frame = {
        -- no idea how to make these transparent
        inactive_titlebar_bg = "#1a1b26",
        active_titlebar_bg = "#1a1b26",
}
config.window_background_opacity = 0.85
config.macos_window_background_blur = 50


-- and finally, return the configuration to wezterm
return config
