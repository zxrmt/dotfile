local wezterm = require 'wezterm'
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()


wezterm.on('user-var-changed', function(window, pane, name, value)
  wezterm.log_info('var', name, value)
  if name == 'wez_not' then
    window:toast_notification('wezterm', 'msg: ' .. value, nil, 1000)
  end

end)


config.term = "xterm-256color"





wezterm.on('bell', function(window, pane)
  -- Ignore bells from the currently focused pane
  local active = window:active_pane()
  if active and pane:pane_id() == active:pane_id() then
    return
  end

  local tab = pane:tab()
  local tab_title = tab and tab:get_title() or 'other tab'
  window:toast_notification('Notification', 'Task completed: ' .. tab_title, nil, 9000)
end)











-- This is where you actually apply your config choices

config.scrollback_lines = 10000
-- For example, changing the color scheme:
config.enable_scroll_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.max_fps = 120
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
config.keys = {
{ key = 'a', mods = 'CMD', action = wezterm.action_callback(function(window, pane)
    local dims = pane:get_dimensions()
    local txt = pane:get_text_from_region(0, dims.scrollback_top, 0, dims.scrollback_top + dims.scrollback_rows)
    window:copy_to_clipboard(txt:match('^%s*(.-)%s*$')) -- trim leading and trailing whitespace
    end)
}

}


function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end


-- and finally, return the configuration to wezterm
return config
