local settings = require("ttt.settings")

local cmd = "prettier --stdin-filepath {file}"

settings.set("formatters.js", cmd)
settings.set("formatters.ts", cmd)
settings.set("formatters.jsx", cmd)
settings.set("formatters.tsx", cmd)
settings.set("formatters.css", cmd)
settings.set("formatters.html", cmd)
settings.set("formatters.json", cmd)
settings.set("formatters.md", cmd)
settings.set("formatters.yaml", cmd)
