local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.elixir", {command = {"elixir-ls"}})
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.elixir", nil)
end)
