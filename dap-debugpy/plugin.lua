local ttt = require("ttt")
local settings = require("ttt.settings")

local adapter = {
  provider = "debugpy",
  command = {"${python}", "-m", "debugpy.adapter"},
  transport = "stdio",
  languages = {"python"},
}
local keys = {"debug.adapters.debugpy"}

ttt.on_install(function()
  for _, key in ipairs(keys) do
    settings.set_default(key, adapter)
  end
end)
