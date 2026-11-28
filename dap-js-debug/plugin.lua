local ttt = require("ttt")
local settings = require("ttt.settings")

local function adapter()
  return {
    provider = "jsdebug",
    command = {"js-debug-adapter", ttt.platform() == "windows" and "0" or "${socket}", "127.0.0.1"},
    transport = "listen",
    addressPattern = "^Debug server listening at (.+)$",
    fileLaunch = {program = "${file}"},
    languages = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
  }
end

local node = adapter()
node.markers = {"package.json"}
node.configurations = {
  {name = "Launch program", request = "launch", program = "${workspaceFolder}/index.js"},
}

ttt.on_install(function()
  settings.set_default("debug.adapters.node", node)
  settings.set_default("debug.adapters.pwa-node", adapter())
end)
