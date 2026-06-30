local ttt = require("ttt")
local sys = require("ttt.system")

-- State
local results = {} -- grouped results: { {file=..., items={...}}, ... }
local total_count = 0
local scanning = false
local initialized = false
local rg_missing = false
local last_panel = nil

-- Sanitize a string from ripgrep output for safe display.
-- Removes control characters, replaces tabs, strips carriage returns.
local function sanitize_text(s)
	if not s then
		return ""
	end
	-- Replace tabs with spaces
	s = s:gsub("\t", "  ")
	-- Remove carriage returns (from CRLF line endings)
	s = s:gsub("\r", "")
	-- Remove null bytes and other control characters (0x00-0x08, 0x0B-0x0C, 0x0E-0x1F, 0x7F)
	s = s:gsub("[%z\1-\8\11-\12\14-\31\127]", "")
	return s
end

-- Icons for comment types
local icons = {
	TODO = "●",
	FIXME = "▲",
	HACK = "◆",
	NOTE = "■",
}

-- Detect which comment type a matched line contains
local function detect_type(text)
	-- Check for the keyword nearest to the start of the match
	local best_type = "TODO"
	local best_pos = #text + 1
	for _, kw in ipairs({ "TODO", "FIXME", "HACK", "NOTE" }) do
		local pos = text:find(kw)
		if pos and pos < best_pos then
			best_pos = pos
			best_type = kw
		end
	end
	return best_type
end

-- Extract the comment text after the keyword (e.g. "TODO: fix this" -> "fix this")
local function extract_text(line, keyword)
	local pattern = keyword .. "[:%s]*(.*)"
	local match = line:match(pattern)
	if match then
		-- Trim trailing whitespace
		return match:gsub("%s+$", "")
	end
	return line:gsub("%s+$", "")
end

-- Parse ripgrep output and group by file
local function parse_results(stdout)
	local files = {} -- ordered list of file paths
	local file_map = {} -- file_path -> { items = { ... } }
	local count = 0

	for line in stdout:gmatch("[^\n]+") do
		-- ripgrep format: file:line:column:matched text
		local file, line_num, col, text = line:match("^(.-):(%-?%d+):(%-?%d+):(.*)$")
		if file and line_num and text then
			-- Sanitize raw text from ripgrep to remove control characters
			text = sanitize_text(text)
			local comment_type = detect_type(text)
			local display_text = extract_text(text, comment_type)

			-- Trim leading whitespace from display text
			display_text = display_text:gsub("^%s+", "")
			if display_text == "" then
				display_text = comment_type
			end

			-- Sanitize file path and strip leading ./
			file = sanitize_text(file)
			if file:sub(1, 2) == "./" then
				file = file:sub(3)
			end

			if not file_map[file] then
				file_map[file] = { items = {} }
				table.insert(files, file)
			end

			table.insert(file_map[file].items, {
				line = tonumber(line_num),
				col = tonumber(col),
				text = display_text,
				type = comment_type,
				file = file,
			})
			count = count + 1
		end
	end

	-- Build grouped results
	local grouped = {}
	for _, file_path in ipairs(files) do
		table.insert(grouped, {
			file = file_path,
			items = file_map[file_path].items,
		})
	end

	return grouped, count
end

-- Build tree items from grouped results
local function build_tree_items()
	local tree = {}

	for _, group in ipairs(results) do
		local children = {}
		for i, item in ipairs(group.items) do
			local icon = icons[item.type] or icons.TODO
			table.insert(children, {
				id = item.file .. ":" .. tostring(item.line),
				label = item.text,
				icon = icon,
				badge = ":" .. tostring(item.line),
			})
		end

		-- Use file path as the parent node
		local file_label = group.file
		table.insert(tree, {
			id = "file:" .. group.file,
			label = file_label,
			expandable = true,
			expanded = true,
			badge = tostring(#group.items),
			children = children,
		})
	end

	return tree
end

-- Run the scan
local function scan_workspace(panel)
	if scanning then
		return
	end
	scanning = true
	rg_missing = false
	ttt.log("Scanning workspace for TODOs...")

	sys.exec_async("rg", {
		"--no-heading",
		"--line-number",
		"--column",
		"-g",
		"!.git",
		"-g",
		"!node_modules",
		"-g",
		"!vendor",
		"-e",
		"(TODO|FIXME|HACK|NOTE)[:\\s]",
		".",
	}, function(result)
		scanning = false

		if result.exit_code == -1 then
			-- exec error: rg not found
			rg_missing = true
			results = {}
			total_count = 0
			ttt.log("warn", "ripgrep (rg) is not installed. Install it to use TODO scanning.")
		elseif result.exit_code == 0 then
			results, total_count = parse_results(result.stdout)
			ttt.log("Found " .. tostring(total_count) .. " TODOs in " .. tostring(#results) .. " files")
		elseif result.exit_code == 1 then
			-- rg returns 1 when no matches found
			results = {}
			total_count = 0
			ttt.log("No TODOs found in workspace")
		else
			results = {}
			total_count = 0
			ttt.log("warn", "Scan failed: " .. result.stderr)
		end

		if panel then
			panel:redraw()
		end
	end)
end

-- Navigate to a file and line (from tree node id "file:line")
local function navigate_to(node_id)
	local file, line = node_id:match("^(.+):(%d+)$")
	if file and line then
		ttt.open_file(file, tonumber(line))
	end
end

-- Command handler for palette
local function cmd_scan()
	scan_workspace(last_panel)
end

-- Registration
ttt.register({
	bottom = {
		title = "TODOs",

		render = function(panel)
			last_panel = panel

			-- Scan on first open
			if not initialized then
				initialized = true
				scan_workspace(panel)
			end

			-- Show scanning state
			if scanning then
				panel:label({ text = "Scanning...", style = "muted" })
				return
			end

			-- Handle rg not installed
			if rg_missing then
				panel:label({ text = "ripgrep (rg) is not installed", style = "danger", padding_left = 1 })
				panel:label({ text = "Install ripgrep to scan for TODOs:", style = "muted", padding_left = 1 })
				panel:label({ text = "  https://github.com/BurntSushi/ripgrep", style = "muted", padding_left = 1 })
				panel:label({ text = "", padding_left = 1 })
				panel:label({ text = "On Ubuntu/Debian: sudo apt install ripgrep", style = "muted", padding_left = 1 })
				panel:label({ text = "On macOS: brew install ripgrep", style = "muted", padding_left = 1 })
				panel:label({ text = "On Arch: sudo pacman -S ripgrep", style = "muted", padding_left = 1 })
				return
			end

			-- No results
			if total_count == 0 and not scanning then
				panel:label({ text = "No TODOs found", style = "muted", padding_left = 1 })
				panel:label({ text = "Press r to refresh", style = "muted", padding_left = 1 })
				return
			end

			-- Results tree
			panel:tree({
				items = build_tree_items(),
				indent = 2,
				on_select = function(node)
					-- Only navigate for leaf nodes (actual TODO items, not file groups)
					if node.id and not node.id:match("^file:") then
						navigate_to(node.id)
					end
				end,
			})
		end,

		on_event = function(event)
			if event.type == "key" then
				if event.key == "r" and event.mod == nil then
					scan_workspace(last_panel)
				end
			end
		end,
	},

	commands = {
		{ id = "todos.scan", title = "TODOs: Scan Workspace", handler = cmd_scan },
	},
})
