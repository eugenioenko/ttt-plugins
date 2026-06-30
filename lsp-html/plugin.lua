local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.html", {command = {"vscode-html-language-server", "--stdio"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.html", nil)
end)
