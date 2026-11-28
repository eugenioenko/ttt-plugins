local ttt = require("ttt")
local settings = require("ttt.settings")

local adapter = {
  command = {"gdb", "-q", "-nx", "-i", "dap"},
  transport = "stdio",
  languages = {"c", "cpp"},
  markers = {"CMakeLists.txt", "Makefile", "meson.build"},
  configurations = {
    {name = "Launch program", request = "launch", program = "${workspaceFolder}/example", cwd = "${workspaceFolder}"},
    {name = "Attach to process", request = "attach", pid = "${command:pickProcess}"},
  },
}

ttt.on_install(function()
  settings.set_default("debug.adapters.gdb", adapter)
end)
