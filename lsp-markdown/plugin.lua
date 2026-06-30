local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.markdown", {command = {"marksman", "server"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.markdown", nil)
end)
