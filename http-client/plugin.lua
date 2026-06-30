local ttt = require("ttt")
local net = require("ttt.net")
local editor = require("ttt.editor")

-- State
local url = ""
local method = "GET"
local body = ""
local response_lines = {}
local response_status = nil
local loading = false

local function split_lines(text)
	local lines = {}
	for line in (text .. "\n"):gmatch("(.-)\n") do
		table.insert(lines, line)
	end
	return lines
end

local function do_request(panel)
	if url == "" then
		ttt.log("warn", "URL is empty")
		return
	end

	loading = true
	response_lines = {}
	response_status = nil
	if panel then
		panel:redraw()
	end

	local target = url
	if not target:match("^https?://") then
		target = "http://" .. target
	end

	ttt.log("info", method .. " " .. target)

	local function handle_response(resp)
		loading = false
		if resp.error then
			response_status = "error"
			response_lines = { "Error: " .. resp.error }
		else
			response_status = tostring(resp.status)
			response_lines = split_lines(resp.body)
		end
		ttt.log("info", "Response: " .. (response_status or "?"))
		if panel then
			panel:redraw()
		end
	end

	if method == "POST" then
		net.post_async(target, {
			headers = { ["Content-Type"] = "application/json" },
			body = body,
		}, handle_response)
	else
		net.get_async(target, handle_response)
	end
end

local last_panel = nil

local function open_client()
	ttt.open_drawer({
		width = 50,
		min_width = 30,
		render = function(panel)
			last_panel = panel

			panel:label({ text = "HTTP Client", style = "bold", padding_left = 1 })

			panel:vstack({
				gap = 0,
				render = function(p)
					p:label({ text = "Method", style = "muted", padding_left = 1 })
					p:list({
						items = {
							{ id = "GET", label = "GET", icon = method == "GET" and "●" or "○" },
							{ id = "POST", label = "POST", icon = method == "POST" and "●" or "○" },
						},
						on_select = function(node)
							method = node.id
							panel:redraw()
						end,
					})
				end,
			})

			panel:label({ text = "URL", style = "muted", padding_left = 1, margin_top = 1 })
			panel:input({
				placeholder = "https://api.example.com/data",
				on_change = function(text)
					url = text
				end,
				on_submit = function(text)
					url = text
					do_request(panel)
				end,
			})

			if method == "POST" then
				panel:label({ text = "Body (JSON)", style = "muted", padding_left = 1, margin_top = 1 })
				panel:input({
					placeholder = '{"key": "value"}',
					on_change = function(text)
						body = text
					end,
				})
			end

			panel:vstack({
				render = function(p)
					p:button({
						label = "&Send",
						on_click = function()
							do_request(panel)
						end,
					})
				end,
			})

			if loading then
				panel:label({ text = "Loading...", style = "muted", padding_left = 1, margin_top = 1 })
			elseif response_status then
				local status_style = "success"
				if response_status == "error" or (tonumber(response_status) and tonumber(response_status) >= 400) then
					status_style = "danger"
				elseif tonumber(response_status) and tonumber(response_status) >= 300 then
					status_style = "warning"
				end
				panel:label({
					text = "Response",
					badge = response_status,
					padding_left = 1,
					margin_top = 1,
				})

				panel:box({
					border = true,
					render = function(bp)
						if #response_lines == 0 then
							bp:label({ text = "(empty response)", style = "muted" })
						else
							for _, line in ipairs(response_lines) do
								bp:label(line)
							end
						end
					end,
				})

				panel:vstack({
					render = function(p)
						p:button({
							label = "&Insert to editor",
							on_click = function()
								local text = table.concat(response_lines, "\n")
								local pos = editor.cursor()
								editor.insert(pos.line, pos.col, text)
								ttt.log("info", "Inserted response into editor")
								ttt.close_drawer()
							end,
						})
					end,
				})
			end
		end,
	})
end

ttt.register({
	commands = {
		{ id = "httpClient.open", title = "HTTP Client: Open", handler = open_client },
	},
	keybindings = {
		{ key = "ctrl+k u", command = "httpClient.open" },
	},
})
