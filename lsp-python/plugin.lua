local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.python", {command = {"pyright-langserver", "--stdio"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.python", nil)
end)
