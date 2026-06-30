local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.lua", {command = {"lua-language-server"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.lua", nil)
end)
