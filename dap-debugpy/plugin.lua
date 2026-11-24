local ttt = require("ttt")
local settings = require("ttt.settings")
local storage = require("ttt.storage")
local json = require("ttt.json")

local adapter = {
  provider = "debugpy",
  command = {"${python}", "-m", "debugpy.adapter"},
  transport = "stdio",
  languages = {"python"},
}
local keys = {"debug.adapters.debugpy"}

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
