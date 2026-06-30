local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.ruby", {command = {"ruby-lsp"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.ruby", nil)
end)
