local ttt = require("ttt")
local settings = require("ttt.settings")

settings.set("lsp.servers.terraform", {
  command = {"terraform-ls", "serve"},
  languages = {
    [".tf"] = "terraform",
    [".tfvars"] = "terraform",
  },
})

ttt.on_uninstall(function()
  settings.set("lsp.servers.terraform", nil)
end)
