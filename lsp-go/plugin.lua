local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.go", {command = {"gopls"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.go", nil)
end)
