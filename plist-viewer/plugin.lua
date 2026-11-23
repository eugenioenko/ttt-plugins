-- plist-viewer — read-only viewer for binary property lists (bplist00),
-- the format macOS and iOS use for preferences and Info.plist files.
--
-- Interaction: the tree widget owns expansion state natively (click, Enter,
-- Space, Left/Right, h/l/j/k all toggle or move). Children are always
-- materialized so nodes stay expandable, and `expanded` is asserted only on
-- the FIRST build: the panel framework re-asserts item flags on every
-- re-render, so asserting them later would silently un-collapse nodes the
-- user collapsed. Keyboard focus arrives via ttt.focus_tab from the
-- file.open and tab.change events. Keys and values render as two left-aligned
-- columns with a rule between them: each label is truncated-or-padded to a
-- per-file column width minus the row's indent, so the value badge that
-- follows lands on one shared column at every nesting depth.

local ttt = require("ttt")
local fs = require("ttt.fs")
local text = require("ttt.text")
local events = require("ttt.events")

-- ── byte readers (1-based offsets; Lua strings are byte strings, NUL-safe) ──

local function be(s, i, n)
	local v = 0
	for j = i, i + n - 1 do v = v * 256 + s:byte(j) end
	return v
end

local SAFE = 2 ^ 53

-- Two's-complement integer of n bytes at i. Returns ("num", value) when exact
-- in a double, else ("hex", "±0x…") so display stays honest past 2^53.
local function read_int(s, i, n)
	if s:byte(i) < 0x80 then
		local first = i
		while first < i + n - 1 and s:byte(first) == 0 do first = first + 1 end
		local v = be(s, first, i + n - first)
		if v < SAFE then return "num", v end
		local hex = string.format("%02X", s:byte(first))
		for j = first + 1, i + n - 1 do hex = hex .. string.format("%02X", s:byte(j)) end
		return "hex", "0x" .. hex
	end
	local b = {}
	for j = 1, n do b[j] = 0xFF - s:byte(i + j - 1) end
	local carry = 1
	for j = n, 1, -1 do
		local v = b[j] + carry
		b[j] = v % 256
		carry = (v - b[j]) / 256
	end
	local first = 1
	while first < n and b[first] == 0 do first = first + 1 end
	local v = 0
	for j = first, n do v = v * 256 + b[j] end
	if v < SAFE then return "num", -v end
	local hex = string.format("%02X", b[first])
	for j = first + 1, n do hex = hex .. string.format("%02X", b[j]) end
	return "hex", "-0x" .. hex
end

local function read_f64(s, i)
	local b1, b2, b3, b4, b5, b6, b7, b8 = s:byte(i, i + 7)
	local sign = b1 >= 0x80 and -1 or 1
	local exp = (b1 % 0x80) * 16 + math.floor(b2 / 16)
	local mant = (b2 % 16) * 2 ^ 48 + b3 * 2 ^ 40 + b4 * 2 ^ 32 + b5 * 2 ^ 24 + b6 * 2 ^ 16 + b7 * 2 ^ 8 + b8
	if exp == 0 then
		if mant == 0 then return sign * 0 end
		return sign * mant * 2 ^ -1074
	end
	if exp == 0x7FF then return sign * (mant == 0 and math.huge or 0 / 0) end
	return sign * (1 + mant / 2 ^ 52) * 2 ^ (exp - 1023)
end

local function read_f32(s, i)
	local b1, b2, b3, b4 = s:byte(i, i + 3)
	local sign = b1 >= 0x80 and -1 or 1
	local exp = (b1 % 0x80) * 2 + math.floor(b2 / 0x80)
	local mant = (b2 % 0x80) * 65536 + b3 * 256 + b4
	if exp == 0 then
		if mant == 0 then return sign * 0 end
		return sign * mant * 2 ^ -149
	end
	if exp == 0xFF then return sign * (mant == 0 and math.huge or 0 / 0) end
	return sign * (1 + mant / 2 ^ 23) * 2 ^ (exp - 127)
end

local function utf8_encode(cp)
	if cp < 0x80 then return string.char(cp) end
	if cp < 0x800 then
		return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
	end
	if cp < 0x10000 then
		return string.char(0xE0 + math.floor(cp / 0x1000),
			0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
	end
	return string.char(0xF0 + math.floor(cp / 0x40000),
		0x80 + math.floor(cp / 0x1000) % 0x40,
		0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
end

-- n UTF-16BE code units starting at 1-based byte offset i (surrogate pairs
-- decode to one char but consume two units — the count is in units, not chars)
local function utf16be(s, i, n)
	local out, pos, used = {}, i, 0
	while used < n do
		local cp = s:byte(pos) * 256 + s:byte(pos + 1)
		pos = pos + 2
		used = used + 1
		if cp >= 0xD800 and cp <= 0xDBFF and used < n then
			local lo = s:byte(pos) * 256 + s:byte(pos + 1)
			if lo >= 0xDC00 and lo <= 0xDFFF then
				pos = pos + 2
				used = used + 1
				cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
			end
		end
		out[#out + 1] = utf8_encode(cp)
	end
	return table.concat(out)
end

-- plist dates: float64 seconds since 2001-01-01T00:00:00Z (epoch shift + civil-from-days)
local function fmt_date(secs)
	local unix = math.floor(secs + 0.5) + 978307200
	local days = math.floor(unix / 86400)
	local rem = unix - days * 86400
	local h = math.floor(rem / 3600)
	local mi = math.floor((rem - h * 3600) / 60)
	local se = rem - h * 3600 - mi * 60
	local z = days + 719468
	local era = math.floor(z / 146097)
	local doe = z - era * 146097
	local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
	local y = yoe + era * 400
	local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
	local mp = math.floor((5 * doy + 2) / 153)
	local d = doy - math.floor((153 * mp + 2) / 5) + 1
	local m = mp < 10 and mp + 3 or mp - 9
	y = y + (m <= 2 and 1 or 0)
	return string.format("%04d-%02d-%02d %02d:%02d:%02d UTC", y, m, d, h, mi, se)
end

-- ── bplist00 decoder → value nodes ──

local function decode(data)
	if data:sub(1, 8) ~= "bplist00" then return nil, "not a bplist00 file" end
	if #data < 40 then return nil, "file too short for header + trailer" end
	local tr = #data - 31
	local offsize = data:byte(tr + 6)
	local refsize = data:byte(tr + 7)
	local nobjects = be(data, tr + 8, 8)
	local top = be(data, tr + 16, 8)
	local table_off = be(data, tr + 24, 8)
	if offsize < 1 or refsize < 1 or nobjects < 1 or top >= nobjects then
		return nil, "bad trailer"
	end

	local obj_at, decode_obj

	obj_at = function(idx, depth)
		if idx >= nobjects then return nil, "object index out of range" end
		local o = be(data, table_off + idx * offsize + 1, offsize)
		return decode_obj(o + 1, depth)
	end

	decode_obj = function(off, depth)
		if depth > 64 then return nil, "nesting too deep" end
		local m = data:byte(off)
		local hi = math.floor(m / 16)
		local lo = m % 16
		local function count(cpos)
			if lo ~= 0xF then return lo, cpos end
			local cm = data:byte(cpos)
			if math.floor(cm / 16) ~= 0x1 then return nil, "expected int marker for count" end
			local n = 2 ^ (cm % 16)
			local kind, v = read_int(data, cpos + 1, n)
			if kind ~= "num" then return nil, "count too large" end
			return v, cpos + 1 + n
		end
		if m == 0x00 then return { kind = "null", text = "null" }
		elseif m == 0x08 then return { kind = "bool", text = "false" }
		elseif m == 0x09 then return { kind = "bool", text = "true" }
		elseif hi == 0x1 then
			local kind, v = read_int(data, off + 1, 2 ^ lo)
			return { kind = "int", text = kind == "num" and string.format("%.0f", v) or v }
		elseif hi == 0x2 then
			local v
			if lo == 2 then v = read_f32(data, off + 1)
			elseif lo == 3 then v = read_f64(data, off + 1)
			else return nil, "bad real size" end
			return { kind = "real", text = string.format("%.14g", v) }
		elseif m == 0x33 then
			return { kind = "date", text = fmt_date(read_f64(data, off + 1)) }
		elseif hi == 0x4 then
			local n, p = count(off + 1)
			if not n then return nil, p end
			local shown = {}
			for j = 0, math.min(n, 8) - 1 do shown[#shown + 1] = string.format("%02X", data:byte(p + j)) end
			return { kind = "data",
				text = n .. " B  " .. table.concat(shown, " ") .. (n > 8 and " …" or "") }
		elseif hi == 0x5 then
			local n, p = count(off + 1)
			if not n then return nil, p end
			return { kind = "str", text = data:sub(p, p + n - 1) }
		elseif hi == 0x6 then
			local n, p = count(off + 1)
			if not n then return nil, p end
			return { kind = "str", text = utf16be(data, p, n) }
		elseif hi == 0x8 then
			return { kind = "uid", text = "UID " .. string.format("%.0f", be(data, off + 1, lo + 1)) }
		elseif hi == 0xA or hi == 0xB or hi == 0xC then
			local n, p = count(off + 1)
			if not n then return nil, p end
			local items = {}
			for j = 0, n - 1 do
				local v, err = obj_at(be(data, p + j * refsize, refsize), depth + 1)
				if not v then return nil, err end
				items[#items + 1] = v
			end
			return { kind = "list", items = items, text = #items .. " items" }
		elseif hi == 0xD then
			local n, p = count(off + 1)
			if not n then return nil, p end
			local entries = {}
			for j = 0, n - 1 do
				local k, err = obj_at(be(data, p + j * refsize, refsize), depth + 1)
				if not k then return nil, err end
				local v, verr = obj_at(be(data, p + (n + j) * refsize, refsize), depth + 1)
				if not v then return nil, verr end
				entries[#entries + 1] = { key = k, val = v }
			end
			return { kind = "dict", entries = entries, text = #entries .. " keys" }
		end
		return nil, string.format("unknown marker 0x%02X at byte %d", m, off - 1)
	end

	local root, err = obj_at(top, 0)
	if not root then return nil, err end
	return root, nil, { objects = nobjects }
end

-- ── viewer state (one per open file path) ──

local viewers = {}

-- Nerd Font (nf-fa) type glyphs as Lua 5.1 decimal UTF-8 escapes.
local TYPE_ICONS = {
	dict = "\239\129\187", -- U+F07B folder
	list = "\239\128\186", -- U+F03A list
	str = "\239\132\142", -- U+F10E quote-right
	int = "\239\138\146", -- U+F292 hashtag
	real = "\239\135\172", -- U+F1EC calculator
	bool = "\239\128\140", -- U+F00C check
	date = "\239\129\179", -- U+F073 calendar
	data = "\239\135\128", -- U+F1C0 database
	uid = "\239\128\135", -- U+F007 user
	null = "\239\132\145", -- U+F111 circle
}

local function clean(text, max)
	local t = tostring(text):gsub("%c", "·")
	if #t > max then t = t:sub(1, max) .. "…" end
	return t
end

-- Key column width: widest key (display columns) plus a gap, capped. Values
-- start at a constant x for every depth because each label is padded to
-- colw - depth*indent columns.
local function key_col_width(root)
	local w = 10
	local function walk(v)
		if v.kind == "dict" then
			for _, e in ipairs(v.entries) do
				local k = text.width(e.key.text)
				if k > w then w = k end
				walk(e.val)
			end
		elseif v.kind == "list" then
			local idx = #tostring(#v.items) + 2
			if idx > w then w = idx end
			for _, c in ipairs(v.items) do walk(c) end
		end
	end
	walk(root)
	return math.min(40, w + 3)
end

-- Truncate-or-pad a key to exactly `avail` display columns so the badge
-- (the value) that follows it lands on the shared value column.
local function fit(label, avail)
	if avail < 1 then return label end
	local s = text.truncate(label, avail, "…")
	local w = text.width(s)
	if w < avail then s = s .. string.rep(" ", avail - w) end
	return s
end

-- Key plus the column rule (U+2502, same glyph as the panel border) at a
-- constant x: label still measures `avail`, so the value column holds.
local SEP = "\226\148\130"
local function keylabel(key, avail)
	if avail < 4 then return fit(key, avail) end
	return fit(key, avail - 1) .. SEP
end

-- Children are always materialized and the WIDGET owns expansion state: its
-- on-click/Enter toggle persists across re-renders because the panel framework
-- reconciles expansion by node ID. `expanded` is asserted only on the FIRST
-- build (initial defaults); re-asserting it on later builds would re-expand
-- nodes the user has collapsed.
local function build_items(viewer)
	local first = not viewer.built
	viewer.built = true
	local colw = viewer.colw
	local vcap = viewer.value_cap or 60
	local function node_item(pid, label, val, idx, muted, depth)
		local id = pid .. "/" .. idx .. ":" .. label
		local avail = colw - depth * 2
		if avail < 1 then avail = 1 end
		local icon = TYPE_ICONS[val.kind] or ""
		if val.kind == "dict" or val.kind == "list" then
			local children = {}
			local isdict = val.kind == "dict"
			local entries = isdict and val.entries or val.items
			for j, e in ipairs(entries) do
				if isdict then
					children[#children + 1] = node_item(id, clean(e.key.text, 40), e.val, j, false, depth + 1)
				else
					children[#children + 1] = node_item(id, "[" .. (j - 1) .. "]", e, j, true, depth + 1)
				end
			end
			local node = { id = id, label = keylabel(label, avail), badge = val.text,
				children = children }
			if first and depth < 1 then node.expanded = true end
			return node
		end
		local v = val.text
		if val.kind == "str" and v == "" then v = '""' end
		return { id = id, icon = icon, icon_style = "muted", label = keylabel(label, avail),
			badge = text.truncate(v, vcap, "…"), muted = muted }
	end

	local items = {}
	local root = viewer.root
	if root.kind == "dict" then
		for j, e in ipairs(root.entries) do
			items[#items + 1] = node_item("r", clean(e.key.text, 40), e.val, j, false, 0)
		end
	elseif root.kind == "list" then
		for j, v in ipairs(root.items) do
			items[#items + 1] = node_item("r", "[" .. (j - 1) .. "]", v, j, true, 0)
		end
	else
		items[#items + 1] = { id = "r/1:root", icon = TYPE_ICONS[root.kind] or "",
			icon_style = "muted", label = keylabel("root", colw), badge = clean(root.text, 72) }
	end
	return items
end

local function render_viewer(viewer, panel)
	viewer.panel = panel
	local w = panel:size()
	viewer.value_cap = math.max(20, (w or 120) - viewer.colw - 10)
	local shown = viewer.path
	if #shown > 48 then shown = "…" .. shown:sub(#shown - 45) end
	panel:label({ text = shown .. " · bplist00 · " .. viewer.stats.objects .. " objects",
		style = "muted" })
	panel:tree({
		items = build_items(viewer),
		indent = 2,
	})
end

-- ── file handler + focus wiring ──

ttt.register({
	file_handlers = {
		{
			id = "bplist",
			title = "PLIST Viewer",
			magic = "bplist00",
			extensions = { "plist" },
			open = function(path, tab)
				local ok, root, derr, stats = pcall(function()
					local data, err = fs.read(path)
					if not data then return nil, "fs.read: " .. tostring(err) end
					local r, e, st = decode(data)
					if not r then return nil, e end
					return r, nil, st
				end)
				local viewer
				if ok and root then
					viewer = { path = path, root = root, stats = stats,
						colw = key_col_width(root), built = false, panel = nil }
					viewers[path] = viewer
				end
				tab.render = function(panel)
					if viewer then
						render_viewer(viewer, panel)
					else
						panel:label({ text = "decode failed: " .. tostring(ok and derr or root), style = "danger" })
					end
				end
			end,
		},
	},
})

events.on("file.open", function(path)
	if viewers[path] then ttt.focus_tab(path) end
end)

events.on("tab.change", function(path)
	if viewers[path] then ttt.focus_tab(path) end
end)

events.on("file.close", function(path)
	viewers[path] = nil
end)
