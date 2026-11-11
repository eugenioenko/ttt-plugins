local M = {}

local theme_name = "terminal"
local output_path = "{config}/themes/terminal.json"
local poll_timeout_ms = 250
local max_palette_polls = 80
local minimum_contrast_ratio = 4.5
local selection_blend = 0.28
local surface_blend = 0.08
local search_match_blend = 0.35
local diff_blend = 0.18

local DEFAULT = {
  default = { fg = "#fafafa", bg = "#1f1f1f" },
  muted = { fg = "#888888" },
  success = {},
  danger = {},
  warning = {},
  conflict = {},
  statusBar = {},
  commitHeader = {},
  tabs = {
    active = { fg = "#ffffff", bold = true },
    inactive = { fg = "#999999" },
    selected = {},
  },
  sidebar = {
    header = { fg = "#ffffff", bold = true },
    item = {},
    selected = {},
  },
  dialog = {
    input = {},
    item = {},
    selected = {},
    muted = {},
  },
  editor = {
    lineNumber = { fg = "#999999" },
    activeLine = {},
    selection = {},
    searchMatch = {},
    searchActive = {},
    bracketMatch = {},
    bracketColors = { "blue", "magenta", "cyan" },
    diagnostics = { error = {}, warning = {}, info = {}, hint = {} },
  },
  menu = {
    item = {},
    active = { bold = true },
  },
  input = { item = {}, placeholder = {}, action = {} },
  button = { item = {}, focused = {} },
  hover = { bold = {}, italic = {}, code = {} },
  border = { fg = "#555555" },
  borderActive = {},
  diff = {
    added = {},
    deleted = {},
    modified = {},
    collapsedEmphasis = { bold = true },
    collapsedHover = {},
    gutterAdded = {},
    gutterDeleted = {},
    gutterModified = {},
    gutterBookmark = {},
  },
  scrollbar = { fg = "#999999", bg = "#555555" },
  syntax = {
    comment = {},
    string = {},
    keyword = {},
    number = {},
    operator = {},
    ["function"] = {},
    type = {},
    builtin = {},
    variable = {},
    punctuation = {},
    tag = {},
    attribute = {},
    regexp = {},
    heading = {},
    bold = {},
    italic = {},
    quote = {},
    inserted = {},
    deleted = {},
    invalid = {},
    control = {},
    storage = {},
    constant = {},
    escape = {},
    parameter = {},
    property = {},
    self = {},
    namespace = {},
    decorator = {},
    link = {},
    code = {},
    interpolation = {},
    selector = {},
    readonlyVariable = {},
  },
  fileIcons = {
    red = {},
    yellow = {},
    green = {},
    cyan = {},
    blue = {},
    magenta = {},
  },
  borders = {
    horizontal = "─",
    vertical = "│",
    topLeft = "╭",
    topRight = "╮",
    bottomLeft = "╰",
    bottomRight = "╯",
    topTee = "┬",
    bottomTee = "┴",
    leftTee = "├",
    rightTee = "┤",
  },
  terminal = {
    black = "#000000",
    red = "#ff0000",
    green = "#00ff00",
    yellow = "#ffff00",
    blue = "#0000ff",
    magenta = "#ff00ff",
    cyan = "#00ffff",
    white = "#ffffff",
    brightBlack = "#808080",
    brightRed = "#ff5555",
    brightGreen = "#55ff55",
    brightYellow = "#ffff55",
    brightBlue = "#5555ff",
    brightMagenta = "#ff55ff",
    brightCyan = "#55ffff",
    brightWhite = "#ffffff",
  },
}

-- Fallbacks for terminals that omit part of their palette. They are only used
-- for entries the terminal does not define.
local FALLBACK_ANSI = {
  "#1e1e1e", "#f44747", "#6a9955", "#d7ba7d",
  "#569cd6", "#c586c0", "#4ec9b0", "#d4d4d4",
  "#808080", "#f14c4c", "#73c991", "#e2c08d",
  "#6cb6ff", "#d670d6", "#58d1c9", "#e5e5e5",
}

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = copy(item) end
  return result
end

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parse_hex(value)
  if type(value) ~= "string" then return nil end
  value = trim(value)
  if value:sub(1, 1) == "#" then
    value = value:sub(2)
  elseif value:sub(1, 2):lower() == "0x" then
    value = value:sub(3)
  end
  value = value:lower()
  if #value == 8 and value:match("^%x+$") then
    value = value:sub(1, 6)
  end
  if #value == 3 and value:match("^%x+$") then
    value = value:sub(1, 1):rep(2) .. value:sub(2, 2):rep(2) .. value:sub(3, 3):rep(2)
  end
  if #value == 6 and value:match("^%x+$") then
    return "#" .. value
  end
  return nil
end

local function normalize_color(value)
  if type(value) ~= "string" then return nil end
  local red, green, blue = value:match("^rgb:([%x]+)/([%x]+)/([%x]+)$")
  if not red or #red > 4 or #green > 4 or #blue > 4 then return parse_hex(value) end
  local function component(part)
    local maximum = 16 ^ #part - 1
    return math.floor(tonumber(part, 16) * 255 / maximum + 0.5)
  end
  return string.format("#%02x%02x%02x", component(red), component(green), component(blue))
end

local function rgb(value)
  if type(value) ~= "string" or not value:match("^#%x%x%x%x%x%x$") then return nil end
  return tonumber(value:sub(2, 3), 16), tonumber(value:sub(4, 5), 16), tonumber(value:sub(6, 7), 16)
end

local function hex(r, g, b)
  return string.format("#%02x%02x%02x", math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

local function mix(background, foreground, amount)
  local br, bg, bb = rgb(background)
  local fr, fg, fb = rgb(foreground)
  if not br or not fr then return background end
  return hex(br + (fr - br) * amount, bg + (fg - bg) * amount, bb + (fb - bb) * amount)
end

local function luminance(r, g, b)
  local function channel(value)
    value = value / 255
    if value <= 0.04045 then return value / 12.92 end
    return ((value + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

local function contrast(r1, g1, b1, r2, g2, b2)
  local first, second = luminance(r1, g1, b1), luminance(r2, g2, b2)
  if first < second then first, second = second, first end
  return (first + 0.05) / (second + 0.05)
end

local function safe(foreground, background, fallback)
  local r, g, b = rgb(foreground)
  local br, bg, bb = rgb(background)
  if not r then
    foreground = fallback
    r, g, b = rgb(foreground)
  end
  if not r or not br then return foreground end
  if contrast(r, g, b, br, bg, bb) >= minimum_contrast_ratio then return foreground end

  local target = { 0, 0, 0 }
  if contrast(255, 255, 255, br, bg, bb) > contrast(0, 0, 0, br, bg, bb) then
    target = { 255, 255, 255 }
  end
  for step = 1, 255 do
    local amount = step / 255
    local candidate = hex(
      r + (target[1] - r) * amount,
      g + (target[2] - g) * amount,
      b + (target[3] - b) * amount
    )
    local cr, cg, cb = rgb(candidate)
    if contrast(cr, cg, cb, br, bg, bb) >= minimum_contrast_ratio then return candidate end
  end
  return hex(target[1], target[2], target[3])
end

local function readable_on(background)
  local br, bg, bb = rgb(background)
  if not br then return "#ffffff" end
  if contrast(0, 0, 0, br, bg, bb) >= contrast(255, 255, 255, br, bg, bb) then
    return "#000000"
  end
  return "#ffffff"
end

local function set(style, foreground, background)
  if foreground then style.fg = foreground end
  if background then style.bg = background end
end

local ttt = require("ttt")
local fs = require("ttt.fs")
local settings = require("ttt.settings")
local json = require("ttt.json")
local term = require("ttt.terminal")

local function drop_empty_groups(value)
  for key, child in pairs(value) do
    if type(child) == "table" then
      drop_empty_groups(child)
      if next(child) == nil then value[key] = nil end
    end
  end
end

function M.convert(palette)
  if type(palette) ~= "table" then return nil, "palette must be a table" end
  local ansi = {}
  local missing = 0
  for index = 0, 15 do
    ansi[index] = palette.ansi and palette.ansi[index] or FALLBACK_ANSI[index + 1]
    if not (palette.ansi and palette.ansi[index]) then missing = missing + 1 end
  end

  local foreground = palette.fg
  local background = palette.bg
  if not foreground or not background then
    return nil, "terminal palette does not define a foreground and background color"
  end
  if not rgb(foreground) or not rgb(background) then
    return nil, "terminal palette requires a valid foreground and background color"
  end

  foreground = safe(foreground, background, foreground)
  local accent = safe(palette.accent or ansi[4] or ansi[6] or foreground, background, foreground)
  local muted = safe(ansi[8] or mix(foreground, background, 0.5), background, foreground)
  local selection = palette.selection
  if not rgb(selection) then selection = mix(background, accent, selection_blend) end
  local surface = mix(background, foreground, surface_blend)
  local selection_text = safe(foreground, selection, foreground)
  local accent_text = readable_on(accent)

  local red = safe(ansi[1], background, foreground)
  local green = safe(ansi[2], background, foreground)
  local yellow = safe(ansi[3], background, foreground)
  local magenta = safe(ansi[5], background, foreground)
  local cyan = safe(ansi[6], background, foreground)
  local bright_red = safe(ansi[9], background, foreground)
  local bright_green = safe(ansi[10], background, foreground)
  local bright_yellow = safe(ansi[11], background, foreground)
  local bright_blue = safe(ansi[12], background, foreground)
  local bright_magenta = safe(ansi[13], background, foreground)
  local bright_cyan = safe(ansi[14], background, foreground)
  local bright_white = safe(ansi[15], background, foreground)

  local theme = copy(DEFAULT)

  set(theme.default, foreground, background)
  set(theme.muted, muted)
  set(theme.success, green)
  set(theme.danger, red)
  set(theme.warning, yellow)
  set(theme.conflict, magenta)
  set(theme.statusBar, safe(foreground, surface, foreground), surface)
  set(theme.tabs.active, accent)
  set(theme.tabs.inactive, muted)
  set(theme.tabs.selected, selection_text, selection)
  set(theme.sidebar.header, accent)
  set(theme.sidebar.item, foreground)
  set(theme.sidebar.selected, selection_text, selection)
  set(theme.dialog.selected, selection_text, selection)
  set(theme.dialog.muted, muted)
  set(theme.menu.item, foreground)
  set(theme.menu.active, selection_text, selection)
  set(theme.border, muted)
  set(theme.borderActive, accent)
  set(theme.editor.lineNumber, muted)
  set(theme.editor.activeLine, nil, surface)
  set(theme.editor.selection, nil, selection)
  local search_match = mix(background, yellow, search_match_blend)
  set(theme.editor.searchMatch, safe(foreground, search_match, background), search_match)
  set(theme.editor.searchActive, accent_text, accent)
  set(theme.editor.bracketMatch, nil, selection)
  set(theme.diff.added, nil, mix(background, green, diff_blend))
  set(theme.diff.deleted, nil, mix(background, red, diff_blend))
  set(theme.diff.modified, nil, mix(background, yellow, diff_blend))
  set(theme.diff.gutterAdded, green)
  set(theme.diff.gutterDeleted, red)
  set(theme.diff.gutterModified, yellow)
  set(theme.diff.gutterBookmark, accent)
  set(theme.scrollbar, muted, surface)

  local roles = {
    comment = muted,
    string = green,
    keyword = magenta,
    number = yellow,
    operator = foreground,
    ["function"] = accent,
    type = cyan,
    builtin = cyan,
    variable = bright_blue,
    punctuation = foreground,
    tag = red,
    attribute = yellow,
    regexp = bright_red,
    heading = bright_magenta,
    quote = ansi[8] or muted,
    inserted = bright_green,
    deleted = bright_red,
    invalid = bright_red,
    control = bright_magenta,
    storage = bright_yellow,
    constant = bright_blue,
    escape = bright_cyan,
    parameter = bright_white,
    property = bright_cyan,
    self = bright_magenta,
    namespace = cyan,
    decorator = bright_red,
    link = bright_blue,
    code = bright_green,
    interpolation = bright_cyan,
    selector = bright_yellow,
    readonlyVariable = bright_magenta,
  }
  for role, value in pairs(roles) do
    theme.syntax[role].fg = safe(value, background, foreground)
  end
  theme.syntax.comment.italic = true
  theme.syntax.heading.bold = true
  theme.syntax.quote.italic = true
  theme.syntax.invalid.bold = true

  theme.terminal.foreground = foreground
  theme.terminal.background = background
  theme.terminal.selection = selection
  local terminal_names = {
    "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
    "brightBlack", "brightRed", "brightGreen", "brightYellow", "brightBlue",
    "brightMagenta", "brightCyan", "brightWhite",
  }
  for index, name in ipairs(terminal_names) do
    theme.terminal[name] = ansi[index - 1]
  end

  drop_empty_groups(theme)
  return theme, { missing = missing }
end

local last_input_key
local last_output
local last_error
local last_info
local reload_pending = false
local palette_polls = 0
local poll, report

local function schedule_palette_poll(failure_reason)
  if palette_polls >= max_palette_polls then
    report(failure_reason or "terminal palette capture did not finish; reload the plugin to try again")
    return
  end
  palette_polls = palette_polls + 1
  ttt.set_timeout(poll_timeout_ms, poll)
end

report = function(message)
  if message == last_error then return end
  ttt.log("warn", "Terminal theme: " .. message)
  if ttt.notify then ttt.notify("Terminal theme: " .. message, "warn") end
  last_error = message
end

local function report_info(message)
  if message == last_info then return end
  ttt.log("info", "Terminal theme: " .. message)
  last_info = message
end

local function reload_active_theme()
  if not reload_pending then return end
  local ok, selected = pcall(settings.get, "theme")
  if not ok or selected ~= theme_name then
    reload_pending = false
    return
  end
  local executed, done = pcall(ttt.exec_command, "settings.reload")
  if executed and done then
    reload_pending = false
    last_error = nil
  else
    report("snapshot updated, but settings.reload command was unavailable")
    schedule_palette_poll("settings.reload failed; snapshot is saved, reload the plugin to retry")
  end
end

local function palette_key(palette)
  local parts = { palette.fg or "", palette.bg or "", palette.selection or "", palette.cursor or "" }
  for index = 0, 15 do parts[#parts + 1] = palette.ansi and palette.ansi[index] or "" end
  return table.concat(parts, "|")
end

poll = function()
  local ok, result = pcall(term.palette)
  if not ok or type(result) ~= "table" then
    report("terminal palette API is unavailable; this TTT build may predate ttt.terminal.palette()")
		schedule_palette_poll("terminal palette API is unavailable; this TTT build may predate ttt.terminal.palette()")
    return
  end
  local status = result.status
  if status == "pending" then schedule_palette_poll(); return end
  if status == "unavailable" then
    report("the client terminal did not provide a palette; keeping the last snapshot")
    schedule_palette_poll()
    return
  end
  if (status ~= "complete" and status ~= "partial") or type(result.colors) ~= "table" then
    report("terminal palette returned an invalid result; keeping the last snapshot")
		schedule_palette_poll("terminal palette returned an invalid result; keeping the last snapshot")
    return
  end
  local colors = result.colors
  local palette = { fg = normalize_color(colors["10"]), bg = normalize_color(colors["11"]), ansi = {} }
  if not palette.fg or not palette.bg then
    report("terminal palette has no valid foreground/background; keeping the last snapshot")
		schedule_palette_poll("terminal palette has no valid foreground/background; keeping the last snapshot")
    return
  end
  for index = 0, 15 do palette.ansi[index] = normalize_color(colors["4;" .. index]) end
  palette.selection = normalize_color(colors["17"])
  palette.cursor = normalize_color(colors["12"])
  last_error = nil

  local input_key = palette_key(palette)
  if input_key == last_input_key then
    reload_active_theme()
    return
  end

  local theme, build_info = M.convert(palette)
  if not theme then
    report(build_info)
    return
  end

  local output, encode_error = json.encode(theme)
  if not output then
    report("could not encode generated theme: " .. tostring(encode_error))
    return
  end
  if output == last_output then
    last_input_key = input_key
    last_error = nil
    reload_active_theme()
    return
  end

  local written, write_error = fs.write(output_path, output)
  if not written then
    report("could not write " .. output_path .. "; create the themes directory (mkdir -p ~/.config/ttt/themes) or check its permissions: " .. tostring(write_error))
		schedule_palette_poll("could not write " .. output_path .. "; create the themes directory (mkdir -p ~/.config/ttt/themes) or check its permissions: " .. tostring(write_error))
    return
  end

  last_input_key = input_key
  last_output = output
  last_error = nil
  if type(build_info) == "table" and build_info.missing > 0 then
    report_info("the terminal defines " .. build_info.missing .. " of the 16 ANSI colors; using TTT defaults for the rest")
  end
  reload_pending = true
  reload_active_theme()
end

local function capture_and_poll()
  local ok, requested = pcall(term.request_palette)
  if not ok or requested == false then
    report("could not request terminal palette capture; this TTT build may predate ttt.terminal.request_palette()")
    return
  end
  poll()
end

ttt.register({})
ttt.set_timeout(100, capture_and_poll)

return M
