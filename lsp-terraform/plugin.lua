local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set("lsp.servers.terraform", {
    command = {"terraform-ls", "serve"},
    languages = {
      [".tf"] = "terraform",
      [".tfvars"] = "terraform",
    },
  })
end)

ttt.on_uninstall(function()
  settings.set("lsp.servers.terraform", nil)
end)
