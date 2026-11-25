local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set_default("debug.adapters.lldb-dap", {
    command = {"lldb-dap"},
    transport = "stdio",
    languages = {"c"},
  })
end)
