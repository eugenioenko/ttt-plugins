local ttt = require("ttt")
local settings = require("ttt.settings")

local extensions = {"js", "ts", "jsx", "tsx", "css", "html", "json", "md", "yaml"}
local cmd = "prettier --stdin-filepath {file}"

ttt.on_install(function()
  for _, ext in ipairs(extensions) do
    settings.set("formatters." .. ext, cmd)
  end
end)

ttt.on_uninstall(function()
  for _, ext in ipairs(extensions) do
    settings.set("formatters." .. ext, nil)
  end
end)
