local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.java", {command = {"jdtls"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.java", nil)
end)
