local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.rust", {command = {"rust-analyzer"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.rust", nil)
end)
