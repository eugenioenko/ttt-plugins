local ttt = require("ttt")
local net = require("ttt.net")

-- State
local history = {} -- array of query strings (most recent first, max 10)
local cache = {} -- query -> response body
local current_query = nil -- currently displayed query
local current_body = nil -- currently displayed body (or nil while loading)
local current_error = nil -- error message if fetch failed
local fetching = false -- true while a request is in flight
local last_panel = nil -- sidebar panel reference for redraw

-- Add a query to history (move to front if already present, cap at 10)
local function add_to_history(query)
	-- Remove if already in history
	for i = #history, 1, -1 do
		if history[i] == query then
			table.remove(history, i)
		end
	end
	-- Insert at front
	table.insert(history, 1, query)
	-- Cap at 10
	while #history > 10 do
		table.remove(history)
	end
end

-- Fetch a cheat sheet and display it in an editor tab
local function fetch_and_display(query)
	if not query or query == "" then
		return
	end

	current_query = query
	current_error = nil
	fetching = true

	add_to_history(query)

	-- Check cache first
	if cache[query] then
		current_body = cache[query]
		fetching = false
		ttt.open_tab({
			title = "cheat: " .. query,
			render = function(p)
				for line in current_body:gmatch("[^\n]*") do
					p:label(line)
				end
			end,
		})
		if last_panel then
			last_panel:redraw()
		end
		return
	end

	-- Show loading tab
	ttt.open_tab({
		title = "cheat: " .. query,
		render = function(p)
			p:label({ text = "Loading cheat sheet for: " .. query .. "...", style = "muted" })
		end,
	})
	if last_panel then
		last_panel:redraw()
	end

	-- Fetch from cheat.sh
	local url = "http://cheat.sh/" .. query .. "?T"
	ttt.log("Fetching cheat sheet: " .. url)

	net.get_async(url, function(resp)
		fetching = false

		if resp.error then
			current_error = "Network error: " .. resp.error
			current_body = nil
			ttt.log("error", current_error)
			ttt.open_tab({
				title = "cheat: " .. query,
				render = function(p)
					p:label({ text = "Error fetching cheat sheet", style = "danger" })
					p:label({ text = current_error, style = "danger" })
					p:label("")
					p:label({ text = "Query: " .. query, style = "muted" })
				end,
			})
		elseif resp.status ~= 200 then
			current_error = "HTTP " .. tostring(resp.status)
			current_body = nil
			ttt.log("error", "Cheat sheet fetch failed: " .. current_error)
			ttt.open_tab({
				title = "cheat: " .. query,
				render = function(p)
					p:label({ text = "Error fetching cheat sheet", style = "danger" })
					p:label({ text = "HTTP status: " .. tostring(resp.status), style = "danger" })
					if resp.status == 404 then
						p:label({ text = "Topic not found: " .. query, style = "warning" })
					end
					p:label("")
					p:label({ text = "Try a different query, e.g.: go/slice, python/list, bash/find", style = "muted" })
				end,
			})
		else
			current_body = resp.body
			current_error = nil
			cache[query] = resp.body
			ttt.log("Cheat sheet loaded: " .. query)

			-- Capture body for the render closure
			local body = resp.body
			ttt.open_tab({
				title = "cheat: " .. query,
				render = function(p)
					for line in body:gmatch("[^\n]*") do
						p:label(line)
					end
				end,
			})
		end

		if last_panel then
			last_panel:redraw()
		end
	end)
end

-- Build history list items for the sidebar
local function history_items()
	local items = {}
	for i, query in ipairs(history) do
		local has_cache = cache[query] ~= nil
		table.insert(items, {
			id = "history_" .. tostring(i),
			label = query,
			badge = has_cache and "cached" or "",
		})
	end
	return items
end

-- Command handler: prompt for topic via input in sidebar
local function cmd_search()
	-- Focus the sidebar panel so the user sees the input
	if last_panel then
		last_panel:redraw()
	end
end

-- Registration
ttt.register({
	sidebar = {
		title = "Cheat Sheet",
		render = function(panel)
			last_panel = panel

			-- Search input
			panel:input({
				placeholder = "e.g. go/slice, python/list, bash/find",
				prefix = "$ ",
				on_submit = function(text)
					fetch_and_display(text)
				end,
			})

			-- Status
			if fetching then
				panel:label({ text = "Fetching...", style = "muted", margin_top = 1 })
			end

			-- History section
			if #history > 0 then
				panel:label({ text = "Recent Lookups", style = "muted", margin_top = 1, padding_left = 1 })
				panel:list({
					items = history_items(),
					on_select = function(node)
						-- Extract the query from the label
						fetch_and_display(node.label)
					end,
				})
			else
				panel:label({ text = "No recent lookups", style = "muted", margin_top = 1 })
				panel:label({ text = "Type a query above and press Enter", style = "muted" })
				panel:label({ text = "Examples:", style = "muted", margin_top = 1 })
				panel:label({ text = "  go/slice", style = "muted" })
				panel:label({ text = "  python/list", style = "muted" })
				panel:label({ text = "  bash/find", style = "muted" })
				panel:label({ text = "  js/array/map", style = "muted" })
			end
		end,
	},

	commands = {
		{ id = "cheatsheet.search", title = "Cheat Sheet: Search", handler = cmd_search },
	},

	keybindings = {
		{ key = "ctrl+k h", command = "cheatsheet.search" },
	},
})
