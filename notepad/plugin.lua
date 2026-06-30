local ttt = require("ttt")
local fs = require("ttt.fs")
local sys = require("ttt.system")

-- Minimal JSON encoder/decoder for our notes data format.
-- Notes are stored as: [{"id":"1","text":"...","timestamp":"..."},...]

local function json_escape(s)
	s = s:gsub("\\", "\\\\")
	s = s:gsub('"', '\\"')
	s = s:gsub("\n", "\\n")
	s = s:gsub("\r", "\\r")
	s = s:gsub("\t", "\\t")
	return s
end

local function json_encode(notes_list)
	local parts = {}
	for _, note in ipairs(notes_list) do
		local entry = string.format(
			'{"id":"%s","text":"%s","timestamp":"%s"}',
			json_escape(note.id),
			json_escape(note.text),
			json_escape(note.timestamp)
		)
		table.insert(parts, entry)
	end
	return "[\n  " .. table.concat(parts, ",\n  ") .. "\n]"
end

local function json_decode(str)
	local result = {}
	if not str or #str == 0 then
		return result
	end

	local i = 1
	local len = #str

	local function skip_ws()
		while i <= len and str:sub(i, i):match("%s") do
			i = i + 1
		end
	end

	local function parse_string()
		if i > len or str:sub(i, i) ~= '"' then
			return nil
		end
		i = i + 1
		local parts = {}
		while i <= len do
			local c = str:sub(i, i)
			if c == "\\" then
				i = i + 1
				local nc = str:sub(i, i)
				if nc == "n" then
					table.insert(parts, "\n")
				elseif nc == "r" then
					table.insert(parts, "\r")
				elseif nc == "t" then
					table.insert(parts, "\t")
				elseif nc == '"' then
					table.insert(parts, '"')
				elseif nc == "\\" then
					table.insert(parts, "\\")
				else
					table.insert(parts, nc)
				end
				i = i + 1
			elseif c == '"' then
				i = i + 1
				return table.concat(parts)
			else
				table.insert(parts, c)
				i = i + 1
			end
		end
		return nil
	end

	skip_ws()
	if i > len or str:sub(i, i) ~= "[" then
		return result
	end
	i = i + 1

	while i <= len do
		skip_ws()
		if str:sub(i, i) == "]" then
			break
		end
		if str:sub(i, i) == "," then
			i = i + 1
		end
		skip_ws()

		if str:sub(i, i) == "{" then
			i = i + 1
			local note = {}
			while i <= len do
				skip_ws()
				if str:sub(i, i) == "}" then
					i = i + 1
					break
				end
				if str:sub(i, i) == "," then
					i = i + 1
				end
				skip_ws()
				local key = parse_string()
				skip_ws()
				if i <= len and str:sub(i, i) == ":" then
					i = i + 1
				end
				skip_ws()
				local value = parse_string()
				if key and value then
					note[key] = value
				end
			end
			if note.text then
				table.insert(result, note)
			end
		else
			break
		end
	end

	return result
end

-- State
local notes = {}
local next_id = 1
local notes_file = nil
local last_panel = nil

-- Get current timestamp via the date command
local function get_timestamp()
	local result = sys.exec("date", { "+%Y-%m-%d %H:%M:%S" })
	if result.exit_code == 0 then
		return result.stdout:match("^(.-)%s*$") or ""
	end
	return "unknown"
end

-- Load notes from the JSON file
local function load_notes()
	if not notes_file then
		return
	end
	if not fs.exists(notes_file) then
		notes = {}
		return
	end
	local content, err = fs.read(notes_file)
	if not content then
		ttt.log("error", "Failed to read notes: " .. (err or "unknown error"))
		return
	end
	notes = json_decode(content)
	-- Set next_id higher than any existing id
	for _, note in ipairs(notes) do
		local num = tonumber(note.id) or 0
		if num >= next_id then
			next_id = num + 1
		end
	end
end

-- Save notes to the JSON file
local function save_notes()
	if not notes_file then
		return
	end
	local content = json_encode(notes)
	local err = fs.write(notes_file, content)
	if err then
		ttt.log("error", "Failed to save notes: " .. err)
	end
end

-- Add a new note (inserted at the beginning for newest-first order)
local function add_note(text, panel)
	local timestamp = get_timestamp()
	table.insert(notes, 1, {
		id = tostring(next_id),
		text = text,
		timestamp = timestamp,
	})
	next_id = next_id + 1
	save_notes()
	ttt.log("Note added")
	if panel then
		panel:redraw()
	end
end

-- Delete a note by its id
local function delete_note(id, panel)
	for i, note in ipairs(notes) do
		if note.id == id then
			table.remove(notes, i)
			break
		end
	end
	save_notes()
	ttt.log("Note deleted")
	if panel then
		panel:redraw()
	end
end

-- Clear all notes (with confirmation)
local function clear_all()
	if #notes == 0 then
		ttt.log("warn", "No notes to clear")
		return
	end
	ttt.confirm("Clear all " .. #notes .. " notes?", function()
		notes = {}
		save_notes()
		ttt.log("All notes cleared")
		if last_panel then
			last_panel:redraw()
		end
	end)
end

-- Build list items from notes for the list widget
local function note_items()
	local items = {}
	for _, note in ipairs(notes) do
		local ts = note.timestamp or ""
		local short = ts:match("^(%d+-%d+-%d+)") or ts
		table.insert(items, {
			id = note.id,
			label = short .. "  " .. note.text,
		})
	end
	return items
end

local function init()
	if notes_file then
		return
	end
	local result = sys.exec("pwd", {})
	local root = "."
	if result.exit_code == 0 then
		root = result.stdout:match("^(.-)%s*$") or "."
	end
	notes_file = root .. "/.ttt-notepad.json"
	load_notes()
	ttt.log("Notepad loaded (" .. #notes .. " notes)")
end

-- Register the plugin
ttt.register({
	bottom = {
		title = "Notepad",
		render = function(panel)
			last_panel = panel
			init()

			panel:hstack({
				height = 1,
				render = function(h)
					h:input({
						placeholder = "Type a note and press Enter...",
						prefix = "> ",
						clear_on_submit = true,
						on_submit = function(text)
							if #text > 0 then
								add_note(text, panel)
							end
						end,
					})
					h:label({ text = tostring(#notes) .. " notes", style = "muted", width = 10 })
				end,
			})

			panel:divider()

			if #notes == 0 then
				panel:label({ text = "No notes yet. Type above and press Enter.", style = "muted", padding_left = 1 })
			else
				panel:list({
					items = note_items(),
					on_command = function(command, node)
						if command == "delete" then
							ttt.confirm("Delete this note?", function()
								delete_note(node.id, panel)
							end)
						end
					end,
					node_menu = {
						{ label = "Delete", command = "delete" },
					},
				})
			end
		end,
	},

	commands = {
		{
			id = "notepad.clearAll",
			title = "Notepad: Clear All Notes",
			handler = clear_all,
		},
	},
})
