local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.kotlin", {command = {"kotlin-language-server"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.kotlin", nil)
end)
