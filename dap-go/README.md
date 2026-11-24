# Delve for ttt

Install **Delve Debug Adapter** from the Plugins panel to register `go` in `debug.adapters`. The plugin supplies adapter settings. Install the debugger separately.

## Requirements

Install [Delve](https://github.com/go-delve/delve) with `go install github.com/go-delve/delve/cmd/dlv@latest`. Add the Go bin directory to PATH and verify with `dlv version`.

## Launch a program

Open a Go module with a main package at its root. Save this target in `.ttt/launch.json`, set a gutter breakpoint, and select **Run & Debug** in the Debug sidebar.

```json
{
  "configurations": [
    {
      "name": "Launch Go example",
      "type": "go",
      "request": "launch",
      "program": "${workspaceFolder}"
    }
  ]
}
```

You can customize the adapter in user `settings.json`. Installation preserves existing entries. Uninstall removes only entries this plugin created that still match its installed settings.
