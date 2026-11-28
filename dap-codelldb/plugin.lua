local ttt = require("ttt")
local settings = require("ttt.settings")

local adapter = {
  command = {"codelldb", "--port", "${port}"},
  transport = "server",
  languages = {"c", "cpp", "rust"},
  markers = {"Cargo.toml", "CMakeLists.txt", "Makefile"},
  configurations = {
    {name = "Launch program", request = "launch", program = "${workspaceFolder}/example", cwd = "${workspaceFolder}"},
  },
}

ttt.on_install(function()
  settings.set_default("debug.adapters.lldb", adapter)
end)
