local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.tailwindcss", {command = {"tailwindcss-language-server", "--stdio"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.tailwindcss", nil)
end)
