local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.php", {command = {"phpactor", "language-server"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.php", nil)
end)
