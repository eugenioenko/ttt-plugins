local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.bash", {
  command = {"bash-language-server", "start"},
  languages = {
    [".sh"] = "sh",
    [".bash"] = "bash",
  },
})

ttt.on_uninstall(function()
  settings.set("lsp.servers.bash", nil)
end)
