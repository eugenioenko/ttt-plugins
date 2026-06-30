local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("formatters.py", "black -q -")
end)

ttt.on_uninstall(function()
  settings.set("formatters.py", nil)
end)
