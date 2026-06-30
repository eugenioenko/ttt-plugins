local ttt = require("ttt")
local editor = require("ttt.editor")

local function show_preview()
	local path = editor.file_path()
	if not path or not path:match("%.md$") then
		ttt.log("warn", "Current file is not a markdown file")
		return
	end

	local text = editor.buffer_text()
	if not text or text == "" then
		ttt.log("warn", "Buffer is empty")
		return
	end

	local name = editor.file_name()

	ttt.open_tab({
		title = "Preview: " .. name,
		render = function(p)
			p:markdown({ text = text, padding_left = 2 })
		end,
	})
end

ttt.register({
	commands = {
		{
			id = "markdown.preview",
			title = "Preview: Markdown",
			handler = show_preview,
		},
	},
})
