local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.json", {
    command = {"vscode-json-language-server", "--stdio"},
    languages = {
      [".json"] = "json",
      [".jsonc"] = "jsonc",
    },
  })
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.json", nil)
end)
