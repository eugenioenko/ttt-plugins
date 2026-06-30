local ttt = require("ttt")
local editor = require("ttt.editor")
local json = require("ttt.json")

local function type_icon(val)
	if type(val) == "table" then
		local is_array = false
		local count = 0
		for k, _ in pairs(val) do
			count = count + 1
			if type(k) == "number" then
				is_array = true
			end
		end
		if count == 0 then
			return is_array and "[]" or "{}"
		end
		return is_array and "[" .. count .. "]" or "{" .. count .. "}"
	elseif type(val) == "string" then
		return "str"
	elseif type(val) == "number" then
		return "num"
	elseif type(val) == "boolean" then
		return "bool"
	elseif val == nil then
		return "null"
	end
	return ""
end

local function truncate(s, max)
	if #s <= max then
		return s
	end
	return s:sub(1, max - 1) .. "…"
end

local function value_label(val)
	if type(val) == "string" then
		return '"' .. truncate(val, 40) .. '"'
	elseif type(val) == "number" then
		return tostring(val)
	elseif type(val) == "boolean" then
		return tostring(val)
	elseif val == nil then
		return "null"
	end
	return ""
end

local function build_tree(val, key, path)
	path = path or ""
	local node_id = path == "" and "root" or path

	if type(val) == "table" then
		local children = {}
		local is_array = true
		local max_key = 0
		for k, _ in pairs(val) do
			if type(k) ~= "number" then
				is_array = false
				break
			end
			if k > max_key then
				max_key = k
			end
		end
		if is_array and max_key > 0 then
			for i = 1, max_key do
				local child_path = path .. "[" .. i .. "]"
				table.insert(children, build_tree(val[i], tostring(i), child_path))
			end
		else
			is_array = false
			local keys = {}
			for k, _ in pairs(val) do
				table.insert(keys, k)
			end
			table.sort(keys, function(a, b)
				return tostring(a) < tostring(b)
			end)
			for _, k in ipairs(keys) do
				local child_path = path .. "." .. tostring(k)
				table.insert(children, build_tree(val[k], tostring(k), child_path))
			end
		end

		local label = key or (is_array and "Array" or "Object")
		local badge = type_icon(val)

		return {
			id = node_id,
			label = label,
			badge = badge,
			expandable = #children > 0,
			expanded = path == "",
			children = children,
		}
	else
		local label = key and (key .. ": " .. value_label(val)) or value_label(val)
		return {
			id = node_id,
			label = label,
			badge = type_icon(val),
			expandable = false,
		}
	end
end

local function show_preview()
	local text = editor.buffer_text()
	if not text or text == "" then
		ttt.log("warn", "Buffer is empty")
		return
	end

	local ok, data = pcall(json.decode, text)
	if not ok or data == nil then
		ttt.log("error", "Invalid JSON: " .. tostring(data))
		return
	end

	local name = editor.file_name() or "untitled"
	local tree_items = { build_tree(data, name) }

	ttt.open_tab({
		title = "Preview: " .. name,
		render = function(p)
			p:box({
				padding_left = 1,
				render = function(bp)
					bp:tree({
						items = tree_items,
						indent = 2,
					})
				end,
			})
		end,
	})
end

ttt.register({
	commands = {
		{
			id = "json.preview",
			title = "Preview: JSON",
			handler = show_preview,
		},
	},
})
