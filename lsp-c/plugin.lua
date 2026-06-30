local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
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
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.c", nil)
end)
