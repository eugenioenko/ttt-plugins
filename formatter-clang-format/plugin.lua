local ttt = require("ttt")
local settings = require("ttt.settings")

local extensions = {"c", "cpp", "h", "hpp"}

for _, ext in ipairs(extensions) do
  settings.set("formatters." .. ext, "clang-format")
end

ttt.on_uninstall(function()
  for _, ext in ipairs(extensions) do
    settings.set("formatters." .. ext, nil)
  end
end)
