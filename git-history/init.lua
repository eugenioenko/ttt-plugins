local ttt = require("ttt")
local editor = require("ttt.editor")
local events = require("ttt.events")
local sys = require("ttt.system")

local commits = {}
local current_file = ""
local loading = false
local error_msg = nil
local panel_ref = nil

local function split_lines(text)
  local lines = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    table.insert(lines, line)
  end
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

local function parse_commits(stdout)
  local result = {}
  local lines = split_lines(stdout)
  for _, line in ipairs(lines) do
    local hash, date, author, subject = line:match("^(%S+)\t(%S+)\t([^\t]+)\t(.+)$")
    if hash then
      table.insert(result, {
        hash = hash,
        date = date,
        author = author,
        subject = subject,
      })
    end
  end
  return result
end

local function fetch_history(path)
  if not path or path == "" then
    commits = {}
    current_file = ""
    error_msg = nil
    return
  end

  current_file = path
  loading = true
  error_msg = nil

  sys.exec_async("git", {
    "log", "--format=%H\t%as\t%an\t%s", "--follow", "-n", "100", "--", path,
  }, function(result)
    loading = false
    if result.exit_code ~= 0 then
      if result.stderr:find("not a git repository") then
        error_msg = "Not a git repository"
      else
        error_msg = "No history"
      end
      commits = {}
    else
      if result.stdout == "" then
        commits = {}
        error_msg = "No commits for this file"
      else
        commits = parse_commits(result.stdout)
        error_msg = nil
      end
    end
    if panel_ref then
      panel_ref:redraw()
    end
  end)
end

local function get_file_at_parent(sha, path, callback)
  sys.exec_async("git", {"show", sha .. "^:" .. path}, function(result)
    if result.exit_code ~= 0 then
      callback({})
      return
    end
    callback(split_lines(result.stdout))
  end)
end

local function get_file_at_commit(sha, path, callback)
  sys.exec_async("git", {"show", sha .. ":" .. path}, function(result)
    if result.exit_code ~= 0 then
      ttt.notify("Could not retrieve file at " .. sha:sub(1, 7), "error")
      return
    end
    local lines = split_lines(result.stdout)
    callback(lines)
  end)
end

local function get_file_relative_path(abs_path)
  local result = sys.exec("git", {"rev-parse", "--show-toplevel"})
  if result.exit_code ~= 0 then
    return abs_path
  end
  local root = result.stdout:gsub("%s+$", "")
  if abs_path:sub(1, #root) == root then
    local rel = abs_path:sub(#root + 2)
    return rel
  end
  return abs_path
end

local function open_compact_diff(commit)
  local rel_path = get_file_relative_path(current_file)
  local title = commit.hash:sub(1, 7) .. " " .. commit.subject
  sys.exec_async("git", {"show", commit.hash, "--", rel_path}, function(result)
    if result.exit_code ~= 0 then return end
    ttt.open_diff(title, {}, {}, rel_path, false, result.stdout)
  end)
end

local function open_extended_diff(commit)
  local rel_path = get_file_relative_path(current_file)
  local title = commit.hash:sub(1, 7) .. " " .. commit.subject
  get_file_at_parent(commit.hash, rel_path, function(old_lines)
    get_file_at_commit(commit.hash, rel_path, function(new_lines)
      ttt.open_diff(title, old_lines, new_lines, rel_path, true)
    end)
  end)
end

local function compare_with_head(commit)
  local rel_path = get_file_relative_path(current_file)
  local title = commit.hash:sub(1, 7) .. " vs HEAD"
  get_file_at_commit(commit.hash, rel_path, function(old_lines)
    get_file_at_commit("HEAD", rel_path, function(head_lines)
      ttt.open_diff(title, old_lines, head_lines, rel_path)
    end)
  end)
end

local function view_file_at_commit(commit)
  local rel_path = get_file_relative_path(current_file)
  get_file_at_commit(commit.hash, rel_path, function(lines)
    local title = rel_path .. " @ " .. commit.hash:sub(1, 7)
    ttt.open_readonly(title, lines, rel_path)
  end)
end

local function build_items()
  local items = {}
  for _, c in ipairs(commits) do
    table.insert(items, {
      id = c.hash,
      label = c.date .. "  " .. c.subject,
    })
  end
  return items
end

local function on_tab_change()
  local path = editor.file_path()
  if not path or path == "" or path:sub(1, 1) ~= "/" then
    return
  end
  if path ~= current_file then
    fetch_history(path)
    if panel_ref then
      panel_ref:redraw()
    end
  end
end

events.on("tab.change", function()
  on_tab_change()
end)

ttt.register({
  sidebar = {
    title = "History",
    actions = {
      { label = "Refresh", command = "refresh" },
    },
    on_action = function(command)
      if command == "refresh" then
        local path = editor.file_path()
        fetch_history(path)
      end
    end,
    render = function(panel)
      panel_ref = panel

      if loading then
        panel:label({ text = "Loading...", style = "muted", padding_left = 1 })
        return
      end

      if error_msg then
        panel:label({ text = error_msg, style = "muted", padding_left = 1 })
        return
      end

      if #commits == 0 then
        local path = editor.file_path()
        if path and path ~= "" and path:sub(1, 1) == "/" and path ~= current_file then
          fetch_history(path)
          panel:label({ text = "Loading...", style = "muted", padding_left = 1 })
          return
        end
        panel:label({ text = "No file open", style = "muted", padding_left = 1 })
        return
      end

      panel:list({
        items = build_items(),
        on_select = function(node)
          for _, c in ipairs(commits) do
            if c.hash == node.id then
              open_compact_diff(c)
              return
            end
          end
        end,
        on_command = function(command, node)
          for _, c in ipairs(commits) do
            if c.hash == node.id then
              if command == "compact_diff" then
                open_compact_diff(c)
              elseif command == "extended_diff" then
                open_extended_diff(c)
              elseif command == "compare_head" then
                compare_with_head(c)
              elseif command == "view_file" then
                view_file_at_commit(c)
              elseif command == "copy_hash" then
                ttt.clipboard_write(c.hash)
                ttt.notify("Copied " .. c.hash:sub(1, 7))
              end
              return
            end
          end
        end,
        node_menu = {
          { label = "Compact diff", command = "compact_diff" },
          { label = "Extended diff", command = "extended_diff" },
          { separator = true },
          { label = "Compare with HEAD", command = "compare_head" },
          { label = "View file at commit", command = "view_file" },
          { separator = true },
          { label = "Copy commit hash", command = "copy_hash" },
        },
      })
    end,
  },
})
