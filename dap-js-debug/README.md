# JavaScript Debugger for ttt

Install **JavaScript Debugger** from the Plugins panel to register `node`, `pwa-node` in `debug.adapters`. The plugin supplies adapter settings. Install the debugger separately.

## Requirements

Install Node.js and the [standalone js-debug distribution](https://github.com/microsoft/vscode-js-debug/releases). Verify your launcher with `js-debug-adapter --help`. If your installation provides only `dapDebugServer.js`, replace the first item of each adapter’s `command` with two items, `"node"` and the absolute path to `dapDebugServer.js`. Keep the socket and host arguments.

## Launch a program

Use an existing JavaScript entry point. For TypeScript, compile with source maps and point `program` to the emitted JavaScript. Save this target in `.ttt/launch.json`, set a gutter breakpoint, and select **Run & Debug** in the Debug sidebar.

```json
{
  "configurations": [
    {
      "name": "Launch JavaScript example",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/app.js"
    }
  ]
}
```

You can customize the adapter in user `settings.json`. Installation preserves existing entries. Uninstall removes only entries this plugin created that still match its installed settings.
