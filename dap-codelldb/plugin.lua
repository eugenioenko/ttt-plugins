local ttt = require("ttt")
local settings = require("ttt.settings")

local adapter = {
  command = {"codelldb", "--port", "${port}"},
  transport = "server",
  languages = {"c", "cpp", "rust"},
}
local keys = {"debug.adapters.lldb"}

ttt.on_install(function()
  for _, key in ipairs(keys) do
    settings.set_default(key, adapter)
  end
end)
