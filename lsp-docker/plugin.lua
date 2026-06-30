local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.docker", {
  command = {"docker-langserver", "--stdio"},
  languages = {
    ["Dockerfile"] = "dockerfile",
  },
})

ttt.on_uninstall(function()
  settings.set("lsp.servers.docker", nil)
end)
