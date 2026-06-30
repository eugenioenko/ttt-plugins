local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.typescript", {
  command = {"typescript-language-server", "--stdio"},
  languages = {
    [".ts"] = "typescript",
    [".tsx"] = "typescriptreact",
    [".js"] = "javascript",
    [".jsx"] = "javascriptreact",
    [".mjs"] = "javascript",
    [".mts"] = "typescript",
    [".cjs"] = "javascript",
    [".cts"] = "typescript",
  },
})

ttt.on_uninstall(function()
  settings.set("lsp.servers.typescript", nil)
end)
