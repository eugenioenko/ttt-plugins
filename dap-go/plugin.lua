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
}
local keys = {"debug.adapters.go"}

ttt.on_install(function()
  for _, key in ipairs(keys) do
    settings.set_default(key, adapter)
  end
end)
