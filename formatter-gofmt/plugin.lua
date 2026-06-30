local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("formatters.go", "gofmt")

ttt.on_uninstall(function()
  settings.set("formatters.go", nil)
end)
