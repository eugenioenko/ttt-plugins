local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.dart", {command = {"dart", "language-server", "--protocol=lsp"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.dart", nil)
end)
