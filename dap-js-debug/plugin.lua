local ttt = require("ttt")
local settings = require("ttt.settings")

local adapter = {
  provider = "jsdebug",
  command = {"js-debug-adapter", ttt.platform() == "windows" and "0" or "${socket}", "127.0.0.1"},
  transport = "listen",
  addressPattern = "^Debug server listening at (.+)$",
  fileLaunch = {program = "${file}"},
  languages = {"javascript", "javascriptreact", "typescript", "typescriptreact"},
}
local keys = {"debug.adapters.node", "debug.adapters.pwa-node"}

ttt.on_install(function()
  for _, key in ipairs(keys) do
    settings.set_default(key, adapter)
  end
end)
