local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("formatters.lua", "stylua -")
end)

ttt.on_uninstall(function()
  settings.set("formatters.lua", nil)
end)
