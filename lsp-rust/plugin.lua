local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.rust", {command = {"rust-analyzer"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.rust", nil)
end)
