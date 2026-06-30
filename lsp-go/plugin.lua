local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.go", {command = {"gopls"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.go", nil)
end)
