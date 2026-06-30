local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.yaml", {command = {"yaml-language-server", "--stdio"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.yaml", nil)
end)
