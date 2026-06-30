local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.vue", {
    command = {"vue-language-server", "--stdio"},
    languages = {
      [".vue"] = "vue",
    },
  })
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.vue", nil)
end)
