local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set_default("debug.adapters.coreclr", {
    command = {"netcoredbg", "--interpreter=vscode"},
    transport = "stdio",
    languages = {"csharp"},
  })
end)
