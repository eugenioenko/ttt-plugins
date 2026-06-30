local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.lua", {command = {"lua-language-server"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.lua", nil)
end)
