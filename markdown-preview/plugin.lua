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

	local lines = ttt.markdown(text)
	local name = editor.file_name()

	ttt.open_tab({
		title = "Preview: " .. name,
		render = function(p)
			p:scrollview({
				render = function(sp)
					for _, line in ipairs(lines) do
						local parts = {}
						for _, span in ipairs(line) do
							if span.text ~= "" then
								table.insert(parts, span)
							end
						end
						if #parts == 0 then
							sp:label("")
						elseif #parts == 1 then
							sp:label({ text = parts[1].text, style = parts[1].style, padding_left = 1 })
						else
							local full = ""
							local style = "default"
							for _, span in ipairs(parts) do
								full = full .. span.text
								if style == "default" and span.style ~= "default" then
									style = span.style
								end
							end
							sp:label({ text = full, style = style, padding_left = 1 })
						end
					end
				end,
			})
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
