local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("formatters.lua", "stylua -")

ttt.on_uninstall(function()
  settings.set("formatters.lua", nil)
end)
