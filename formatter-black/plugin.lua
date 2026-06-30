local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("formatters.py", "black -q -")

ttt.on_uninstall(function()
  settings.set("formatters.py", nil)
end)
