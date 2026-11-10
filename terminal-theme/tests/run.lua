local root = (arg and arg[0] or "tests/run.lua"):match("^(.*)/tests/run%.lua$") or "."
local output_path = "{config}/themes/terminal.json"

local function eq(got, expected, label)
  assert(got == expected, (label or "value") .. ": got " .. tostring(got) .. ", want " .. tostring(expected))
end

local function encode(value)
  if type(value) == "string" then return string.format("%q", value) end
  if type(value) ~= "table" then return tostring(value) end
  local keys = {}
  for key in pairs(value) do keys[#keys + 1] = key end
  table.sort(keys)
  local entries = {}
  for _, key in ipairs(keys) do
    entries[#entries + 1] = string.format("%q:%s", key, encode(value[key]))
  end
  return "{" .. table.concat(entries, ",") .. "}"
end

local function fresh(options)
  options = options or {}
  for _, name in ipairs({ "ttt", "ttt.fs", "ttt.settings", "ttt.json", "ttt.terminal" }) do
    package.loaded[name] = nil
    package.preload[name] = nil
  end
  local mock = {
    result = options.result or { status = "pending", colors = {} },
    selected_theme = options.selected_theme or "terminal",
    writes = {}, commands = {}, logs = {}, notifications = {}, requests = 0,
    write_error = options.write_error,
    command_failures = options.command_failures or 0,
  }
  local ttt = {
    register = function() end,
    log = function(_, message) mock.logs[#mock.logs + 1] = message end,
    notify = function(message) mock.notifications[#mock.notifications + 1] = message end,
    exec_command = function(command)
      mock.commands[#mock.commands + 1] = command
      if mock.command_failures > 0 then mock.command_failures = mock.command_failures - 1; return false end
      return true
    end,
    set_timeout = function(_, callback) mock.startup = callback end,
    set_interval = function(_, callback) mock.poll = callback end,
  }
  local fs = { write = function(path, content)
    if mock.write_error then return nil, mock.write_error end
    mock.writes[#mock.writes + 1] = { path = path, content = content }
    mock.snapshot = content
    return true
  end }
  package.preload.ttt = function() return ttt end
  package.preload["ttt.fs"] = function() return fs end
  package.preload["ttt.settings"] = function() return { get = function() return mock.selected_theme end } end
  package.preload["ttt.json"] = function() return { encode = function(theme)
    mock.encoded_theme = theme
    return encode(theme)
  end } end
  package.preload["ttt.terminal"] = function() return {
    request_palette = function() mock.requests = mock.requests + 1; return true end,
    palette = function() return mock.result end,
  } end
  mock.plugin = dofile(root .. "/init.lua")
  mock.startup()
  return mock
end

local function palette(fg, bg)
  local colors = { ["10"] = fg or "#abcdef", ["11"] = bg or "#123456", ["12"] = "#eeeeee", ["17"] = "#334455" }
  for index = 0, 15 do colors["4;" .. index] = string.format("#%06x", 0x10203 + index * 0x10101) end
  return { status = "complete", colors = colors }
end

-- Non-final capture states must not write or erase an existing snapshot.
for _, status in ipairs({ "pending", "partial", "unavailable" }) do
  local mock = fresh({ result = { status = status, colors = {} } })
  eq(mock.requests, 1, status .. " requests capture once on load")
  eq(#mock.writes, 0, status .. " does not write")
  mock.result = palette()
  mock.poll()
  eq(mock.requests, 1, status .. " polling does not request another capture")
  eq(#mock.writes, 1, status .. " can later complete")
  local snapshot = mock.snapshot
  mock.result = { status = status, colors = {} }
  mock.poll()
  eq(mock.requests, 1, status .. " later polls do not recapture")
  eq(mock.snapshot, snapshot, status .. " preserves snapshot")
  eq(#mock.writes, 1, status .. " does not rewrite")
end

local complete = fresh({ result = palette() })
eq(#complete.writes, 1, "complete writes once")
eq(complete.writes[1].path, output_path, "snapshot path")
eq(complete.encoded_theme.default.fg, "#abcdef", "OSC 10 maps foreground")
eq(complete.encoded_theme.default.bg, "#123456", "OSC 11 maps background")
eq(complete.encoded_theme.terminal.black, string.format("#%06x", 0x10203), "OSC 4;0 maps ANSI black")
eq(complete.encoded_theme.terminal.brightWhite, string.format("#%06x", 0x10203 + 15 * 0x10101), "OSC 4;15 maps bright white")
eq(complete.commands[1], "settings.reload", "reload command")
complete.poll()
eq(#complete.writes, 1, "unchanged palette does not write")
eq(#complete.commands, 1, "unchanged palette does not reload again")
eq(complete.requests, 1, "unchanged snapshot does not request another capture")

local reloaded = fresh({ result = palette("#fedcba") })
eq(reloaded.requests, 1, "plugin reload requests a fresh capture")
eq(reloaded.encoded_theme.default.fg, "#fedcba", "reload captures changed terminal palette")

local foot_rgb = fresh({ result = { status = "complete", colors = {
  ["10"] = "rgb:ffff/aaaa/8888", ["11"] = "rgb:1234/2/0",
  ["4;0"] = "rgb:f/1/ffff", ["4;1"] = "rgb:ff/fff/ffff",
} } })
eq(foot_rgb.encoded_theme.default.fg, "#ffaa88", "Foot four-digit RGB scales to 8-bit")
eq(foot_rgb.encoded_theme.default.bg, "#122200", "Foot mixed-width RGB components scale independently")
eq(foot_rgb.encoded_theme.terminal.black, "#ff11ff", "one- and four-digit ANSI components normalize")
eq(foot_rgb.encoded_theme.terminal.red, "#ffffff", "one- and three-digit components normalize")

local partial = fresh({ result = { status = "partial", colors = {
  ["10"] = "rgb:ffff/8080/0000", ["11"] = "rgb:0000/0000/0000", ["4;0"] = "rgb:1111/2222/3333",
} } })
eq(#partial.writes, 1, "valid partial palette can be used")
eq(partial.encoded_theme.default.fg, "#ff8000", "partial foreground normalized")
eq(partial.encoded_theme.terminal.black, "#112233", "partial ANSI value retained")
eq(partial.encoded_theme.terminal.red, "#f44747", "missing partial ANSI value falls back")
local partial_snapshot = partial.snapshot
partial.result = { status = "partial", colors = { ["10"] = "rgb:ffff/ffff/ffff" } }
partial.poll()
eq(partial.snapshot, partial_snapshot, "partial palette without background preserves snapshot")

local malformed = fresh({ result = { status = "complete", colors = {
  ["10"] = "rgb:ffff/xyz/0000", ["11"] = "rgb:0000/0000/0000",
} } })
eq(#malformed.writes, 0, "malformed foreground rejected")

local gated = fresh({ result = palette(), selected_theme = "other" })
eq(#gated.writes, 1, "snapshot written when another theme selected")
eq(#gated.commands, 0, "reload gated to terminal theme")

local retry = fresh({ result = palette(), write_error = "read-only" })
eq(#retry.writes, 0, "failed write not recorded")
retry.write_error = nil
retry.poll()
eq(#retry.writes, 1, "write retried on next poll")

local reload_retry = fresh({ result = palette(), command_failures = 1 })
eq(#reload_retry.commands, 1, "first reload attempted")
reload_retry.poll()
eq(#reload_retry.writes, 1, "reload retry does not rewrite snapshot")
eq(#reload_retry.commands, 2, "failed reload retried")

local preserve = fresh({ result = palette() })
local original = preserve.snapshot
preserve.result = palette("invalid", "#123456")
preserve.poll()
eq(preserve.snapshot, original, "invalid complete palette preserves prior snapshot")
print("terminal theme palette tests passed")
