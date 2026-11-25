local ttt = require("ttt")
local settings = require("ttt.settings")

ttt.on_install(function()
  settings.set_default("debug.adapters.php", {
    command = {"php-debug-adapter"},
    transport = "stdio",
    languages = {"php"},
    fileLaunch = {
      program = "${file}",
      cwd = "${workspaceFolder}",
      hostname = "127.0.0.1",
      port = 0,
      runtimeArgs = {"-dxdebug.start_with_request=yes"},
      env = {
        XDEBUG_MODE = "debug",
        XDEBUG_CONFIG = "client_host=127.0.0.1 client_port=${port}",
      },
    },
  })
end)
