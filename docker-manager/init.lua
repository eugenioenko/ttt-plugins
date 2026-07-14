local ttt = require("ttt")
local sys = require("ttt.system")

-- State
local containers = {}
local images = {}
local volumes = {}
local loading = true
local initialized = false

-- Parse docker output
local function parse_lines(stdout)
	local items = {}
	for line in stdout:gmatch("[^\n]+") do
		if line ~= "" then
			table.insert(items, line)
		end
	end
	return items
end

local function refresh_containers(panel)
	sys.exec_async(
		"docker",
		{ "ps", "-a", "--format", "{{.Names}}\t{{.Status}}\t{{.Image}}\t{{.ID}}" },
		function(result)
			containers = {}
			if result.exit_code == 0 then
				for _, line in ipairs(parse_lines(result.stdout)) do
					local name, status, image, id = line:match("^(.-)\t(.-)\t(.-)\t(.+)$")
					if name then
						local running = status:match("^Up") ~= nil
						table.insert(containers, {
							name = name,
							status = status,
							image = image,
							id = id,
							running = running,
						})
					end
				end
			end
			if panel then
				panel:redraw()
			end
		end
	)
end

local function refresh_images(panel)
	sys.exec_async("docker", { "images", "--format", "{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.ID}}" }, function(result)
		images = {}
		if result.exit_code == 0 then
			for _, line in ipairs(parse_lines(result.stdout)) do
				local repo, size, id = line:match("^(.-)\t(.-)\t(.+)$")
				if repo then
					table.insert(images, {
						repo = repo,
						size = size,
						id = id,
					})
				end
			end
		end
		if panel then
			panel:redraw()
		end
	end)
end

local function refresh_volumes(panel)
	sys.exec_async("docker", { "volume", "ls", "--format", "{{.Name}}\t{{.Driver}}" }, function(result)
		volumes = {}
		if result.exit_code == 0 then
			for _, line in ipairs(parse_lines(result.stdout)) do
				local name, driver = line:match("^(.-)\t(.+)$")
				if name then
					table.insert(volumes, {
						name = name,
						driver = driver,
					})
				end
			end
		end
		loading = false
		if panel then
			panel:redraw()
		end
	end)
end

local function refresh_all(panel)
	refresh_containers(panel)
	refresh_images(panel)
	refresh_volumes(panel)
end

-- Container actions
local function container_action(action, name, panel)
	ttt.log("info", action .. " container: " .. name)
	sys.exec_async("docker", { action, name }, function(result)
		if result.exit_code == 0 then
			ttt.log("info", action .. " " .. name .. ": ok")
		else
			ttt.log("error", action .. " " .. name .. ": " .. result.stderr)
		end
		refresh_containers(panel)
	end)
end

local function is_container_running(name)
	for _, c in ipairs(containers) do
		if c.name == name then
			return c.running
		end
	end
	return false
end

local function container_start(name, panel)
	container_action("start", name, panel)
end
local function container_stop(name, panel)
	container_action("stop", name, panel)
end
local function container_restart(name, panel)
	container_action("restart", name, panel)
end

local function container_remove(name, panel)
	ttt.confirm("Remove container '" .. name .. "'?", function()
		ttt.log("info", "removing container: " .. name)
		sys.exec_async("docker", { "rm", "-f", name }, function(result)
			if result.exit_code == 0 then
				ttt.log("info", "removed " .. name)
			else
				ttt.log("error", "remove " .. name .. ": " .. result.stderr)
			end
			refresh_containers(panel)
		end)
	end, "Delete")
end

-- Image actions
local function image_remove(id, panel)
	ttt.confirm("Remove image '" .. id .. "'?", function()
		ttt.log("info", "removing image: " .. id)
		sys.exec_async("docker", { "rmi", id }, function(result)
			if result.exit_code == 0 then
				ttt.log("info", "removed image " .. id)
			else
				ttt.log("error", "remove image: " .. result.stderr)
			end
			refresh_images(panel)
		end)
	end, "Delete")
end

-- Volume actions
local function volume_remove(name, panel)
	ttt.confirm("Remove volume '" .. name .. "'?", function()
		ttt.log("info", "removing volume: " .. name)
		sys.exec_async("docker", { "volume", "rm", name }, function(result)
			if result.exit_code == 0 then
				ttt.log("info", "removed volume " .. name)
			else
				ttt.log("error", "remove volume: " .. result.stderr)
			end
			refresh_volumes(panel)
		end)
	end, "Delete")
end

-- Build list items
local function container_items()
	local items = {}
	for _, c in ipairs(containers) do
		local icon = c.running and "▶" or "■"
		local icon_style = c.running and "success" or "danger"
		local actions = {}
		if c.running then
			table.insert(actions, { icon = "■", command = "stop" })
			table.insert(actions, { icon = "↺", command = "restart" })
		else
			table.insert(actions, { icon = "▶", command = "start" })
			table.insert(actions, { icon = "×", command = "remove" })
		end
		table.insert(items, {
			id = c.name,
			label = c.name,
			icon = icon,
			icon_style = icon_style,
			badge = c.image,
			actions = actions,
		})
	end
	return items
end

local function image_items()
	local items = {}
	for _, img in ipairs(images) do
		table.insert(items, {
			id = img.id,
			label = img.repo,
			badge = img.size,
			actions = {
				{ icon = "×", command = "remove" },
			},
		})
	end
	return items
end

local function volume_items()
	local items = {}
	for _, vol in ipairs(volumes) do
		table.insert(items, {
			id = vol.name,
			label = vol.name,
			badge = vol.driver,
			actions = {
				{ icon = "×", command = "remove" },
			},
		})
	end
	return items
end

-- Command handlers
local last_panel = nil

local function cmd_refresh()
	refresh_all(last_panel)
end

local function cmd_prune_containers()
	ttt.confirm("Prune all stopped containers?", function()
		ttt.log("info", "pruning stopped containers...")
		sys.exec_async("docker", { "container", "prune", "-f" }, function(result)
			if result.exit_code == 0 then
				ttt.log("info", "container prune: ok")
			else
				ttt.log("error", "container prune: " .. result.stderr)
			end
			refresh_containers(last_panel)
		end)
	end)
end

local function cmd_prune_images()
	ttt.confirm("Prune all unused images?", function()
		ttt.log("info", "pruning unused images...")
		sys.exec_async("docker", { "image", "prune", "-f" }, function(result)
			if result.exit_code == 0 then
				ttt.log("info", "image prune: ok")
			else
				ttt.log("error", "image prune: " .. result.stderr)
			end
			refresh_images(last_panel)
		end)
	end)
end

local function cmd_prune_volumes()
	ttt.confirm("Prune all unused volumes?", function()
		ttt.log("info", "pruning unused volumes...")
		sys.exec_async("docker", { "volume", "prune", "-f" }, function(result)
			if result.exit_code == 0 then
				ttt.log("info", "volume prune: ok")
			else
				ttt.log("error", "volume prune: " .. result.stderr)
			end
			refresh_volumes(last_panel)
		end)
	end)
end

-- Registration
ttt.register({
	sidebar = {
		title = "Docker",
		actions = {
			{ label = "Refresh All", command = "docker.sidebarAction.refresh" },
			{ separator = true },
			{ label = "Prune Containers", command = "docker.sidebarAction.pruneContainers" },
			{ label = "Prune Images", command = "docker.sidebarAction.pruneImages" },
			{ label = "Prune Volumes", command = "docker.sidebarAction.pruneVolumes" },
			{ separator = true },
			{ label = "Help", command = "docker.sidebarAction.help" },
		},
		on_action = function(command)
			if command == "docker.sidebarAction.refresh" then
				refresh_all(last_panel)
			elseif command == "docker.sidebarAction.pruneContainers" then
				cmd_prune_containers()
			elseif command == "docker.sidebarAction.pruneImages" then
				cmd_prune_images()
			elseif command == "docker.sidebarAction.pruneVolumes" then
				cmd_prune_volumes()
			elseif command == "docker.sidebarAction.help" then
				ttt.show_info("Docker Shortcuts", {
					{ key = "Enter / Space", value = "Toggle start / stop container" },
					{ key = "d", value = "Delete container, image or volume" },
					{ key = "r", value = "Refresh all" },
					{ key = "Right-click", value = "Context menu on item" },
					{ key = "Up / Down", value = "Navigate items" },
					{ key = "Ctrl+K r", value = "Refresh (global)" },
				})
			end
		end,
		render = function(panel)
			last_panel = panel

			if not initialized then
				initialized = true
				refresh_all(panel)
			end

			if loading then
				panel:label({ text = "Loading...", style = "muted" })
				return
			end

			-- Containers section
			panel:vstack({
				render = function(p)
					p:label({ text = "Containers", badge = tostring(#containers), padding_left = 1, padding_right = 1 })
					p:box({
						border = true,
						render = function(bp)
							bp:list({
								items = container_items(),
								select_on_click = true,
								key_commands = { d = "remove" },
								on_command = function(command, node)
									if command == "activate" then
										if is_container_running(node.id) then
											container_stop(node.id, panel)
										else
											container_start(node.id, panel)
										end
									elseif command == "start" then
										container_start(node.id, panel)
									elseif command == "stop" then
										container_stop(node.id, panel)
									elseif command == "restart" then
										container_restart(node.id, panel)
									elseif command == "remove" then
										container_remove(node.id, panel)
									end
								end,
								node_menu = {
									{ label = "Start", command = "start" },
									{ label = "Stop", command = "stop" },
									{ label = "Restart", command = "restart" },
									{ separator = true },
									{ label = "Remove", command = "remove" },
								},
							})
						end,
					})
				end,
			})

			-- Images section
			panel:vstack({
				render = function(p)
					p:label({ text = "Images", badge = tostring(#images), padding_left = 1, padding_right = 1 })
					p:box({
						border = true,
						render = function(bp)
							bp:list({
								items = image_items(),
								key_commands = { d = "remove" },
								on_command = function(command, node)
									if command == "remove" then
										image_remove(node.id, panel)
									end
								end,
								node_menu = {
									{ label = "Remove", command = "remove" },
								},
							})
						end,
					})
				end,
			})

			-- Volumes section
			panel:vstack({
				render = function(p)
					p:label({ text = "Volumes", badge = tostring(#volumes), padding_left = 1, padding_right = 1 })
					p:box({
						border = true,
						render = function(bp)
							bp:list({
								items = volume_items(),
								key_commands = { d = "remove" },
								on_command = function(command, node)
									if command == "remove" then
										volume_remove(node.id, panel)
									end
								end,
								node_menu = {
									{ label = "Remove", command = "remove" },
								},
							})
						end,
					})
				end,
			})
		end,

		on_event = function(event)
			if event.type == "key" then
				if event.key == "r" and event.mod == nil then
					refresh_all(last_panel)
				end
			end
		end,
	},

	commands = {
		{ id = "docker.refresh", title = "Docker: Refresh", handler = cmd_refresh },
		{ id = "docker.pruneContainers", title = "Docker: Prune Containers", handler = cmd_prune_containers },
		{ id = "docker.pruneImages", title = "Docker: Prune Images", handler = cmd_prune_images },
		{ id = "docker.pruneVolumes", title = "Docker: Prune Volumes", handler = cmd_prune_volumes },
	},

	keybindings = {
		{ key = "ctrl+k r", command = "docker.refresh" },
	},
})
