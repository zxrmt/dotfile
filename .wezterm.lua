local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20


-- For example, changing the color scheme:
config.enable_scroll_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- and finally, return the configuration to wezterm
return config
