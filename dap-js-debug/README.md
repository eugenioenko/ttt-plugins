# JavaScript Debugger for ttt

Debug JavaScript and TypeScript with Microsoft's [js-debug](https://github.com/microsoft/vscode-js-debug), the debugger VS Code uses. Install the debugger, then let the plugin configure ttt or add the settings yourself.

## Install the debugger

Install [Node.js](https://nodejs.org), then download and extract the standalone `js-debug-dap` archive from the [releases page](https://github.com/microsoft/vscode-js-debug/releases):

```sh
mkdir -p ~/.local/share/js-debug && cd ~/.local/share/js-debug
curl -L https://github.com/microsoft/vscode-js-debug/releases/download/v1.140.1/js-debug-dap-v1.140.1.tar.gz | tar xz
```

The adapter is `js-debug/src/dapDebugServer.js`. Create an executable named `js-debug-adapter` on PATH that runs it:

```sh
#!/bin/sh
exec node "$HOME/.local/share/js-debug/js-debug/src/dapDebugServer.js" "$@"
```

Verify with `js-debug-adapter --help`. Instead of the launcher, you can replace `"js-debug-adapter"` in `command` with two items, `"node"` and the absolute path to `dapDebugServer.js`.

## Configure ttt

Install **JavaScript Debugger** from the Plugins panel, or add this to `~/.config/ttt/settings.json`:

```json
{
  "debug": {
    "adapters": {
      "node": {
        "provider": "jsdebug",
        "command": ["js-debug-adapter", "${socket}", "127.0.0.1"],
        "transport": "listen",
        "addressPattern": "^Debug server listening at (.+)$",
        "languages": ["javascript", "javascriptreact", "typescript", "typescriptreact"],
        "markers": ["package.json"],
        "fileLaunch": {"program": "${file}"},
        "configurations": [
          {"name": "Launch program", "request": "launch", "program": "${workspaceFolder}/index.js"}
        ]
      },
      "pwa-node": {
        "provider": "jsdebug",
        "command": ["js-debug-adapter", "${socket}", "127.0.0.1"],
        "transport": "listen",
        "addressPattern": "^Debug server listening at (.+)$",
        "languages": ["javascript", "javascriptreact", "typescript", "typescriptreact"],
        "fileLaunch": {"program": "${file}"}
      }
    }
  }
}
```

On Windows, replace `"${socket}"` with `"0"` in both commands. `pwa-node` is the same adapter under the type name older VS Code launch files use. The plugin keeps existing `debug.adapters.node` and `debug.adapters.pwa-node` entries unchanged, and uninstalling it removes only entries it created that you have not edited.

## Launch a program

**Debug File** launches the active file with Node. Use a saved target if your project needs a loader or a compiled JavaScript entry point.

**Configure** in the Debug sidebar writes a **Launch program** target to `.ttt/launch.json`. Change `program` to your entry point; for TypeScript, compile with source maps and point `program` to the emitted JavaScript. Set a gutter breakpoint and select **Run & Debug**.
