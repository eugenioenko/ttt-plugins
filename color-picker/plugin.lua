local ttt = require("ttt")
local editor = require("ttt.editor")

-- Color palettes organized by category
local palettes = {
	{
		name = "Basic",
		colors = {
			{ name = "Black", hex = "#000000" },
			{ name = "White", hex = "#ffffff" },
			{ name = "Red", hex = "#ff0000" },
			{ name = "Green", hex = "#00ff00" },
			{ name = "Blue", hex = "#0000ff" },
			{ name = "Yellow", hex = "#ffff00" },
			{ name = "Cyan", hex = "#00ffff" },
			{ name = "Magenta", hex = "#ff00ff" },
		},
	},
	{
		name = "Grays",
		colors = {
			{ name = "White Smoke", hex = "#f5f5f5" },
			{ name = "Gainsboro", hex = "#dcdcdc" },
			{ name = "Silver", hex = "#c0c0c0" },
			{ name = "Dark Gray", hex = "#a9a9a9" },
			{ name = "Gray", hex = "#808080" },
			{ name = "Dim Gray", hex = "#696969" },
			{ name = "Charcoal", hex = "#36454f" },
			{ name = "Jet", hex = "#343434" },
		},
	},
	{
		name = "Reds & Oranges",
		colors = {
			{ name = "Light Coral", hex = "#f08080" },
			{ name = "Salmon", hex = "#fa8072" },
			{ name = "Coral", hex = "#ff7f50" },
			{ name = "Tomato", hex = "#ff6347" },
			{ name = "Orange Red", hex = "#ff4500" },
			{ name = "Crimson", hex = "#dc143c" },
			{ name = "Fire Brick", hex = "#b22222" },
			{ name = "Dark Red", hex = "#8b0000" },
			{ name = "Orange", hex = "#ffa500" },
			{ name = "Dark Orange", hex = "#ff8c00" },
		},
	},
	{
		name = "Yellows & Browns",
		colors = {
			{ name = "Gold", hex = "#ffd700" },
			{ name = "Khaki", hex = "#f0e68c" },
			{ name = "Peach Puff", hex = "#ffdab9" },
			{ name = "Moccasin", hex = "#ffe4b5" },
			{ name = "Sandy Brown", hex = "#f4a460" },
			{ name = "Chocolate", hex = "#d2691e" },
			{ name = "Saddle Brown", hex = "#8b4513" },
			{ name = "Sienna", hex = "#a0522d" },
		},
	},
	{
		name = "Greens",
		colors = {
			{ name = "Lime", hex = "#00ff00" },
			{ name = "Lime Green", hex = "#32cd32" },
			{ name = "Light Green", hex = "#90ee90" },
			{ name = "Pale Green", hex = "#98fb98" },
			{ name = "Spring Green", hex = "#00ff7f" },
			{ name = "Medium Sea Green", hex = "#3cb371" },
			{ name = "Forest Green", hex = "#228b22" },
			{ name = "Dark Green", hex = "#006400" },
			{ name = "Olive", hex = "#808000" },
			{ name = "Olive Drab", hex = "#6b8e23" },
		},
	},
	{
		name = "Blues",
		colors = {
			{ name = "Light Blue", hex = "#add8e6" },
			{ name = "Sky Blue", hex = "#87ceeb" },
			{ name = "Cornflower", hex = "#6495ed" },
			{ name = "Dodger Blue", hex = "#1e90ff" },
			{ name = "Royal Blue", hex = "#4169e1" },
			{ name = "Steel Blue", hex = "#4682b4" },
			{ name = "Medium Blue", hex = "#0000cd" },
			{ name = "Navy", hex = "#000080" },
			{ name = "Teal", hex = "#008080" },
			{ name = "Dark Cyan", hex = "#008b8b" },
		},
	},
	{
		name = "Purples & Pinks",
		colors = {
			{ name = "Lavender", hex = "#e6e6fa" },
			{ name = "Plum", hex = "#dda0dd" },
			{ name = "Violet", hex = "#ee82ee" },
			{ name = "Orchid", hex = "#da70d6" },
			{ name = "Fuchsia", hex = "#ff00ff" },
			{ name = "Medium Purple", hex = "#9370db" },
			{ name = "Blue Violet", hex = "#8a2be2" },
			{ name = "Indigo", hex = "#4b0082" },
			{ name = "Hot Pink", hex = "#ff69b4" },
			{ name = "Deep Pink", hex = "#ff1493" },
		},
	},
}

-- Insert a hex color at the current cursor position
local function insert_color(hex)
	local pos = editor.cursor()
	editor.insert(pos.line, pos.col, hex)
	ttt.log("Inserted: " .. hex)
	ttt.close_drawer()
end

-- Build list items for a palette category
local function build_items(palette)
	local items = {}
	for _, color in ipairs(palette.colors) do
		table.insert(items, {
			id = color.hex,
			label = color.name,
			badge = color.hex,
		})
	end
	return items
end

-- Open the color picker drawer
local function open_color_picker()
	ttt.open_drawer({
		width = 36,
		min_width = 28,
		render = function(panel)
			panel:title({ text = "Color Picker", margin_bottom = 1, padding_left = 1 })

			for _, palette in ipairs(palettes) do
				panel:label({
					text = palette.name,
					style = "muted",
					badge = tostring(#palette.colors),
					padding_left = 1,
					padding_right = 1,
					margin_top = 1,
				})
				panel:box({
					border = true,
					render = function(bp)
						bp:list({
							items = build_items(palette),
							on_command = function(command, node)
								if command == "activate" then
									insert_color(node.id)
								end
							end,
						})
					end,
				})
			end
		end,
	})
end

-- Register the plugin
ttt.register({
	commands = {
		{
			id = "colorPicker.open",
			title = "Color Picker: Open",
			handler = open_color_picker,
		},
	},
	keybindings = {
		{ key = "ctrl+k c", command = "colorPicker.open" },
	},
})
