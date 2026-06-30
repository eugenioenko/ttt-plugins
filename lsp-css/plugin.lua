local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.css", {
    command = {"vscode-css-language-server", "--stdio"},
    languages = {
      [".css"] = "css",
      [".scss"] = "scss",
      [".less"] = "less",
    },
  })
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.css", nil)
end)
