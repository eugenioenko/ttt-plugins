local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.zig", {command = {"zls"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.zig", nil)
end)
