local ttt = require("ttt")
local settings = require("ttt.settings")

local extensions = {"sh", "bash"}

for _, ext in ipairs(extensions) do
  settings.set("formatters." .. ext, "shfmt")
end

ttt.on_uninstall(function()
  for _, ext in ipairs(extensions) do
    settings.set("formatters." .. ext, nil)
  end
end)
