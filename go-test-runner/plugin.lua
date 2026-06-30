local ttt = require("ttt")
local sys = require("ttt.system")
local editor = require("ttt.editor")

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local packages = {} -- array of {path, name, tests}
local test_status = {} -- "importpath::TestName" -> "pass"|"fail"|"running"|"unknown"
local test_output = {} -- "importpath::TestName" -> raw -v output
local test_files = {} -- "importpath::TestName" -> {file, line}
local loading = false
local initialized = false
local last_panel = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function status_icon(status)
	if status == "pass" then
		return "●"
	elseif status == "fail" then
		return "✕"
	elseif status == "running" then
		return "⟳"
	else
		return "○"
	end
end

local function compute_stats()
	local passed, failed, not_run, running = 0, 0, 0, 0
	for _, s in pairs(test_status) do
		if s == "pass" then
			passed = passed + 1
		elseif s == "fail" then
			failed = failed + 1
		elseif s == "running" then
			running = running + 1
		else
			not_run = not_run + 1
		end
	end
	return passed, failed, not_run, running
end

local function make_key(pkg_path, test_name)
	return pkg_path .. "::" .. test_name
end

local function parse_key(key)
	return key:match("^(.+)::(.+)$")
end

-- Find a package entry by import path.
local function find_package(pkg_path)
	for _, pkg in ipairs(packages) do
		if pkg.path == pkg_path then
			return pkg
		end
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- Test discovery
-- ---------------------------------------------------------------------------

local function discover_tests(panel)
	loading = true
	if panel then
		panel:redraw()
	end

	sys.exec_async("go", { "test", "-list", ".*", "./..." }, function(result)
		loading = false
		packages = {}
		test_status = {}
		test_output = {}
		test_files = {}

		if result.exit_code ~= 0 and (result.stdout == nil or result.stdout == "") then
			ttt.log("error", "Failed to discover tests: " .. (result.stderr or "unknown error"))
			if panel then
				panel:redraw()
			end
			return
		end

		-- Parse stdout: test names interleaved with "ok"/"?"/"FAIL" summary lines.
		-- Test names appear one per line before the summary line of their package.
		local current_tests = {}
		local stdout = result.stdout or ""

		for line in stdout:gmatch("[^\n]+") do
			local trimmed = line:match("^%s*(.-)%s*$")
			if trimmed == "" then
			-- skip blank lines
			elseif trimmed:match("^ok%s") then
				local pkg_path = trimmed:match("^ok%s+(%S+)")
				if pkg_path and #current_tests > 0 then
					local short_name = pkg_path:match("([^/]+)$") or pkg_path
					table.insert(packages, { path = pkg_path, name = short_name, tests = {} })
					local pkg = packages[#packages]
					for _, t in ipairs(current_tests) do
						table.insert(pkg.tests, t)
						test_status[make_key(pkg_path, t)] = "unknown"
					end
				end
				current_tests = {}
			elseif trimmed:match("^%?%s") then
				-- no test files — discard collected names (shouldn't be any)
				current_tests = {}
			elseif trimmed:match("^FAIL%s") then
				local pkg_path = trimmed:match("^FAIL%s+(%S+)")
				if pkg_path then
					ttt.log("warn", "Package failed to compile: " .. pkg_path)
				end
				current_tests = {}
			elseif trimmed:match("^Test[A-Z_]") then
				-- Go test function name (must start with Test + uppercase/underscore)
				local name = trimmed:match("^(%S+)")
				if name then
					table.insert(current_tests, name)
				end
			end
			-- ignore Benchmark/Example/Fuzz and other output
		end

		-- Log stderr warnings (compilation errors, etc.)
		if result.stderr and result.stderr ~= "" then
			for line in result.stderr:gmatch("[^\n]+") do
				if line:match("%S") then
					ttt.log("warn", line)
				end
			end
		end

		local total = 0
		for _, pkg in ipairs(packages) do
			total = total + #pkg.tests
		end
		ttt.log("Discovered " .. tostring(total) .. " tests in " .. tostring(#packages) .. " packages")
		if panel then
			panel:redraw()
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Running tests
-- ---------------------------------------------------------------------------

-- Extract file:line references from go test -v failure output.
local function extract_failure_location(output, test_name)
	-- Look for lines like "    foo_test.go:42: expected ..."
	local capturing = false
	for line in output:gmatch("[^\n]+") do
		if line:find("--- FAIL: " .. test_name, 1, true) then
			capturing = true
		elseif capturing then
			local file, line_num = line:match("%s+(%S+_test%.go):(%d+):")
			if file then
				return file, tonumber(line_num)
			end
		end
	end
	-- Fallback: scan entire output for any _test.go reference
	for line in output:gmatch("[^\n]+") do
		local file, line_num = line:match("%s+(%S+_test%.go):(%d+):")
		if file then
			return file, tonumber(line_num)
		end
	end
	return nil, nil
end

-- Parse -v output to update status for a set of test names in a package.
local function parse_verbose_results(output, pkg_path, test_names)
	for _, test_name in ipairs(test_names) do
		local key = make_key(pkg_path, test_name)
		test_output[key] = output

		if output:find("--- PASS: " .. test_name, 1, true) then
			test_status[key] = "pass"
		elseif output:find("--- FAIL: " .. test_name, 1, true) then
			test_status[key] = "fail"
			local file, line_num = extract_failure_location(output, test_name)
			if file then
				test_files[key] = { file = file, line = line_num }
			end
		else
			-- Test may not have run (filtered out, skipped, or build error)
			if test_status[key] == "running" then
				test_status[key] = "unknown"
			end
		end
	end
end

local function run_test(pkg_path, test_name, panel)
	local key = make_key(pkg_path, test_name)
	test_status[key] = "running"
	test_output[key] = ""
	if panel then
		panel:redraw()
	end

	ttt.log("Running " .. test_name .. " in " .. pkg_path)

	sys.exec_async("go", { "test", "-run", "^" .. test_name .. "$", "-v", pkg_path }, function(result)
		local output = result.stdout or ""
		parse_verbose_results(output, pkg_path, { test_name })

		local status = test_status[key]
		if status == "pass" then
			ttt.log("PASS: " .. test_name)
		elseif status == "fail" then
			ttt.log("error", "FAIL: " .. test_name)
		end

		if panel then
			panel:redraw()
		end
	end)
end

local function run_package(pkg_path, panel)
	local pkg = find_package(pkg_path)
	if not pkg then
		return
	end

	for _, test_name in ipairs(pkg.tests) do
		test_status[make_key(pkg_path, test_name)] = "running"
	end
	if panel then
		panel:redraw()
	end

	ttt.log("Running all tests in " .. pkg_path)

	sys.exec_async("go", { "test", "-v", pkg_path }, function(result)
		local output = result.stdout or ""
		parse_verbose_results(output, pkg_path, pkg.tests)

		local pass_count, fail_count = 0, 0
		for _, test_name in ipairs(pkg.tests) do
			local s = test_status[make_key(pkg_path, test_name)]
			if s == "pass" then
				pass_count = pass_count + 1
			elseif s == "fail" then
				fail_count = fail_count + 1
			end
		end

		if fail_count > 0 then
			ttt.log("error", pkg.name .. ": " .. pass_count .. " passed, " .. fail_count .. " failed")
		else
			ttt.log(pkg.name .. ": " .. pass_count .. " passed")
		end

		if panel then
			panel:redraw()
		end
	end)
end

local function run_all(panel)
	-- Mark every known test as running
	for key, _ in pairs(test_status) do
		test_status[key] = "running"
	end
	if panel then
		panel:redraw()
	end

	ttt.log("Running all tests...")

	sys.exec_async("go", { "test", "-v", "./..." }, function(result)
		local output = result.stdout or ""

		-- Update status for every known test
		for _, pkg in ipairs(packages) do
			parse_verbose_results(output, pkg.path, pkg.tests)
		end

		local passed, failed = compute_stats()
		if failed > 0 then
			ttt.log("error", "Tests complete: " .. passed .. " passed, " .. failed .. " failed")
		else
			ttt.log("Tests complete: " .. passed .. " passed")
		end

		if panel then
			panel:redraw()
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Tree building
-- ---------------------------------------------------------------------------

local function build_tree_items()
	local items = {}
	for _, pkg in ipairs(packages) do
		local children = {}
		local pkg_has_fail = false
		local pkg_all_pass = #pkg.tests > 0
		local pkg_has_running = false

		for _, test_name in ipairs(pkg.tests) do
			local key = make_key(pkg.path, test_name)
			local status = test_status[key] or "unknown"

			if status == "fail" then
				pkg_has_fail = true
				pkg_all_pass = false
			end
			if status ~= "pass" then
				pkg_all_pass = false
			end
			if status == "running" then
				pkg_has_running = true
				pkg_all_pass = false
			end

			table.insert(children, {
				id = key,
				label = test_name,
				icon = status_icon(status),
			})
		end

		-- Aggregate package icon
		local pkg_icon
		if pkg_has_running then
			pkg_icon = status_icon("running")
		elseif pkg_has_fail then
			pkg_icon = status_icon("fail")
		elseif pkg_all_pass then
			pkg_icon = status_icon("pass")
		else
			pkg_icon = status_icon("unknown")
		end

		table.insert(items, {
			id = pkg.path,
			label = pkg.name,
			icon = pkg_icon,
			badge = tostring(#pkg.tests),
			expandable = true,
			expanded = false,
			children = children,
		})
	end
	return items
end

-- ---------------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------------

local function navigate_to_test(key)
	local info = test_files[key]
	if not info then
		ttt.log("warn", "No file location recorded for this test")
		return
	end

	ttt.log("Test location: " .. info.file .. ":" .. tostring(info.line))

	-- If the failing test's file is currently open, jump to the line
	local current = editor.file_name()
	if current and current == info.file then
		editor.set_cursor(info.line, 1)
	else
		ttt.log("Open " .. info.file .. " and go to line " .. tostring(info.line))
	end
end

-- ---------------------------------------------------------------------------
-- Command handlers
-- ---------------------------------------------------------------------------

local function cmd_run_all()
	run_all(last_panel)
end

local function cmd_refresh()
	discover_tests(last_panel)
end

local function cmd_run_current_file()
	local file = editor.file_path()
	if not file or not file:match("_test%.go$") then
		ttt.log("warn", "Current file is not a Go test file")
		return
	end

	-- Try to match the current file's directory against known packages.
	-- Extract directory components and compare suffixes.
	local dir = file:match("^(.+)/[^/]+$") or ""

	for _, pkg in ipairs(packages) do
		-- Check if the file's directory path ends with the package's import path suffix
		local pkg_suffix = pkg.path:gsub("^[^/]+", "") -- strip module prefix
		if pkg_suffix ~= "" and dir:match(pkg_suffix:gsub("%-", "%%-") .. "$") then
			run_package(pkg.path, last_panel)
			return
		end
		-- Fallback: match by short package name
		if dir:match("/" .. pkg.name .. "$") or dir == pkg.name then
			run_package(pkg.path, last_panel)
			return
		end
	end

	ttt.log("warn", "Could not determine package for " .. file)
end

-- ---------------------------------------------------------------------------
-- Registration
-- ---------------------------------------------------------------------------

ttt.register({
	sidebar = {
		title = "Tests",

		actions = {
			{ label = "Run All Tests", command = "gotest.action.runAll" },
			{ label = "Refresh Test List", command = "gotest.action.refresh" },
		},

		on_action = function(command)
			if command == "gotest.action.runAll" then
				run_all(last_panel)
			elseif command == "gotest.action.refresh" then
				discover_tests(last_panel)
			end
		end,

		render = function(panel)
			last_panel = panel

			-- Auto-discover on first render
			if not initialized then
				initialized = true
				discover_tests(panel)
			end

			if loading then
				panel:label({ text = "Discovering tests...", style = "muted", padding_left = 1, padding_right = 1 })
				return
			end

			-- Summary label with badge
			local passed, failed, not_run, running = compute_stats()
			local total = passed + failed + not_run + running
			local parts = {}
			if passed > 0 then
				table.insert(parts, tostring(passed) .. " passed")
			end
			if failed > 0 then
				table.insert(parts, tostring(failed) .. " failed")
			end
			if not_run > 0 then
				table.insert(parts, tostring(not_run) .. " not run")
			end
			if running > 0 then
				table.insert(parts, tostring(running) .. " running")
			end

			local summary = "Tests: " .. (#parts > 0 and table.concat(parts, ", ") or "none found")
			panel:label({
				text = summary,
				style = "muted",
				badge = tostring(total),
				padding_left = 1,
				padding_right = 1,
				border_bottom = true,
			})

			if #packages == 0 then
				panel:label({ text = "No test packages found", style = "muted", padding_left = 1 })
				panel:label({ text = "Press r to refresh", style = "muted", padding_left = 1 })
				return
			end

			-- Test tree
			panel:box({
				padding_left = 1,
				render = function(bp)
					bp:tree({
						items = build_tree_items(),
						indent = 2,
						on_command = function(command, node)
							local pkg_path, test_name = parse_key(node.id)
							if command == "activate" then
								if pkg_path and test_name then
									local status = test_status[node.id]
									if status == "fail" then
										navigate_to_test(node.id)
									else
										run_test(pkg_path, test_name, panel)
									end
								else
									run_package(node.id, panel)
								end
							elseif command == "run" then
								if pkg_path and test_name then
									run_test(pkg_path, test_name, panel)
								else
									run_package(node.id, panel)
								end
							elseif command == "run_all" then
								if pkg_path then
									run_package(pkg_path, panel)
								else
									run_package(node.id, panel)
								end
							end
						end,
						node_menu = {
							{ label = "▶ Run", command = "run" },
							{ label = "▶ Run All in Package", command = "run_all" },
						},
						key_commands = {
							f = "run",
							a = "run_all",
						},
					})
				end,
			})
		end,

		on_event = function(event)
			if event.type == "key" then
				if event.key == "r" and event.mod == nil then
					discover_tests(last_panel)
				end
			end
		end,
	},

	commands = {
		{ id = "gotest.runAll", title = "Go Tests: Run All", handler = cmd_run_all },
		{ id = "gotest.runCurrentFile", title = "Go Tests: Run Current File", handler = cmd_run_current_file },
		{ id = "gotest.refresh", title = "Go Tests: Refresh", handler = cmd_refresh },
	},

	keybindings = {
		{ key = "ctrl+k t", command = "gotest.runAll" },
	},
})
