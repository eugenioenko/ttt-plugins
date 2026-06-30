local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.html", {command = {"vscode-html-language-server", "--stdio"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.html", nil)
end)
