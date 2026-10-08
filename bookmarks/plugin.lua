local ttt = require("ttt")
local editor = require("ttt.editor")
local bookmarks = require("ttt.bookmarks")
local events = require("ttt.events")
local storage = require("ttt.storage")

local ICON = "◆"
local STYLE = "bookmark"

local marks = {}
local nodes = {}
local last_panel = nil

local function redraw()
	if last_panel then
		last_panel:redraw()
	end
end

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function sorted_lines(path)
	local lines = {}
	for line in pairs(marks[path] or {}) do
		table.insert(lines, line)
	end
	table.sort(lines)
	return lines
end

local function save(path)
	local lines = sorted_lines(path)
	if #lines == 0 then
		marks[path] = nil
		storage.remove(path)
		return
	end
	local items = {}
	for _, line in ipairs(lines) do
		table.insert(items, { line = line, text = marks[path][line] })
	end
	storage.set(path, items)
end

local function load()
	for _, path in ipairs(storage.keys()) do
		local items = storage.get(path)
		if type(items) == "table" then
			marks[path] = {}
			for _, item in ipairs(items) do
				marks[path][item.line] = item.text or ""
			end
		end
	end
end

local function apply()
	local path = editor.file_path()
	if path == "" then
		return
	end
	local items = {}
	for _, line in ipairs(sorted_lines(path)) do
		table.insert(items, { line = line, icon = ICON, style = STYLE })
	end
	bookmarks.set_all(items)
end

local function add(path, line)
	marks[path] = marks[path] or {}
	marks[path][line] = trim(editor.get_line(line))
	bookmarks.set(line, ICON, STYLE)
	save(path)
	redraw()
end

local function remove(path, line)
	if not (marks[path] and marks[path][line]) then
		return
	end
	marks[path][line] = nil
	if path == editor.file_path() then
		bookmarks.remove(line)
	end
	save(path)
	redraw()
end

local function remove_file(path)
	marks[path] = nil
	storage.remove(path)
	if path == editor.file_path() then
		bookmarks.clear()
	end
	redraw()
end

local function toggle(path, line)
	if path == "" then
		return
	end
	if marks[path] and marks[path][line] then
		remove(path, line)
	else
		add(path, line)
	end
end

local function toggle_at_cursor()
	toggle(editor.file_path(), editor.cursor().line)
end

local function remove_all()
	if next(marks) == nil then
		return
	end
	ttt.confirm("Remove all bookmarks?", function()
		for path in pairs(marks) do
			storage.remove(path)
		end
		marks = {}
		bookmarks.clear()
		redraw()
	end)
end

local function refresh_text(path)
	if not marks[path] or path ~= editor.file_path() then
		return
	end
	local count = editor.line_count()
	for line in pairs(marks[path]) do
		if line > count then
			marks[path][line] = nil
		else
			marks[path][line] = trim(editor.get_line(line))
		end
	end
	save(path)
	redraw()
end

local function split_path(path)
	local dir, name = path:match("^(.*)/([^/]+)$")
	if not dir then
		return "", path
	end
	local short = dir:match("([^/]+/[^/]+)$") or dir:match("([^/]+)$") or dir
	return short, name
end

local function build_items()
	nodes = {}
	local paths = {}
	for path in pairs(marks) do
		table.insert(paths, path)
	end
	table.sort(paths)

	local items = {}
	for _, path in ipairs(paths) do
		local dir, name = split_path(path)
		local children = {}
		for _, line in ipairs(sorted_lines(path)) do
			local id = path .. "#" .. line
			nodes[id] = { path = path, line = line }
			table.insert(children, {
				id = id,
				label = line .. "  " .. marks[path][line],
				icon = ICON,
				actions = { { icon = "✕", command = "remove" } },
			})
		end
		nodes[path] = { path = path }
		table.insert(items, {
			id = path,
			label = name,
			badge = dir,
			expanded = true,
			children = children,
			actions = { { icon = "✕", command = "remove" } },
		})
	end
	return items
end

events.on("gutter.click", function(path, line)
	toggle(path, line)
end)

events.on("tab.change", function()
	apply()
end)

events.on("file.save", function(path)
	refresh_text(path)
end)

editor.register_context_menu(function(line)
	local path = editor.file_path()
	if path == "" then
		return {}
	end
	local label = (marks[path] and marks[path][line]) and "Remove Bookmark" or "Add Bookmark"
	return {
		{
			label = label,
			on_select = function()
				toggle(path, line)
			end,
		},
	}
end)

load()
ttt.set_timeout(0, apply)

ttt.register({
	sidebar = {
		title = "Bookmarks",
		actions = {
			{ label = "Remove All Bookmarks", command = "bookmarks.sidebarAction.removeAll" },
		},
		on_action = function(command)
			if command == "bookmarks.sidebarAction.removeAll" then
				remove_all()
			end
		end,
		render = function(panel)
			last_panel = panel
			local items = build_items()
			if #items == 0 then
				panel:label({ text = "No bookmarks", padding_left = 1 })
				panel:label({ text = "Click left of a line number", style = "muted", padding_left = 1 })
				panel:label({ text = "or right-click a line", style = "muted", padding_left = 1 })
				return
			end
			panel:tree({
				items = items,
				on_command = function(command, node)
					local n = nodes[node.id]
					if not n then
						return
					end
					if command == "open" or command == "activate" then
						ttt.open_file(n.path, n.line)
					elseif command == "remove" then
						if n.line then
							remove(n.path, n.line)
						else
							remove_file(n.path)
						end
					end
				end,
				node_menu = {
					{ label = "Open", command = "open" },
					{ label = "Remove", command = "remove" },
				},
			})
		end,
	},
	commands = {
		{ id = "bookmarks.toggle", title = "Bookmarks: Toggle Bookmark", handler = toggle_at_cursor },
		{ id = "bookmarks.removeAll", title = "Bookmarks: Remove All Bookmarks", handler = remove_all },
	},
})
