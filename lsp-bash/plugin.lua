local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.bash", {
    command = {"bash-language-server", "start"},
    languages = {
      [".sh"] = "sh",
      [".bash"] = "bash",
    },
  })
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.bash", nil)
end)
