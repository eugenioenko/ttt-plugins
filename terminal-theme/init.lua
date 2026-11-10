local M = {}

local theme_name = "terminal"
local output_path = "{config}/themes/terminal.json"
local poll_interval_ms = 2000
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

local NAMED_COLORS = {
  black = "#000000",
  maroon = "#800000",
  green = "#008000",
  olive = "#808000",
  navy = "#000080",
  purple = "#800080",
  teal = "#008080",
  silver = "#c0c0c0",
  grey = "#808080",
  gray = "#808080",
  red = "#ff0000",
  lime = "#00ff00",
  yellow = "#ffff00",
  blue = "#0000ff",
  fuchsia = "#ff00ff",
  magenta = "#ff00ff",
  aqua = "#00ffff",
  cyan = "#00ffff",
  white = "#ffffff",
}

local ANSI_NAMES = {
  "black", "maroon", "green", "olive", "navy", "purple", "teal", "silver",
}

local BRIGHT_NAMES = {
  "grey", "red", "lime", "yellow", "blue", "fuchsia", "aqua", "white",
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

local function split_lines(source)
  local lines = {}
  for line in (source .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end
  return lines
end

local function strip_quotes(value)
  value = trim(value)
  local quote = value:sub(1, 1)
  if (quote == '"' or quote == "'") and value:sub(-1) == quote then
    local body = value:sub(2, -2)
    body = body:gsub("\\(.)", function(char)
      local replacements = {
        ['"'] = '"', ["'"] = "'", ["\\"] = "\\",
        n = "\n", t = "\t", r = "\r", b = "\b", f = "\f",
      }
      return replacements[char] or char
    end)
    return body
  end
  return value
end

local function strip_inline_comment(line)
  local quote, escaped = nil, false
  for index = 1, #line do
    local char = line:sub(index, index)
    if quote then
      if char == "\\" and not escaped then
        escaped = true
      elseif char == quote and not escaped then
        quote = nil
      else
        escaped = false
      end
    elseif char == '"' or char == "'" then
      quote = char
      escaped = false
    elseif char == "#" and (index == 1 or line:sub(index - 1, index - 1):match("%s")) then
      -- A comment marker is followed by whitespace or end of line; `#rrggbb`
      -- is a color value and must survive.
      local after = line:sub(index + 1, index + 1)
      if after == "" or after:match("%s") then return line:sub(1, index - 1) end
    end
  end
  return line
end

local function strip_toml_comment(line)
  local quote, escaped = nil, false
  for index = 1, #line do
    local char = line:sub(index, index)
    if quote then
      if char == "\\" and not escaped then
        escaped = true
      elseif char == quote and not escaped then
        quote = nil
      else
        escaped = false
      end
    elseif char == '"' or char == "'" then
      quote = char
      escaped = false
    elseif char == "#" then
      return line:sub(1, index - 1)
    end
  end
  return line
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
  elseif #value == 4 and value:match("^%x+$") then
    value = value:sub(1, 3)
  end
  if #value == 3 and value:match("^%x+$") then
    value = value:sub(1, 1):rep(2) .. value:sub(2, 2):rep(2) .. value:sub(3, 3):rep(2)
  end
  if #value == 6 and value:match("^%x+$") then
    return "#" .. value
  end
  return nil
end

local function color(value, context)
  if type(value) ~= "string" then return nil end
  value = strip_quotes(trim(value)):lower()
  if value == "" or value == "none" then return nil end
  if value == "cellforeground" or value == "foreground" or value == "fg" then
    return context and context.fg or nil
  end
  if value == "cellbackground" or value == "background" or value == "bg" then
    return context and context.bg or nil
  end
  return parse_hex(value) or NAMED_COLORS[value]
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

local function dirname(path)
  return path:match("^(.*)/[^/]*$") or "."
end

local function is_absolute(path)
  return path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil
end

local function join_path(base, path)
  path = trim(path)
  if path == "" then return nil end
  if path:sub(1, 1) == "?" then path = path:sub(2) end
  if is_absolute(path) or path:sub(1, 2) == "~/" then return path end
  return base .. "/" .. path
end

local function expand_path_vars(path, env)
  path = path:gsub("%${([%w_]+)}", function(name) return env(name) end)
  return path:gsub("%$([%w_]+)", function(name) return env(name) end)
end

local function merge_palette(base, overlay)
  if type(base) ~= "table" then base = {} end
  if type(overlay) ~= "table" then return base end
  if overlay.fg then base.fg = overlay.fg end
  if overlay.bg then base.bg = overlay.bg end
  if overlay.selection then base.selection = overlay.selection end
  if overlay.cursor then base.cursor = overlay.cursor end
  base.ansi = base.ansi or {}
  if overlay.ansi then
    for index = 0, 15 do
      if overlay.ansi[index] then base.ansi[index] = overlay.ansi[index] end
    end
  end
  if overlay.incomplete then base.incomplete = true end
  return base
end

local function parse_int(value)
  value = trim(value)
  if value:match("^0[xX]%x+$") then return tonumber(value:sub(3), 16) end
  if value:match("^0[oO][0-7]+$") then return tonumber(value:sub(3), 8) end
  if value:match("^0[bB][01]+$") then
    local result = 0
    for digit in value:sub(3):gmatch("%d") do result = result * 2 + tonumber(digit) end
    return result
  end
  return tonumber(value)
end

function M.parse_foot_config(source)
  local parsed = { sections = { main = {} }, includes = {} }
  local current = "main"
  for _, raw in ipairs(split_lines(source)) do
    local line = trim(raw)
    if line ~= "" and line:sub(1, 1) ~= ";" and line:sub(1, 1) ~= "#" then
      line = trim(strip_inline_comment(line))
      local section = line:match("^%[([^%]]+)%]$")
      if section then
        current = trim(section):lower()
        parsed.sections[current] = parsed.sections[current] or {}
      else
        local key, value = line:match("^([^=]+)=(.*)$")
        if key then
          key = trim(key):lower()
          value = strip_quotes(trim(value))
          if key == "include" then
            parsed.includes[#parsed.includes + 1] = value
          else
            parsed.sections[current] = parsed.sections[current] or {}
            parsed.sections[current][key] = value
          end
        end
      end
    end
  end
  return parsed
end

function M.parse_kitty_config(source)
  local parsed = { values = {}, includes = {} }
  for _, raw in ipairs(split_lines(source)) do
    local line = trim(raw)
    if line ~= "" and line:sub(1, 1) ~= "#" then
      local key, value = line:match("^([%w_%-]+)%s*[= ]%s*(.*)$")
      if key then
        key = key:lower()
        value = strip_quotes(trim(value))
        if key == "include" then
          parsed.includes[#parsed.includes + 1] = value
        else
          parsed.values[key] = value
        end
      end
    end
  end
  return parsed
end

function M.parse_ghostty_config(source)
  local parsed = { values = {}, palette = {}, includes = {} }
  for _, raw in ipairs(split_lines(source)) do
    local line = trim(raw)
    if line ~= "" and line:sub(1, 1) ~= "#" then
      local key, value = line:match("^([%w_%-]+)%s*=%s*(.*)$")
      if key then
        key = key:lower()
        value = strip_quotes(trim(value))
        if key == "config-file" then
          parsed.includes[#parsed.includes + 1] = value
        elseif key == "palette" then
          local index, entry = value:match("^([^=]+)=(.+)$")
          local number = index and parse_int(index)
          if number then parsed.palette[number] = entry end
        else
          parsed.values[key] = value
        end
      end
    end
  end
  return parsed
end

local function toml_lines(source)
  local result = {}
  local pending = ""
  for _, raw in ipairs(split_lines(source)) do
    local line = trim(strip_toml_comment(raw))
    if pending ~= "" then line = pending .. " " .. line end
    pending = ""
    if line ~= "" then
      if line:find("%[") and not line:find("%]") then
        pending = line
      else
        result[#result + 1] = line
      end
    end
  end
  if pending ~= "" then result[#result + 1] = pending end
  return result
end

local function parse_toml_value(raw)
  raw = trim(raw)
  local quote = raw:sub(1, 1)
  if (quote == '"' or quote == "'") and raw:sub(-1) == quote then
    return strip_quotes(raw)
  end
  return raw
end

function M.parse_alacritty_config(source)
  local parsed = { values = {}, imports = {} }
  local section = nil
  for _, line in ipairs(toml_lines(source)) do
    local header, rest = line:match("^%[%[?(.-)%]%]?(.*)$")
    if header then
      section = trim(header)
      line = trim(rest)
    end
    if line ~= "" then
      local key, raw = line:match("^([^=]+)=(.*)$")
      if key then
        key = trim(key):gsub("%s*%.%s*", ".")
        local full = section and (section .. "." .. key) or key
        if full == "general.import" or full == "import" then
          for quoted in raw:gmatch("([\"'][^\"']*[\"'])") do
            parsed.imports[#parsed.imports + 1] = strip_quotes(quoted)
          end
        else
          parsed.values[full] = parse_toml_value(raw)
        end
      end
    end
  end
  return parsed
end

local function strip_lua_comments(source)
  local output = {}
  local index = 1
  local quote = nil
  while index <= #source do
    local char = source:sub(index, index)
    local next_char = source:sub(index + 1, index + 1)
    if quote then
      output[#output + 1] = char
      if char == "\\" then
        output[#output + 1] = next_char
        index = index + 2
      elseif char == quote then
        quote = nil
        index = index + 1
      else
        index = index + 1
      end
    elseif char == '"' or char == "'" then
      quote = char
      output[#output + 1] = char
      index = index + 1
    elseif char == "-" and next_char == "-" then
      if source:sub(index, index + 3) == "--[[" then
        local close = source:find("]]", index + 4, true)
        if not close then break end
        index = close + 2
      else
        local newline = source:find("\n", index, true)
        if not newline then break end
        index = newline
      end
    else
      output[#output + 1] = char
      index = index + 1
    end
  end
  return table.concat(output)
end

local function skip_space(source, index)
  while index <= #source and source:sub(index, index):match("%s") do
    index = index + 1
  end
  return index
end

local function parse_lua_string(source, index)
  local quote = source:sub(index, index)
  local output = {}
  index = index + 1
  while index <= #source do
    local char = source:sub(index, index)
    if char == "\\" then
      local escaped = source:sub(index + 1, index + 1)
      local replacements = {
        n = "\n", t = "\t", r = "\r", ["\\"] = "\\",
        ["'"] = "'", ['"'] = '"',
      }
      output[#output + 1] = replacements[escaped] or escaped
      index = index + 2
    elseif char == quote then
      return table.concat(output), index + 1
    else
      output[#output + 1] = char
      index = index + 1
    end
  end
  return table.concat(output), index
end

local function extract_table(source, start)
  local depth = 0
  local quote = nil
  local index = start
  while index <= #source do
    local char = source:sub(index, index)
    if quote then
      if char == "\\" then
        index = index + 2
      elseif char == quote then
        quote = nil
        index = index + 1
      else
        index = index + 1
      end
    elseif char == '"' or char == "'" then
      quote = char
      index = index + 1
    elseif char == "{" then
      depth = depth + 1
      index = index + 1
    elseif char == "}" then
      depth = depth - 1
      if depth == 0 then return source:sub(start, index), index end
      index = index + 1
    else
      index = index + 1
    end
  end
  return nil, #source
end

local function parse_lua_table(body)
  local values = {}
  local index = 1
  if body:sub(1, 1) == "{" then index = 2 end
  local next_index = 1
  while index <= #body do
    index = skip_space(body, index)
    local char = body:sub(index, index)
    if char == "" or char == "}" then
      break
    elseif char == "," then
      index = index + 1
    else
      local key
      local identifier = body:sub(index):match("^([%a_][%w_]*)%s*=")
      if identifier then
        key = identifier
        index = index + #identifier
        index = skip_space(body, index)
        if body:sub(index, index) ~= "=" then break end
        index = index + 1
      elseif char == "[" then
        local close = body:find("]", index, true)
        if not close then break end
        local raw_key = trim(body:sub(index + 1, close - 1))
        key = raw_key:match("^%d+$") and tonumber(raw_key) or raw_key
        index = close + 1
        index = skip_space(body, index)
        if body:sub(index, index) ~= "=" then break end
        index = index + 1
      end
      index = skip_space(body, index)
      local value
      char = body:sub(index, index)
      if char == '"' or char == "'" then
        value, index = parse_lua_string(body, index)
      elseif char == "{" then
        local stop
        value, stop = extract_table(body, index)
        index = stop + 1
      else
        local stop = body:find("[,}]", index)
        local last = (stop or (#body + 1)) - 1
        value = trim(body:sub(index, last))
        index = stop or (#body + 1)
      end
      if key ~= nil then
        values[key] = value
      else
        values[next_index] = value
        next_index = next_index + 1
      end
    end
  end
  return values
end

local function wezterm_color_tables(source)
  local tables = {}
  local index = 1
  while true do
    local position = source:find("colors", index, true)
    if not position then break end
    local before = position > 1 and source:sub(position - 1, position - 1) or ""
    local after = source:sub(position + 6, position + 6)
    if not before:match("[%w_]") and not after:match("[%w_]") then
      local cursor = skip_space(source, position + 6)
      if source:sub(cursor, cursor) == "=" then
        cursor = skip_space(source, cursor + 1)
        if source:sub(cursor, cursor) == "{" then
          local body, stop = extract_table(source, cursor)
          if body then tables[#tables + 1] = body end
          index = (stop or #source) + 1
        else
          index = cursor
        end
      else
        index = position + 6
      end
    else
      index = position + 6
    end
  end
  return tables
end

local function resolve_wezterm_color(value, context)
  if type(value) == "table" then
    if value.Color then return color(value.Color, context) end
    if value.AnsiColor then return color(value.AnsiColor, context) end
    return nil
  end
  if type(value) ~= "string" then return nil end
  value = trim(value)
  if value:sub(1, 1) == "{" then
    local nested = parse_lua_table(value)
    if nested.Color then return color(nested.Color, context) end
    if nested.AnsiColor then return color(nested.AnsiColor, context) end
    return nil
  end
  return color(value, context)
end

local function palette_from_wezterm(tables)
  local palette = {}
  local function apply(table)
    if table.foreground then palette.fg = resolve_wezterm_color(table.foreground, palette) end
    if table.background then palette.bg = resolve_wezterm_color(table.background, palette) end
    if table.selection_bg then palette.selection = resolve_wezterm_color(table.selection_bg, palette) end
    if table.cursor_bg then palette.cursor = resolve_wezterm_color(table.cursor_bg, palette) end
    if table.cursor_border then palette.cursor = palette.cursor or resolve_wezterm_color(table.cursor_border, palette) end
    if table.ansi then
      local ansi = parse_lua_table(table.ansi)
      for offset = 1, 8 do
        local value = ansi[offset] or ansi[ANSI_NAMES[offset]]
        if value then palette.ansi = palette.ansi or {}; palette.ansi[offset - 1] = resolve_wezterm_color(value, palette) end
      end
    end
    if table.brights then
      local brights = parse_lua_table(table.brights)
      for offset = 1, 8 do
        local value = brights[offset] or brights[BRIGHT_NAMES[offset]]
        if value then palette.ansi = palette.ansi or {}; palette.ansi[offset + 7] = resolve_wezterm_color(value, palette) end
      end
    end
  end
  for _, table in ipairs(tables) do apply(table) end
  return palette
end

function M.parse_wezterm_config(source)
  local cleaned = strip_lua_comments(source)
  local tables = wezterm_color_tables(cleaned)
  local parsed = { tables = {}, values = {}, color_scheme = nil }
  for _, body in ipairs(tables) do
    parsed.tables[#parsed.tables + 1] = parse_lua_table(body)
  end
  local scheme = cleaned:match("color_scheme%s*=%s*['\"]([^'\"]+)['\"]")
  parsed.color_scheme = scheme
  return parsed
end

local function palette_from_foot(parsed)
  local palette = { ansi = {} }
  local section = {}
  -- Explicit [colors] wins, then dark, then light; each section only fills keys
  -- the higher-precedence one left undefined.
  for _, name in ipairs({ "colors", "colors-dark", "colors-light" }) do
    local values = parsed.sections[name]
    if values then
      for key, value in pairs(values) do
        if section[key] == nil then section[key] = value end
      end
    end
  end
  palette.fg = color(section.foreground)
  palette.bg = color(section.background)
  for index = 0, 7 do palette.ansi[index] = color(section["regular" .. index]) end
  for index = 0, 7 do palette.ansi[index + 8] = color(section["bright" .. index]) end
  palette.selection = color(section["selection-background"])
  local cursor = section.cursor and section.cursor:match("^%s*(%S+)")
  palette.cursor = color(cursor)
  return palette
end

local function palette_from_kitty(parsed)
  local palette = { ansi = {} }
  palette.fg = color(parsed.values.foreground)
  palette.bg = color(parsed.values.background)
  for index = 0, 15 do palette.ansi[index] = color(parsed.values["color" .. index]) end
  palette.selection = color(parsed.values.selection_background)
  palette.cursor = color(parsed.values.cursor)
  return palette
end

local function palette_from_ghostty(parsed)
  local palette = { ansi = {} }
  palette.fg = color(parsed.values.foreground)
  palette.bg = color(parsed.values.background)
  for index = 0, 15 do palette.ansi[index] = color(parsed.palette[index]) end
  palette.selection = color(parsed.values["selection-background"])
  palette.cursor = color(parsed.values["cursor-color"])
  return palette
end

local function palette_from_alacritty(parsed)
  local palette = { ansi = {} }
  palette.fg = color(parsed.values["colors.primary.foreground"])
  palette.bg = color(parsed.values["colors.primary.background"])
  local normal = { "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white" }
  for index, name in ipairs(normal) do
    palette.ansi[index - 1] = color(parsed.values["colors.normal." .. name])
  end
  for index, name in ipairs(normal) do
    palette.ansi[index + 7] = color(parsed.values["colors.bright." .. name])
  end
  palette.selection = color(parsed.values["colors.selection.background"], palette)
  palette.cursor = color(parsed.values["colors.cursor.cursor"], palette)
  return palette
end

local function read_config(path, state)
  if state.visited[path] then return nil, "cycle detected at " .. path end
  if state.files >= 32 then return nil, "too many included files" end
  state.visited[path] = true
  state.files = state.files + 1
  local content, err = state.reader(path)
  if not content then return nil, err or ("could not read " .. path) end
  return content
end

local function load_foot(path, state)
  local content, err = read_config(path, state)
  if not content then return nil, err end
  local parsed = M.parse_foot_config(content)
  local result = {}
  for _, include in ipairs(parsed.includes) do
    local include_path = join_path(dirname(path), expand_path_vars(include, state.env))
    if include_path then
      local sub = load_foot(include_path, state)
      if sub then result = merge_palette(result, sub) end
    end
  end
  return merge_palette(result, palette_from_foot(parsed))
end

local function load_kitty(path, state)
  local content, err = read_config(path, state)
  if not content then return nil, err end
  local parsed = M.parse_kitty_config(content)
  local result = {}
  for _, include in ipairs(parsed.includes) do
    local include_path = join_path(dirname(path), expand_path_vars(include, state.env))
    if include_path then
      local sub = load_kitty(include_path, state)
      if sub then result = merge_palette(result, sub) end
    end
  end
  return merge_palette(result, palette_from_kitty(parsed))
end

local function ghostty_theme_name(value)
  value = strip_quotes(trim(value))
  local dark = value:match("dark%s*:%s*([^,]+)")
  if dark then return trim(dark) end
  local light = value:match("light%s*:%s*([^,]+)")
  if light then return trim(light) end
  return value
end

local function find_ghostty_theme(name, state)
  name = ghostty_theme_name(name)
  if name == "" then return nil end
  local candidates
  if is_absolute(name) or name:sub(1, 2) == "~/" then
    candidates = { name }
  else
    candidates = {
      "~/.config/ghostty/themes/" .. name,
      "~/Library/Application Support/com.mitchellh.ghostty/themes/" .. name,
      "/usr/share/ghostty/themes/" .. name,
      "/Applications/Ghostty.app/Contents/Resources/ghostty/themes/" .. name,
    }
  end
  for _, candidate in ipairs(candidates) do
    local content = state.reader(candidate)
    if content then return candidate end
  end
  return nil
end

local function load_ghostty(path, state)
  local content, err = read_config(path, state)
  if not content then return nil, err end
  local parsed = M.parse_ghostty_config(content)
  local result = {}
  if parsed.values.theme then
    local theme_path = find_ghostty_theme(parsed.values.theme, state)
    if theme_path then
      local sub = load_ghostty(theme_path, state)
      if sub then result = merge_palette(result, sub) end
    else
      state.warnings[#state.warnings + 1] = "Ghostty theme not found: " .. parsed.values.theme
    end
  end
  result = merge_palette(result, palette_from_ghostty(parsed))
  for _, include in ipairs(parsed.includes) do
    local include_path = join_path(dirname(path), expand_path_vars(include, state.env))
    if include_path then
      local sub = load_ghostty(include_path, state)
      if sub then result = merge_palette(result, sub) end
    end
  end
  return result
end

local function load_alacritty(path, state)
  local content, err = read_config(path, state)
  if not content then return nil, err end
  local parsed = M.parse_alacritty_config(content)
  local result = {}
  for _, import in ipairs(parsed.imports) do
    import = expand_path_vars(import, state.env)
    if not import:find("[*?%[]") then
      local import_path = join_path(dirname(path), import)
      if import_path then
        local sub = load_alacritty(import_path, state)
        if sub then result = merge_palette(result, sub) end
      end
    end
  end
  return merge_palette(result, palette_from_alacritty(parsed))
end

local json = require("ttt.json")

local LOADERS = {
  foot = load_foot,
  kitty = load_kitty,
  ghostty = load_ghostty,
  alacritty = load_alacritty,
  wezterm = function(path, state)
    local content, err = read_config(path, state)
    if not content then return nil, err end
    local parsed = M.parse_wezterm_config(content)
    local palette = palette_from_wezterm(parsed.tables)
    if not palette.fg and not palette.bg and parsed.color_scheme then
      return nil, "WezTerm color_scheme names are not resolved; define config.colors or set TTT_TERMINAL_THEME"
    end
    return palette
  end,
  env = function(path, state)
    local raw = state.env("TTT_TERMINAL_PALETTE")
    if raw == "" then return nil, "TTT_TERMINAL_PALETTE is empty" end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= "table" then
      return nil, "TTT_TERMINAL_PALETTE must be a JSON object"
    end
    local palette = {}
    palette.fg = decoded.fg or decoded.foreground
    palette.bg = decoded.bg or decoded.background
    if type(decoded.ansi) == "table" then
      palette.ansi = {}
      for index, value in ipairs(decoded.ansi) do
        palette.ansi[index - 1] = value
      end
    end
    palette.selection = decoded.selection
    palette.cursor = decoded.cursor
    if not palette.fg or not palette.bg then
      return nil, "TTT_TERMINAL_PALETTE must include fg/foreground and bg/background"
    end
    return palette
  end,
}

function M.load_palette(source_id, path, reader, env)
  local loader = LOADERS[source_id]
  if not loader then return nil, "unknown terminal source: " .. tostring(source_id) end
  local state = {
    reader = reader,
    env = env or function() return "" end,
    visited = {},
    files = 0,
    warnings = {},
  }
  local palette, err = loader(path, state)
  if not palette then return nil, err end
  return palette, state.warnings
end

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

local SOURCES = {
  {
    id = "env",
    label = "Environment",
    paths = {},
  },
  {
    id = "foot",
    label = "Foot",
    paths = { "~/.config/foot/foot.ini" },
  },
  {
    id = "ghostty",
    label = "Ghostty",
    paths = {
      "~/.config/ghostty/config",
      "~/.config/ghostty/config.ghostty",
      "~/Library/Application Support/com.mitchellh.ghostty/config",
    },
  },
  {
    id = "kitty",
    label = "Kitty",
    paths = {
      "~/.config/kitty/kitty.conf",
      "~/Library/Application Support/kitty/kitty.conf",
    },
  },
  {
    id = "alacritty",
    label = "Alacritty",
    paths = {
      "~/.config/alacritty/alacritty.toml",
      "~/Library/Application Support/alacritty/alacritty.toml",
    },
  },
  {
    id = "wezterm",
    label = "WezTerm",
    paths = {
      "~/.config/wezterm/wezterm.lua",
      "~/.wezterm.lua",
      "~/Library/Application Support/wezterm/wezterm.lua",
    },
  },
}

local function source_by_id(id)
  for _, source in ipairs(SOURCES) do
    if source.id == id or source.label:lower() == id then return source end
  end
  return nil
end

local function source_path(source, exists)
  for _, path in ipairs(source.paths) do
    local ok, found = pcall(exists, path)
    if ok and found then return path end
  end
  return nil
end

local function detect_from_env(env)
  local function value(name) return env(name) or "" end
  local term = value("TERM"):lower()
  local program = value("TERM_PROGRAM"):lower()
  if program == "ghostty" or term:find("ghostty", 1, true) or value("GHOSTTY_RESOURCES_DIR") ~= "" or value("GHOSTTY_BIN_DIR") ~= "" then
    return "ghostty"
  end
  if value("KITTY_WINDOW_ID") ~= "" or value("KITTY_PID") ~= "" or program == "kitty" or term:find("kitty", 1, true) then
    return "kitty"
  end
  if program == "wezterm" or value("WEZTERM_PANE") ~= "" or value("WEZTERM_EXECUTABLE") ~= "" or term:find("wezterm", 1, true) then
    return "wezterm"
  end
  if program == "alacritty" or term:find("alacritty", 1, true) or value("ALACRITTY_SOCKET") ~= "" or value("ALACRITTY_LOG") ~= "" then
    return "alacritty"
  end
  if program == "foot" or term:find("foot", 1, true) then
    return "foot"
  end
  return nil
end

function M.detect(env, exists)
  local forced = env("TTT_TERMINAL_THEME") or ""
  if forced ~= "" and forced:lower() ~= "auto" then
    local source = source_by_id(forced:lower())
    if not source then
      return nil, nil, "unknown TTT_TERMINAL_THEME " .. forced .. "; use foot, ghostty, kitty, alacritty, wezterm, or env"
    end
    local path = source_path(source, exists)
    if not path and source.id ~= "env" then return nil, nil, source.label .. " config not found" end
    return source.id, path or "TTT_TERMINAL_PALETTE"
  end

  if (env("TTT_TERMINAL_PALETTE") or "") ~= "" then
    return "env", "TTT_TERMINAL_PALETTE"
  end

  local detected = detect_from_env(env)
  if detected then
    local source = source_by_id(detected)
    local path = source_path(source, exists)
    if path then return source.id, path end
    return nil, nil, source.label .. " config not found; check " .. source.paths[1] .. " or set TTT_TERMINAL_THEME"
  end

  local found = {}
  for _, source in ipairs(SOURCES) do
    local path = source_path(source, exists)
    if path then found[#found + 1] = { id = source.id, path = path, label = source.label } end
  end
  if #found == 0 then
    return nil, nil, "no supported terminal config found"
  end
  local first = found[1]
  local info
  if #found > 1 then
    local labels = {}
    for _, item in ipairs(found) do labels[#labels + 1] = item.label end
    info = "multiple terminal configs found (" .. table.concat(labels, ", ") .. "); using " .. first.label .. "; set TTT_TERMINAL_THEME to override"
  end
  return first.id, first.path, nil, info
end

local ttt = require("ttt")
local fs = require("ttt.fs")
local settings = require("ttt.settings")
local system = require("ttt.system")

local last_input_key
local last_output
local last_error
local last_info
local reload_pending = false

local function read_env(name)
  if not system or not system.env then return "" end
  local ok, value = pcall(system.env, name)
  if ok and type(value) == "string" then return value end
  return ""
end

local function file_exists(path)
  if fs.exists then return fs.exists(path) end
  local content = fs.read(path)
  return content ~= nil
end

local function report(message)
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
  end
end

local function palette_key(palette)
  local parts = { palette.fg or "", palette.bg or "", palette.selection or "", palette.cursor or "" }
  for index = 0, 15 do parts[#parts + 1] = palette.ansi and palette.ansi[index] or "" end
  return table.concat(parts, "|")
end

local function poll()
  local source_id, path, detect_error, info = M.detect(read_env, file_exists)
  if not source_id then
    report(detect_error)
    return
  end
  if info then report_info(info) end

  local palette, warnings = M.load_palette(source_id, path, fs.read, read_env)
  if not palette then
    report(warnings or ("could not read " .. path))
    return
  end
  last_error = nil
  if type(warnings) == "table" and warnings[1] then report_info(warnings[1]) end

  local input_key = source_id .. "|" .. path .. "|" .. palette_key(palette)
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

ttt.register({})
ttt.set_timeout(100, poll)
ttt.set_interval(poll_interval_ms, poll)

return M
