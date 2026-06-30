local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.markdown", {command = {"marksman", "server"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.markdown", nil)
end)
