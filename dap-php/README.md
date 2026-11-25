# PHP and Xdebug for ttt

Install **PHP Debug Adapter** in the Plugins panel. Install PHP CLI with [Xdebug](https://xdebug.org/docs/install), and Node.js. Check that `php --ri xdebug` shows the extension.

Download the [PHP Debug adapter VSIX](https://github.com/xdebug/vscode-php-debug/releases), extract it, and keep the extracted directory intact. Create an executable named `php-debug-adapter` on PATH with the following contents, substituting the absolute path to your extracted directory.

```sh
#!/bin/sh
exec node "/absolute/path/to/extension/out/phpDebug.js" "$@"
```

Open a saved PHP script and select **Debug File**. The plugin starts the CLI with step debugging and uses an available loopback port for Xdebug.

## Listen for requests

Use this configuration in `.ttt/launch.json` to debug PHP processes started outside the editor.

```json
{
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "hostname": "127.0.0.1",
      "port": 9003
    }
  ]
}
```

Set a breakpoint and select **Run & Debug**. From the same machine, run a script with Xdebug enabled:

```sh
XDEBUG_MODE=debug php -dxdebug.start_with_request=yes -dxdebug.client_host=127.0.0.1 -dxdebug.client_port=9003 main.php
```

Each invocation connects back to the listener. Continue past the breakpoint to finish that request. Stop the session in ttt when you are done.
