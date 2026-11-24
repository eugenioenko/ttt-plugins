local ttt = require("ttt")
local settings = require("ttt.settings")
local storage = require("ttt.storage")
local json = require("ttt.json")

local adapter = {
  command = {"gdb", "-q", "-nx", "-i", "dap"},
  transport = "stdio",
  languages = {"c", "cpp"},
}
local keys = {"debug.adapters.gdb"}

ttt.on_install(function()
  for _, key in ipairs(keys) do
    if settings.get(key) == nil then
      settings.set(key, adapter)
      storage.set(key, json.encode(adapter))
    end
  end
end)

ttt.on_uninstall(function()
  for _, key in ipairs(keys) do
    local owned = storage.get(key)
    if owned and owned == json.encode(settings.get(key)) then
      settings.set(key, nil)
    end
    storage.remove(key)
  end
end)
