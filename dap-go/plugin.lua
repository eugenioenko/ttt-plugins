local ttt = require("ttt")
local settings = require("ttt.settings")

local adapter = {
  provider = "delve",
  command = {"dlv", "dap", "--listen=unix:${socket}"},
  transport = "listen",
  addressPattern = "^DAP server listening at: (.+)$",
  fileLaunch = {program = "${fileDirname}"},
  fileLaunchOverrides = {
    {pattern = "*_test.go", arguments = {mode = "test"}},
  },
  languages = {"go"},
  markers = {"go.mod"},
  configurations = {
    {name = "Launch package", request = "launch", program = "${workspaceFolder}"},
    {name = "Debug tests", request = "launch", mode = "test", program = "${workspaceFolder}"},
  },
}

ttt.on_install(function()
  settings.set_default("debug.adapters.go", adapter)
end)
