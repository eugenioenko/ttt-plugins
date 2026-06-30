local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.c", {
  command = {"clangd"},
  languages = {
    [".c"] = "c",
    [".h"] = "c",
    [".cpp"] = "cpp",
    [".hpp"] = "cpp",
    [".cc"] = "cpp",
    [".cxx"] = "cpp",
  },
})

ttt.on_uninstall(function()
  settings.set("lsp.servers.c", nil)
end)
