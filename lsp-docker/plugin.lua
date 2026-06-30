local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.docker", {
    command = {"docker-langserver", "--stdio"},
    languages = {
      ["Dockerfile"] = "dockerfile",
    },
  })
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.docker", nil)
end)
