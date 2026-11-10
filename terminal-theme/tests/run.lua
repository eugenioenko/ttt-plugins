local script = arg and arg[0] or "tests/run.lua"
local root = script:match("^(.*)/tests/run%.lua$") or "."
local output_path = "{config}/themes/terminal.json"
local foot_main_path = "~/.config/foot/foot.ini"
local foot_theme_path = "~/.local/state/omarchy/current/theme/foot.ini"
local kitty_main_path = "~/.config/kitty/kitty.conf"
local kitty_theme_path = "~/.local/state/omarchy/current/theme/kitty.conf"
local alacritty_main_path = "~/.config/alacritty/alacritty.toml"
local alacritty_theme_path = "~/.local/state/omarchy/current/theme/alacritty.toml"
local ghostty_main_path = "~/.config/ghostty/config"
local ghostty_theme_path = "~/.config/ghostty/themes/MyTheme"
local wezterm_main_path = "~/.config/wezterm/wezterm.lua"

local function eq(got, want, label)
  assert(got == want, (label or "value") .. ": got " .. tostring(got) .. ", want " .. tostring(want))
end

local function contains(value, fragment, label)
  assert(type(value) == "string", (label or "value") .. " is not a string")
  assert(value:find(fragment, 1, true), (label or "value") .. " does not contain " .. tostring(fragment))
end

local function not_eq(got, unwanted, label)
  assert(got ~= unwanted, (label or "value") .. " should differ from " .. tostring(unwanted))
end

local function is_array(t)
  local count = 0
  for key in pairs(t) do
    if type(key) ~= "number" then return false end
    count = count + 1
  end
  for index = 1, count do
    if t[index] == nil then return false end
  end
  return true, count
end

local function encode_json(value)
  local kind = type(value)
  if kind == "string" then return string.format("%q", value) end
  if kind == "number" or kind == "boolean" then return tostring(value) end
  if kind ~= "table" then return "null" end
  local array, length = is_array(value)
  if array then
    local parts = {}
    for index = 1, length do parts[index] = encode_json(value[index]) end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  local keys = {}
  for key in pairs(value) do keys[#keys + 1] = key end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local parts = {}
  for _, key in ipairs(keys) do
    parts[#parts + 1] = string.format("%q", tostring(key)) .. ":" .. encode_json(value[key])
  end
  return "{" .. table.concat(parts, ",") .. "}"
end


local function decode_json(value)
  local i = 1
  local function skip() while i <= #value and value:sub(i, i):match("%s") do i = i + 1 end end
  local parse_value
  local function parse_string()
    assert(value:sub(i, i) == '"', "expected string")
    i = i + 1
    local out = {}
    while i <= #value do
      local c = value:sub(i, i)
      if c == '"' then i = i + 1; return table.concat(out) end
      if c == "\\" then
        local n = value:sub(i + 1, i + 1)
        if n == "n" then out[#out + 1] = "\n"; i = i + 2
        elseif n == "t" then out[#out + 1] = "\t"; i = i + 2
        elseif n == "r" then out[#out + 1] = "\r"; i = i + 2
        elseif n == '"' then out[#out + 1] = '"'; i = i + 2
        elseif n == "\\" then out[#out + 1] = "\\"; i = i + 2
        elseif n == "/" then out[#out + 1] = "/"; i = i + 2
        elseif n == "u" then
          local hex = value:sub(i + 2, i + 5)
          out[#out + 1] = string.char(tonumber(hex, 16))
          i = i + 6
        else
          error("bad escape")
        end
      else
        out[#out + 1] = c
        i = i + 1
      end
    end
    error("unterminated string")
  end
  local function parse_number()
    local start = i
    while i <= #value and value:sub(i, i):match("[%d%+%-%eE%.]") do i = i + 1 end
    return tonumber(value:sub(start, i - 1))
  end
  local function parse_array()
    assert(value:sub(i, i) == "[", "expected array")
    i = i + 1
    skip()
    local arr = {}
    if value:sub(i, i) == "]" then i = i + 1; return arr end
    while true do
      arr[#arr + 1] = parse_value()
      skip()
      if value:sub(i, i) == "," then i = i + 1; skip()
      elseif value:sub(i, i) == "]" then i = i + 1; break
      else error("expected , or ]") end
    end
    return arr
  end
  local function parse_object()
    assert(value:sub(i, i) == "{", "expected object")
    i = i + 1
    skip()
    local obj = {}
    if value:sub(i, i) == "}" then i = i + 1; return obj end
    while true do
      skip()
      local key = parse_string()
      skip()
      assert(value:sub(i, i) == ":", "expected :")
      i = i + 1
      skip()
      obj[key] = parse_value()
      skip()
      if value:sub(i, i) == "," then i = i + 1; skip()
      elseif value:sub(i, i) == "}" then i = i + 1; break
      else error("expected , or }") end
    end
    return obj
  end
  parse_value = function()
    skip()
    local c = value:sub(i, i)
    if c == '"' then return parse_string()
    elseif c == "{" then return parse_object()
    elseif c == "[" then return parse_array()
    elseif c == "t" then assert(value:sub(i, i + 3) == "true"); i = i + 4; return true
    elseif c == "f" then assert(value:sub(i, i + 4) == "false"); i = i + 5; return false
    elseif c == "n" then assert(value:sub(i, i + 3) == "null"); i = i + 4; return nil
    else return parse_number() end
  end
  local result = parse_value()
  skip()
  return result
end

local function reader_for(files)
  return function(path)
    local value = files[path]
    if value == nil then return nil, "not found" end
    return value
  end
end

local function env_for(values)
  return function(name) return values[name] or "" end
end

local function load_plugin(options)
  options = options or {}
  for _, name in ipairs({ "ttt", "ttt.fs", "ttt.settings", "ttt.json", "ttt.system" }) do
    package.loaded[name] = nil
    package.preload[name] = nil
  end

  local mock = {
    files = options.files or {},
    env = options.env or { TERM = "foot" },
    selected_theme = options.selected_theme or "terminal",
    write_error = options.write_error,
    command_failures = options.command_failures or 0,
    without_notify = options.without_notify,
    writes = {},
    commands = {},
    logs = {},
    notifications = {},
    settings_reads = {},
    reads = {},
    env_reads = {},
  }

  local ttt = {
    register = function(config) mock.registration = config end,
    log = function(level, message) mock.logs[#mock.logs + 1] = { level, message } end,
    exec_command = function(id)
      mock.commands[#mock.commands + 1] = id
      if mock.command_failures > 0 then
        mock.command_failures = mock.command_failures - 1
        return false
      end
      return true
    end,
    set_timeout = function(ms, callback)
      mock.startup_timeout_ms = ms
      mock.startup_poll = callback
      return 2
    end,
    set_interval = function(ms, callback)
      mock.interval_ms = ms
      mock.poll = callback
      return 1
    end,
  }
  if not mock.without_notify then
    ttt.notify = function(message, level)
      mock.notifications[#mock.notifications + 1] = { level, message }
    end
  end

  local fs = {
    read = function(path)
      mock.reads[#mock.reads + 1] = path
      local value = mock.files[path]
      if value == nil then return nil, mock.read_errors and mock.read_errors[path] or "not found" end
      return value
    end,
    exists = function(path)
      if mock.exists_override then return mock.exists_override(path) end
      return mock.files[path] ~= nil
    end,
    write = function(path, content)
      if mock.write_error then return nil, mock.write_error end
      mock.writes[#mock.writes + 1] = { path = path, content = content }
      mock.snapshot = content
      mock.snapshot_path = path
      return true
    end,
  }
  local settings = {
    get = function(key)
      mock.settings_reads[#mock.settings_reads + 1] = key
      assert(key == "theme", "plugin read unexpected setting " .. tostring(key))
      return mock.selected_theme
    end,
  }
  local json = {
    encode = function(theme)
      mock.theme = theme
      return encode_json(theme)
    end,
    decode = function(value)
      return decode_json(value)
    end,
  }
  local system = {
    env = function(name)
      mock.env_reads[#mock.env_reads + 1] = name
      return mock.env[name] or ""
    end,
  }

  package.preload.ttt = function() return ttt end
  package.preload["ttt.fs"] = function() return fs end
  package.preload["ttt.settings"] = function() return settings end
  package.preload["ttt.json"] = function() return json end
  package.preload["ttt.system"] = function() return system end
  local plugin = dofile(root .. "/init.lua")
  mock.plugin = plugin
  eq(mock.startup_timeout_ms, 100, "deferred initial poll")
  eq(mock.interval_ms, 2000, "poll interval")
  mock.startup_poll()
  return mock
end

local foot_theme = table.concat({
  "[colors-dark]",
  "foreground=#f6dcac",
  "background=#05182e",
  "selection-background=#134e5a",
  "cursor=#05182e #f6dcac",
  "regular0=#05182e",
  "regular1=#f85525",
  "regular2=#028391",
  "regular3=#e97b3c",
  "regular4=#3f8f8a",
  "regular5=#3f8f8a",
  "regular6=#8cbfb8",
  "regular7=#f6dcac",
  "bright0=#2a6b78",
  "bright1=#f85525",
  "bright2=#028391",
  "bright3=#e97b3c",
  "bright4=#faa968",
  "bright5=#3f8f8a",
  "bright6=#8cbfb8",
  "bright7=#f6dcac",
}, "\n")
local foot_main = "include=" .. foot_theme_path .. "\n"

local kitty_theme = table.concat({
  "foreground #f6dcac",
  "background #05182e",
  "selection_background #134e5a",
  "cursor #f6dcac",
  "color0 #05182e",
  "color1 #f85525",
  "color2 #028391",
  "color3 #e97b3c",
  "color4 #3f8f8a",
  "color5 #3f8f8a",
  "color6 #8cbfb8",
  "color7 #f6dcac",
  "color8 #2a6b78",
  "color9 #f85525",
  "color10 #028391",
  "color11 #e97b3c",
  "color12 #faa968",
  "color13 #3f8f8a",
  "color14 #8cbfb8",
  "color15 #f6dcac",
}, "\n")
local kitty_main = "include " .. kitty_theme_path .. "\n"

local alacritty_theme = table.concat({
  "[colors.primary]",
  'background = "#05182e"',
  'foreground = "#f6dcac"',
  "[colors.selection]",
  'background = "#134e5a"',
  "[colors.cursor]",
  'cursor = "#f6dcac"',
  "[colors.normal]",
  'black = "#05182e"',
  'red = "#f85525"',
  'green = "#028391"',
  'yellow = "#e97b3c"',
  'blue = "#3f8f8a"',
  'magenta = "#3f8f8a"',
  'cyan = "#8cbfb8"',
  'white = "#f6dcac"',
  "[colors.bright]",
  'black = "#2a6b78"',
  'red = "#f85525"',
  'green = "#028391"',
  'yellow = "#e97b3c"',
  'blue = "#faa968"',
  'magenta = "#3f8f8a"',
  'cyan = "#8cbfb8"',
  'white = "#f6dcac"',
}, "\n")
local alacritty_main = 'general.import = [ "' .. alacritty_theme_path .. '" ]\n'

local ghostty_theme = table.concat({
  "background = #05182e",
  "foreground = #f6dcac",
  "cursor-color = #f6dcac",
  "selection-background = #134e5a",
  "palette = 0=#05182e",
  "palette = 1=#f85525",
  "palette = 2=#028391",
  "palette = 3=#e97b3c",
  "palette = 4=#3f8f8a",
  "palette = 5=#3f8f8a",
  "palette = 6=#8cbfb8",
  "palette = 7=#f6dcac",
  "palette = 8=#2a6b78",
  "palette = 9=#f85525",
  "palette = 10=#028391",
  "palette = 11=#e97b3c",
  "palette = 12=#faa968",
  "palette = 13=#3f8f8a",
  "palette = 14=#8cbfb8",
  "palette = 15=#f6dcac",
}, "\n")
local ghostty_main = "theme = dark:MyTheme\n"

local wezterm_source = table.concat({
  "local wezterm = require 'wezterm'",
  "return {",
  "  colors = {",
  "    foreground = '#f6dcac',",
  "    background = '#05182e',",
  "    selection_bg = '#134e5a',",
  "    cursor_bg = '#f6dcac',",
  "    ansi = { '#05182e', '#f85525', '#028391', '#e97b3c', '#3f8f8a', '#3f8f8a', '#8cbfb8', '#f6dcac' },",
  "    brights = { '#2a6b78', '#f85525', '#028391', '#e97b3c', '#faa968', '#3f8f8a', '#8cbfb8', '#f6dcac' },",
  "  },",
  "}",
}, "\n")

local first = load_plugin({
  files = {
    [foot_main_path] = foot_main,
    [foot_theme_path] = foot_theme,
  },
})
local M = first.plugin

-- Parser unit tests -------------------------------------------------------

local parsed_foot = M.parse_foot_config(table.concat({
  "# full line comment with an = sign must be ignored",
  "include=~/.config/foot/extra.ini",
  "[colors]",
  "foreground = #eeeeee # trailing comment",
  "background = #101010",
  "cursor = #eeeeee",
  "",
}, "\n"))
eq(parsed_foot.includes[1], "~/.config/foot/extra.ini", "foot include")
eq(parsed_foot.sections.colors.foreground, "#eeeeee", "foot color with # prefix and inline comment")
eq(parsed_foot.sections.colors.background, "#101010", "foot color value")
eq(parsed_foot.sections.colors.cursor, "#eeeeee", "foot cursor")
eq(parsed_foot.sections["# full line comment with an = sign must be ignored"], nil, "foot full-line comment")

local parsed_kitty = M.parse_kitty_config(table.concat({
  "# comment",
  "include ~/.config/kitty/extra.conf",
  "foreground #eeeeee",
  "background #101010",
  "color1 #cc3333",
  "selection_background #223344",
}, "\n"))
eq(parsed_kitty.includes[1], "~/.config/kitty/extra.conf", "kitty include")
eq(parsed_kitty.values.foreground, "#eeeeee", "kitty space syntax")
eq(parsed_kitty.values.color1, "#cc3333", "kitty color key")
eq(parsed_kitty.values.selection_background, "#223344", "kitty selection")

local parsed_ghostty = M.parse_ghostty_config(table.concat({
  "# comment",
  "config-file = ~/.config/ghostty/extra.conf",
  "background = #101010",
  "palette = 1=#cc3333",
  "palette = 12=#ff5555",
  "theme = dark:MyTheme",
}, "\n"))
eq(parsed_ghostty.includes[1], "~/.config/ghostty/extra.conf", "ghostty include")
eq(parsed_ghostty.values.background, "#101010", "ghostty value")
eq(parsed_ghostty.palette[1], "#cc3333", "ghostty palette")
eq(parsed_ghostty.palette[12], "#ff5555", "ghostty bright palette")
eq(parsed_ghostty.values.theme, "dark:MyTheme", "ghostty theme")

local parsed_alacritty = M.parse_alacritty_config(table.concat({
  'general.import = [ "~/.config/alacritty/colors.toml" ]',
  "[colors.primary]",
  'background = "#101010" # inline comment',
  'foreground = "#eeeeee"',
  "[colors.normal]",
  'red = "#cc3333"',
  "[colors.bright]",
  "blue = '#5555ff'",
}, "\n"))
eq(parsed_alacritty.imports[1], "~/.config/alacritty/colors.toml", "alacritty import")
eq(parsed_alacritty.values["colors.primary.foreground"], "#eeeeee", "alacritty primary")
eq(parsed_alacritty.values["colors.primary.background"], "#101010", "alacritty comment stripped")
eq(parsed_alacritty.values["colors.normal.red"], "#cc3333", "alacritty normal")
eq(parsed_alacritty.values["colors.bright.blue"], "#5555ff", "alacritty bright single quotes")

local parsed_wezterm = M.parse_wezterm_config(wezterm_source)
eq(#parsed_wezterm.tables, 1, "wezterm colors table count")
eq(parsed_wezterm.tables[1].foreground, "#f6dcac", "wezterm foreground")
eq(parsed_wezterm.color_scheme, nil, "wezterm inline palette has no scheme")
local nested_source = table.concat({
  "-- comment",
  "return { colors = {",
  "  foreground = { Color = '#eeeeee' },",
  "  background = { Color = '#101010' },",
  "  ansi = { { Color = '#000000' }, { Color = '#cc3333' } },",
  "}, color_scheme = 'Cool' }",
}, "\n")
local nested_parsed = M.parse_wezterm_config(nested_source)
eq(nested_parsed.color_scheme, "Cool", "wezterm color_scheme")
local nested_palette = M.load_palette("wezterm", wezterm_main_path, reader_for({
  [wezterm_main_path] = nested_source,
}), env_for({}))
eq(nested_palette.fg, "#eeeeee", "wezterm nested Color foreground")
eq(nested_palette.ansi[1], "#cc3333", "wezterm nested Color ansi")

-- Include/import resolution ----------------------------------------------

local foot_palette, foot_warnings = M.load_palette("foot", foot_main_path, reader_for({
  [foot_main_path] = foot_main,
  [foot_theme_path] = foot_theme,
}), env_for({}))
eq(foot_palette.fg, "#f6dcac", "foot include foreground")
eq(foot_palette.bg, "#05182e", "foot include background")
eq(foot_palette.ansi[1], "#f85525", "foot include red")
eq(foot_palette.ansi[12], "#faa968", "foot include bright blue")
eq(foot_palette.selection, "#134e5a", "foot include selection")
eq(foot_palette.cursor, "#05182e", "foot include cursor")
eq(#foot_warnings, 0, "foot include has no warnings")

local precedence = M.load_palette("foot", foot_main_path, reader_for({
  [foot_main_path] = table.concat({
    "[colors]",
    "foreground=#111111",
    "background=#222222",
    "[colors-dark]",
    "foreground=#333333",
    "background=#444444",
  }, "\n"),
}), env_for({}))
eq(precedence.fg, "#111111", "[colors] wins over [colors-dark]")
eq(precedence.bg, "#222222", "[colors] background wins over [colors-dark]")

local missing_include = M.load_palette("foot", foot_main_path, reader_for({
  [foot_main_path] = "include=~/.config/foot/missing.ini\n[colors]\nforeground=#111111\nbackground=#222222\n",
}), env_for({}))
eq(missing_include.fg, "#111111", "missing include falls back to the main config")

local cycle = M.load_palette("foot", foot_main_path, reader_for({
  [foot_main_path] = "include=~/.config/foot/foot.ini\n[colors]\nforeground=#111111\nbackground=#222222\n",
}), env_for({}))
eq(cycle.fg, "#111111", "cyclic include does not crash")

local kitty_palette = M.load_palette("kitty", kitty_main_path, reader_for({
  [kitty_main_path] = kitty_main,
  [kitty_theme_path] = kitty_theme,
}), env_for({}))
eq(kitty_palette.fg, "#f6dcac", "kitty include foreground")
eq(kitty_palette.ansi[0], "#05182e", "kitty include black")
eq(kitty_palette.ansi[15], "#f6dcac", "kitty include bright white")

local alacritty_palette = M.load_palette("alacritty", alacritty_main_path, reader_for({
  [alacritty_main_path] = alacritty_main,
  [alacritty_theme_path] = alacritty_theme,
}), env_for({}))
eq(alacritty_palette.fg, "#f6dcac", "alacritty import foreground")
eq(alacritty_palette.ansi[4], "#3f8f8a", "alacritty import blue")
eq(alacritty_palette.selection, "#134e5a", "alacritty import selection")

local ghostty_palette, ghostty_warnings = M.load_palette("ghostty", ghostty_main_path, reader_for({
  [ghostty_main_path] = ghostty_main,
  [ghostty_theme_path] = ghostty_theme,
}), env_for({}))
eq(ghostty_palette.fg, "#f6dcac", "ghostty theme foreground")
eq(ghostty_palette.ansi[1], "#f85525", "ghostty theme red")
eq(#ghostty_warnings, 0, "ghostty theme has no warnings")

local missing_ghostty, missing_ghostty_warnings = M.load_palette("ghostty", ghostty_main_path, reader_for({
  [ghostty_main_path] = "theme = dark:Missing\n",
}), env_for({}))
eq(missing_ghostty.fg, nil, "missing ghostty theme leaves no foreground")
contains(missing_ghostty_warnings[1], "Ghostty theme not found", "ghostty missing theme warning")

local wezterm_palette = M.load_palette("wezterm", wezterm_main_path, reader_for({
  [wezterm_main_path] = wezterm_source,
}), env_for({}))
eq(wezterm_palette.fg, "#f6dcac", "wezterm foreground")
eq(wezterm_palette.bg, "#05182e", "wezterm background")
eq(wezterm_palette.ansi[2], "#028391", "wezterm green")
eq(wezterm_palette.selection, "#134e5a", "wezterm selection")

local _env_json = '{"fg":"#f6dcac","bg":"#05182e","ansi":[],"selection":"#134e5a"}'
local _env = env_for({ TTT_TERMINAL_PALETTE = _env_json })
local env_direct, env_err = M.load_palette("env", "TTT_TERMINAL_PALETTE", reader_for({}), _env)
eq(env_direct.fg, "#f6dcac", "env foreground")
eq(env_direct.bg, "#05182e", "env background")
eq(env_direct.selection, "#134e5a", "env selection")

local scheme_only, scheme_error = M.load_palette("wezterm", wezterm_main_path, reader_for({
  [wezterm_main_path] = "return { color_scheme = 'Cool' }\n",
}), env_for({}))
eq(scheme_only, nil, "wezterm color_scheme-only config fails")
contains(scheme_error, "color_scheme", "wezterm scheme error mentions color_scheme")

local missing_main, missing_error = M.load_palette("foot", foot_main_path, reader_for({}), env_for({}))
eq(missing_main, nil, "missing main config fails")
contains(missing_error, "not found", "missing main config error")

local absolute_palette = M.load_palette("foot", foot_main_path, reader_for({
  [foot_main_path] = "include=$FOOT_THEME\n",
  ["/tmp/foot-theme.ini"] = foot_theme,
}), env_for({ FOOT_THEME = "/tmp/foot-theme.ini" }))
eq(absolute_palette.fg, "#f6dcac", "environment variable include path")

-- Detection ---------------------------------------------------------------

local function exists_for(paths)
  local set = {}
  for _, path in ipairs(paths) do set[path] = true end
  return function(path) return set[path] == true end
end

local detected, detected_path = M.detect(env_for({ TTT_TERMINAL_THEME = "kitty" }), exists_for({ kitty_main_path }))
eq(detected, "kitty", "forced source")
eq(detected_path, kitty_main_path, "forced source path")

local unknown, _, unknown_error = M.detect(env_for({ TTT_TERMINAL_THEME = "mintty" }), exists_for({}))
eq(unknown, nil, "unknown forced source")
contains(unknown_error, "unknown TTT_TERMINAL_THEME", "unknown forced source error")

detected = M.detect(env_for({ TERM_PROGRAM = "ghostty" }), exists_for({ ghostty_main_path }))
eq(detected, "ghostty", "ghostty environment detection")
detected = M.detect(env_for({ KITTY_WINDOW_ID = "1" }), exists_for({ kitty_main_path }))
eq(detected, "kitty", "kitty environment detection")
detected = M.detect(env_for({ WEZTERM_PANE = "1" }), exists_for({ wezterm_main_path }))
eq(detected, "wezterm", "wezterm environment detection")
detected = M.detect(env_for({ ALACRITTY_SOCKET = "/tmp/sock" }), exists_for({ alacritty_main_path }))
eq(detected, "alacritty", "alacritty environment detection")
detected = M.detect(env_for({ TERM = "foot" }), exists_for({ foot_main_path }))
eq(detected, "foot", "foot environment detection")

local fallback, fallback_path, _, fallback_info = M.detect(env_for({}), exists_for({
  kitty_main_path,
  alacritty_main_path,
}))
eq(fallback, "kitty", "fallback picks first supported source")
eq(fallback_path, kitty_main_path, "fallback path")
contains(fallback_info, "multiple terminal configs found", "ambiguous detection info")
contains(fallback_info, "TTT_TERMINAL_THEME", "ambiguous detection hint")

local none, _, none_error = M.detect(env_for({}), exists_for({}))
eq(none, nil, "no config detected")
contains(none_error, "no supported terminal config found", "no config error")

local env_only, _, env_only_error = M.detect(env_for({ TERM = "foot" }), exists_for({}))
eq(env_only, nil, "detected terminal without config fails")
contains(env_only_error, "Foot config not found", "detected terminal missing config error")

-- Conversion --------------------------------------------------------------

local converted, build_info = M.convert({
  fg = "#eeeeee",
  bg = "#101010",
  selection = "#223344",
  ansi = {
    [0] = "#101010", [1] = "#ff6b6b", [2] = "#69db7c", [3] = "#ffd43b",
    [4] = "#74c0fc", [5] = "#da77f2", [6] = "#66d9e8", [7] = "#f1f3f5",
    [8] = "#adb5bd", [9] = "#ff8787", [10] = "#8ce99a", [11] = "#ffe066",
    [12] = "#a5d8ff", [13] = "#e599f7", [14] = "#99e9f2", [15] = "#ffffff",
  },
})
eq(converted.default.fg, "#eeeeee", "converted foreground")
eq(converted.default.bg, "#101010", "converted background")
eq(converted.danger.fg, "#ff6b6b", "converted danger")
eq(converted.success.fg, "#69db7c", "converted success")
assert(converted.syntax.comment.italic, "comment style keeps italic")
assert(converted.syntax.heading.bold, "heading style keeps bold")
eq(converted.terminal.foreground, "#eeeeee", "terminal foreground")
eq(converted.terminal.background, "#101010", "terminal background")
eq(converted.terminal.selection, "#223344", "terminal selection")
eq(converted.terminal.black, "#101010", "terminal black")
eq(converted.terminal.brightWhite, "#ffffff", "terminal bright white")
eq(build_info.missing, 0, "all ANSI colors present")

local empty_group = nil
local function find_empty_group(value, path)
  for key, child in pairs(value) do
    if type(child) == "table" then
      if next(child) == nil then
        empty_group = empty_group or (path .. "." .. tostring(key))
      else
        find_empty_group(child, path .. "." .. tostring(key))
      end
    end
  end
end
find_empty_group(converted, "theme")
eq(empty_group, nil, "empty style groups are dropped")

local low_contrast = M.convert({
  fg = "#bebebe",
  bg = "#121212",
  ansi = { [0] = "#121212", [1] = "#333333", [7] = "#bebebe", [8] = "#333333" },
})
not_eq(low_contrast.syntax.comment.fg, "#333333", "low contrast color is corrected")
not_eq(low_contrast.danger.fg, "#333333", "low contrast danger is corrected")

local fallback_theme, fallback_info = M.convert({ fg = "#eeeeee", bg = "#101010" })
eq(fallback_theme.terminal.black, "#1e1e1e", "missing ANSI uses fallback")
eq(fallback_info.missing, 16, "missing ANSI count")
local invalid_theme, invalid_error = M.convert({ fg = "not-a-color", bg = "#101010" })
eq(invalid_theme, nil, "invalid foreground fails")
contains(invalid_error, "foreground and background", "invalid foreground error")

-- Snapshot and reload behavior -------------------------------------------

eq(#first.writes, 1, "initial snapshot write")
eq(first.writes[1].path, output_path, "snapshot path")
eq(#first.commands, 1, "reload selected theme")
eq(first.commands[1], "settings.reload", "reload command")
eq(#first.settings_reads, 1, "read selected setting after write")
eq(first.settings_reads[1], "theme", "setting key")
eq(#first.notifications, 0, "successful sync does not notify")
eq(first.registration and next(first.registration), nil, "no UI registration")
eq(first.theme.default.fg, "#f6dcac", "snapshot foreground")
eq(first.theme.default.bg, "#05182e", "snapshot background")
eq(first.theme.terminal.black, "#05182e", "snapshot terminal black")
eq(first.theme.terminal.brightBlack, "#2a6b78", "snapshot terminal bright black")

first.poll()
eq(#first.writes, 1, "unchanged source does not rewrite snapshot")
eq(#first.commands, 1, "unchanged source does not reload")
eq(#first.settings_reads, 1, "unchanged source does not read settings")

first.files[foot_theme_path] = foot_theme:gsub("foreground=#f6dcac", "foreground=#eeeeee")
first.poll()
eq(#first.writes, 2, "changed source updates snapshot")
eq(first.theme.default.fg, "#eeeeee", "changed source updates foreground")
eq(#first.commands, 2, "changed source reloads selected theme")

local unselected = load_plugin({
  files = { [foot_main_path] = foot_main, [foot_theme_path] = foot_theme },
  selected_theme = "other",
})
eq(#unselected.writes, 1, "unselected theme still gets a snapshot")
eq(#unselected.commands, 0, "unselected theme is not reloaded")
eq(#unselected.settings_reads, 1, "unselected theme checks the selected setting")
unselected.files[foot_theme_path] = foot_theme:gsub("bright4=#faa968", "bright4=#88ccff")
unselected.poll()
eq(#unselected.writes, 2, "changed source updates unselected snapshot")
eq(#unselected.commands, 0, "changed source does not change selected theme")

local retry_reload = load_plugin({
  files = { [foot_main_path] = foot_main, [foot_theme_path] = foot_theme },
  command_failures = 1,
})
eq(#retry_reload.writes, 1, "failed reload follows a successful snapshot write")
eq(#retry_reload.commands, 1, "selected theme reload attempted")
retry_reload.poll()
eq(#retry_reload.writes, 1, "reload retry does not rewrite snapshot")
eq(#retry_reload.commands, 2, "failed reload is retried on the next poll")
eq(#retry_reload.settings_reads, 2, "reload retry checks the selected theme")
retry_reload.poll()
eq(#retry_reload.commands, 2, "successful reload is not repeated")

local retry_write = load_plugin({
  files = { [foot_main_path] = foot_main, [foot_theme_path] = foot_theme },
  write_error = "themes directory missing",
})
eq(#retry_write.writes, 0, "failed output write has no success")
eq(#retry_write.commands, 0, "failed output write does not reload")
eq(#retry_write.settings_reads, 0, "failed output write does not read settings")
contains(retry_write.logs[1][2], "mkdir -p ~/.config/ttt/themes", "missing directory guidance")
eq(#retry_write.notifications, 1, "failed output write notifies")
retry_write.write_error = nil
retry_write.poll()
eq(#retry_write.writes, 1, "failed output write retries")
eq(#retry_write.commands, 1, "successful retry reloads selected theme")
eq(#retry_write.notifications, 1, "successful retry does not notify again")

local unavailable = load_plugin({
  files = { [foot_main_path] = foot_main, [foot_theme_path] = foot_theme },
})
local retained_snapshot = unavailable.snapshot
unavailable.files[foot_main_path] = nil
unavailable.env = {}
unavailable.poll()
eq(unavailable.snapshot, retained_snapshot, "missing source retains static snapshot")
eq(#unavailable.writes, 1, "missing source does not write or delete snapshot")
eq(#unavailable.commands, 1, "missing source does not reload")
contains(unavailable.notifications[1][2], "no supported terminal config found", "missing source reason")

unavailable.env = { TERM = "foot" }
unavailable.files[foot_main_path] = foot_main
unavailable.files[foot_theme_path] = foot_theme:gsub("regular4=#3f8f8a", "regular4=#66aaff")
unavailable.poll()
eq(#unavailable.writes, 2, "recovered source updates snapshot")

local no_notify = load_plugin({
  files = { [foot_main_path] = "foreground=#fff\n" },
  without_notify = true,
})
eq(#no_notify.writes, 0, "invalid palette is not written")
eq(#no_notify.logs, 1, "host without ttt.notify still logs")
contains(no_notify.logs[1][2], "Terminal theme: ", "log prefix")

-- Environment palette ----------------------------------------------------

local env_json = encode_json({
  fg = "#f6dcac",
  bg = "#05182e",
  selection = "#134e5a",
  cursor = "#f6dcac",
  ansi = {
    "#05182e", "#f85525", "#028391", "#e97b3c",
    "#3f8f8a", "#3f8f8a", "#8cbfb8", "#f6dcac",
    "#2a6b78", "#f85525", "#028391", "#e97b3c",
    "#faa968", "#3f8f8a", "#8cbfb8", "#f6dcac",
  },
})

local env_plugin = load_plugin({
  files = { [foot_main_path] = foot_main },
  env = { TERM = "xterm-256color", TTT_TERMINAL_PALETTE = env_json },
})
eq(env_plugin.writes[1].path, output_path, "env palette writes snapshot")
contains(env_plugin.writes[1].content, '"default":{"bg":"#05182e","fg":"#f6dcac"}', "env palette content")
assert(env_plugin.env_reads[#env_plugin.env_reads] == "TTT_TERMINAL_PALETTE", "reads env palette")
-- env palette wins over detected terminal configs
assert(not (env_plugin.reads[1] == foot_main_path), "env palette does not read foot config first")

local env_foreground_keys = load_plugin({
  env = { TTT_TERMINAL_PALETTE = encode_json({
    foreground = "#ffffff",
    background = "#000000",
    ansi = {},
  }) },
})
eq(env_foreground_keys.writes[1].path, output_path, "foreground/background keys accepted")

local env_invalid = load_plugin({
  env = { TTT_TERMINAL_PALETTE = "{not json" },
})
eq(#env_invalid.writes, 0, "invalid env palette is not written")
contains(env_invalid.logs[1][2], "TTT_TERMINAL_PALETTE must be a JSON object", "invalid env error")

local env_missing = load_plugin({
  env = { TTT_TERMINAL_PALETTE = encode_json({ fg = "#ffffff" }) },
})
eq(#env_missing.writes, 0, "env palette missing bg is not written")
contains(env_missing.logs[1][2], "must include fg/foreground and bg/background", "missing field error")

-- Permission hygiene ------------------------------------------------------

for _, path in ipairs(first.reads) do
  local allowed = path == foot_main_path
    or path == foot_theme_path
    or path == kitty_main_path
    or path == kitty_theme_path
    or path == alacritty_main_path
    or path == alacritty_theme_path
    or path == ghostty_main_path
    or path == ghostty_theme_path
    or path == wezterm_main_path
    or path == "/tmp/foot-theme.ini"
  assert(allowed, "plugin read outside test fixtures: " .. path)
end

print("terminal theme plugin tests passed")
