local ttt = require("ttt")
local sys = require("ttt.system")

local processes = {}
local filter_text = ""
local loaded = false

-- Each entry: { pid = number, name = string, port = number }

local function parse_linux()
  local result = sys.exec("ss", {"-tlnp"})
  if result.exit_code ~= 0 then
    return {}
  end
  local out = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    local addr = line:match("LISTEN%s+%d+%s+%d+%s+(%S+)")
    local port = addr and addr:match(":(%d+)$")
    local name = line:match('%(%("([^"]+)"')
    local pid = line:match("pid=(%d+)")
    if port and name and pid then
      out[#out + 1] = { pid = tonumber(pid), name = name, port = tonumber(port) }
    end
  end
  return out
end

local function parse_darwin()
  -- -F pcn: machine-readable fields, one per line: p<pid> c<command> n<name>
  local result = sys.exec("lsof", {"-iTCP", "-sTCP:LISTEN", "-P", "-n", "-F", "pcn"})
  if result.exit_code ~= 0 then
    return {}
  end
  local out = {}
  local pid, name
  for line in result.stdout:gmatch("[^\r\n]+") do
    local tag, val = line:sub(1, 1), line:sub(2)
    if tag == "p" then
      pid = val
    elseif tag == "c" then
      name = val
    elseif tag == "n" then
      local port = val:match(":(%d+)$")
      if port and pid and name then
        out[#out + 1] = { pid = tonumber(pid), name = name, port = tonumber(port) }
      end
    end
  end
  return out
end

local function parse_windows()
  local pid_to_name = {}
  local tasks = sys.exec("tasklist", {"/fo", "csv", "/nh"})
  if tasks.exit_code == 0 then
    for line in tasks.stdout:gmatch("[^\r\n]+") do
      local name, pid = line:match('^"([^"]+)","([^"]+)"')
      if name and pid then
        pid_to_name[pid] = name
      end
    end
  end

  local result = sys.exec("netstat", {"-ano", "-p", "tcp"})
  if result.exit_code ~= 0 then
    return {}
  end
  local out = {}
  for line in result.stdout:gmatch("[^\r\n]+") do
    local _, port, state, pid = line:match("^%s*TCP%s+(%S+):(%d+)%s+%S+%s+(%a+)%s+(%d+)%s*$")
    if state == "LISTENING" and pid then
      out[#out + 1] = {
        pid = tonumber(pid),
        name = pid_to_name[pid] or ("pid " .. pid),
        port = tonumber(port),
      }
    end
  end
  return out
end

local function refresh()
  local platform = ttt.platform()
  if platform == "windows" then
    processes = parse_windows()
  elseif platform == "darwin" then
    processes = parse_darwin()
  else
    processes = parse_linux()
  end
end

local function filtered_processes()
  if filter_text == "" then
    return processes
  end
  local needle = filter_text:lower()
  local out = {}
  for _, proc in ipairs(processes) do
    if proc.name:lower():find(needle, 1, true) or tostring(proc.port):find(needle, 1, true) then
      out[#out + 1] = proc
    end
  end
  return out
end

local function list_items()
  local items = {}
  for _, proc in ipairs(filtered_processes()) do
    items[#items + 1] = {
      id = tostring(proc.pid),
      label = proc.name,
      badge = ":" .. proc.port,
      actions = {
        { icon = "✕", command = "kill" },
      },
    }
  end
  return items
end

local function kill(pid)
  if ttt.platform() == "windows" then
    sys.exec("taskkill", {"/PID", tostring(pid), "/F"})
  else
    sys.exec("kill", {"-9", tostring(pid)})
  end
  refresh()
end

ttt.register({
  sidebar = {
    title = "Ports",
    actions = {
      { label = "Refresh", command = "refresh" },
    },
    on_action = function(command)
      if command == "refresh" then
        refresh()
      end
    end,
    render = function(panel)
      if not loaded then
        loaded = true
        refresh()
      end
      panel:vstack({
        render = function(p)
          p:input({
            placeholder = "Filter by name or port...",
            on_change = function(text)
              filter_text = text
              panel:redraw()
            end,
          })
          p:divider()
          p:list({
            items = list_items(),
            key_commands = { k = "kill" },
            on_command = function(command, node)
              if command == "kill" then
                kill(tonumber(node.id))
                panel:redraw()
              end
            end,
          })
        end,
      })
    end,
  },
  commands = {
    { id = "port-finder.refresh", title = "Ports: Refresh", handler = refresh },
  },
})
