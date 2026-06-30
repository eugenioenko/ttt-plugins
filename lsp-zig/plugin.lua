local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.zig", {command = {"zls"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.zig", nil)
end)
