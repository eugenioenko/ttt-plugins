local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.svelte", {
    command = {"svelteserver", "--stdio"},
    languages = {
      [".svelte"] = "svelte",
    },
  })
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.svelte", nil)
end)
