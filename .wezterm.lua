local wezterm = require 'wezterm'
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()


-- config.use_fancy_tab_bar = false
config.tab_max_width = 200


local focused_border = '#7aa2f7'
local unfocused_border = '#2a2a2a'

local function window_frame_with_border(color)
  return {
    border_left_width = '0.15cell',
    border_right_width = '0.15cell',
    border_top_height = '0.15cell',
    border_bottom_height = '0.15cell',

    border_left_color = color,
    border_right_color = color,
    border_top_color = color,
    border_bottom_color = color,
  }
end

-- Keep resize border; use "TITLE | RESIZE" if you want the normal titlebar too.
config.window_decorations = 'RESIZE'

-- Default state.
config.window_frame = window_frame_with_border(unfocused_border)

wezterm.on('window-focus-changed', function(window, pane)
  local overrides = window:get_config_overrides() or {}

  if window:is_focused() then
    overrides.window_frame = window_frame_with_border(focused_border)
  else
    overrides.window_frame = window_frame_with_border(unfocused_border)
  end

  window:set_config_overrides(overrides)
end)




-- Needed so update-status clears alerts soon after you switch tabs.
config.status_update_interval = 250

local ALERT_BG = '#ff5f57'
local ALERT_FG = '#ffffff'

-- tab_id -> true
local bell_alert_tabs = {}

-- window_id -> true/false
local focused_windows = {}

local function tab_title(tab)
  if tab.tab_title and #tab.tab_title > 0 then
    return tab.tab_title
  end
  return tab.active_pane.title
end

local function request_redraw(window)
  -- Nudges WezTerm to recompute the tab bar.
  window:set_config_overrides(window:get_config_overrides() or {})
end

local function clear_active_alert(window)
  focused_windows[window:window_id()] = window:is_focused()

  if not window:is_focused() then
    return
  end

  local tab = window:active_tab()
  if tab then
    bell_alert_tabs[tab:tab_id()] = nil
    request_redraw(window)
  end
end

wezterm.on('bell', function(window, pane)
  local tab = pane:tab()
  if not tab then
    return
  end

  local tab_id = tab:tab_id()
  local active = window:active_tab()

  -- If the bell rings in the tab you're already looking at, don't latch it.
  if window:is_focused() and active and active:tab_id() == tab_id then
    bell_alert_tabs[tab_id] = nil
  else
    bell_alert_tabs[tab_id] = true
  end

  request_redraw(window)
end)

wezterm.on('window-focus-changed', function(window, pane)
  clear_active_alert(window)
end)

wezterm.on('update-status', function(window, pane)
  clear_active_alert(window)
end)

local FIXED_TAB_WIDTH = 20

local function pad_right(s, width)
  local pad = width - wezterm.column_width(s)
  if pad > 0 then
    return s .. string.rep(' ', pad)
  end
  return s
end

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local width = math.min(FIXED_TAB_WIDTH, max_width)

  local title = tab_title(tab)

  local prefix = ' '
  local suffix = ' '

  if bell_alert_tabs[tab.tab_id] then
    prefix = ' 🔔 '
  end

  local title_width = math.max(1, width - wezterm.column_width(prefix) - wezterm.column_width(suffix))
  title = wezterm.truncate_right(title, title_width)
  title = pad_right(title, title_width)

  if bell_alert_tabs[tab.tab_id] then
    return {
      { Background = { Color = ALERT_BG } },
      { Foreground = { Color = ALERT_FG } },
      { Attribute = { Intensity = 'Bold' } },
      { Text = prefix .. title .. suffix },
    }
  end

  return prefix .. title .. suffix
end)

wezterm.on('user-var-changed', function(window, pane, name, value)
  wezterm.log_info('var', name, value)
  if name == 'wez_not' then
    window:toast_notification('wezterm', 'msg: ' .. value, nil, 1000)
  end

end)


config.term = "xterm-256color"

-- blur the wezterm active window
wezterm.on('window-focus-changed', function(window, pane)
  local overrides = window:get_config_overrides() or {}
  if window:is_focused() then
    overrides.window_background_opacity = 0.8
  else
    overrides.window_background_opacity = 1.0
  end
  window:set_config_overrides(overrides)
end)


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
},
-- Ctrl+Backspace -> Ctrl-W : delete the previous word (nvim insert mode, shells, readline)
{ key = 'Backspace', mods = 'CTRL', action = act.SendKey { key = 'w', mods = 'CTRL' } },

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
