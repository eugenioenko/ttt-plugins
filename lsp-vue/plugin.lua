local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.vue", {
  command = {"vue-language-server", "--stdio"},
  languages = {
    [".vue"] = "vue",
  },
})

ttt.on_uninstall(function()
  settings.set("lsp.servers.vue", nil)
end)
