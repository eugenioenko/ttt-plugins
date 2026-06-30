local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.svelte", {
  command = {"svelteserver", "--stdio"},
  languages = {
    [".svelte"] = "svelte",
  },
})

ttt.on_uninstall(function()
  settings.set("lsp.servers.svelte", nil)
end)
