local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("formatters.rs", "rustfmt")
end)

ttt.on_uninstall(function()
  settings.set("formatters.rs", nil)
end)
