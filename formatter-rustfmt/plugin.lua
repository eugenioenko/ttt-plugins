local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("formatters.rs", "rustfmt")

ttt.on_uninstall(function()
  settings.set("formatters.rs", nil)
end)
