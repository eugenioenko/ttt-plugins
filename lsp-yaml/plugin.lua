local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.yaml", {command = {"yaml-language-server", "--stdio"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.yaml", nil)
end)
