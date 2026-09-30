local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("formatters.py", "ruff format --stdin-filename {file} -")
end)

ttt.on_uninstall(function()
  settings.set("formatters.py", nil)
end)
