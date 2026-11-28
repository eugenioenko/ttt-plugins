local ttt = require("ttt")
local settings = require("ttt.settings")

local adapter = {
  provider = "debugpy",
  command = {"${python}", "-m", "debugpy.adapter"},
  transport = "stdio",
  fileLaunch = {program = "${file}"},
  languages = {"python"},
  markers = {"pyproject.toml", "requirements.txt", "setup.py"},
  configurations = {
    {name = "Launch main.py", request = "launch", program = "${workspaceFolder}/main.py"},
  },
}

ttt.on_install(function()
  settings.set_default("debug.adapters.debugpy", adapter)
end)
