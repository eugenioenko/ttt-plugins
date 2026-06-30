local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.python", {command = {"pyright-langserver", "--stdio"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.python", nil)
end)
