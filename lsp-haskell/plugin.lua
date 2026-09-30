local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.haskell", {
    command = {"haskell-language-server-wrapper", "--lsp"},
    languages = {
      [".hs"] = "haskell",
      [".lhs"] = "lhaskell",
    },
  })
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.haskell", nil)
end)
