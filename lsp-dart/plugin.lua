local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.dart", {command = {"dart", "language-server", "--protocol=lsp"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.dart", nil)
end)
