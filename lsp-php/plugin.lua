local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.php", {command = {"phpactor", "language-server"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.php", nil)
end)
