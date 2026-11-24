local ttt = require("ttt")
local settings = require("ttt.settings")

local adapter = {
  command = {"gdb", "-q", "-nx", "-i", "dap"},
  transport = "stdio",
  languages = {"c", "cpp"},
}
local keys = {"debug.adapters.gdb"}

ttt.on_install(function()
  for _, key in ipairs(keys) do
    settings.set_default(key, adapter)
  end
end)
