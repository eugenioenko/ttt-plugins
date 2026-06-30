local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.ruby", {command = {"ruby-lsp"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.ruby", nil)
end)
