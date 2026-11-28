# PHP and Xdebug for ttt

Debug PHP with [Xdebug](https://xdebug.org) through the [PHP Debug adapter](https://github.com/xdebug/vscode-php-debug). Install the debugger, then let the plugin configure ttt or add the settings yourself.

## Install the debugger

Install PHP CLI with Xdebug, and [Node.js](https://nodejs.org):

| Platform | Command |
| --- | --- |
| Debian, Ubuntu | `sudo apt install php-cli php-xdebug nodejs` |
| Fedora | `sudo dnf install php-cli php-pecl-xdebug3 nodejs` |
| macOS | `brew install php node`, then `pecl install xdebug` |

Check that `php --ri xdebug` shows the extension. Then download and extract the adapter VSIX, a zip archive, from the [releases page](https://github.com/xdebug/vscode-php-debug/releases):

```sh
mkdir -p ~/.local/share/php-debug && cd ~/.local/share/php-debug
curl -LO https://github.com/xdebug/vscode-php-debug/releases/download/v1.40.2/php-debug-1.40.2.vsix
unzip -o php-debug-1.40.2.vsix
```

Create an executable named `php-debug-adapter` on PATH that runs it:

```sh
#!/bin/sh
exec node "$HOME/.local/share/php-debug/extension/out/phpDebug.js" "$@"
```

## Configure ttt

Install **PHP Debug Adapter** from the Plugins panel, or add this to `~/.config/ttt/settings.json`:

```json
{
  "debug": {
    "adapters": {
      "php": {
        "command": ["php-debug-adapter"],
        "transport": "stdio",
        "languages": ["php"],
        "markers": ["composer.json"],
        "fileLaunch": {
          "program": "${file}",
          "cwd": "${workspaceFolder}",
          "hostname": "127.0.0.1",
          "port": 0,
          "runtimeArgs": ["-dxdebug.start_with_request=yes"],
          "env": {
            "XDEBUG_CONFIG": "client_host=127.0.0.1 client_port=${port}",
            "XDEBUG_MODE": "debug"
          }
        },
        "configurations": [
          {"name": "Listen for Xdebug", "request": "launch", "hostname": "127.0.0.1", "port": 9003}
        ]
      }
    }
  }
}
```

The plugin keeps an existing `debug.adapters.php` entry unchanged, and uninstalling it removes only an entry it created that you have not edited.

## Launch a program

Open a saved PHP script and select **Debug File**. The plugin starts the CLI with step debugging and uses an available loopback port for Xdebug.

## Listen for requests

**Configure** in the Debug sidebar writes this **Listen for Xdebug** target to `.ttt/launch.json`. Use it to debug PHP processes started outside the editor.

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
