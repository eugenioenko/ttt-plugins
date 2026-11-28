local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set_default("debug.adapters.coreclr", {
    command = {"netcoredbg", "--interpreter=vscode"},
    transport = "stdio",
    languages = {"csharp"},
    markers = {"*.csproj", "*.sln"},
    configurations = {
      {name = "Launch Example", request = "launch", program = "${workspaceFolder}/bin/Debug/net8.0/Example.dll", cwd = "${workspaceFolder}"},
      {name = "Attach to process", request = "attach", processId = "${command:pickProcess}"},
    },
  })
end)
