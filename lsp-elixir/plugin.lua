local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.elixir", {command = {"elixir-ls"}})

ttt.on_uninstall(function()
  settings.set("lsp.servers.elixir", nil)
end)
