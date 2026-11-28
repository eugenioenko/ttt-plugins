# Delve for ttt

Debug Go programs with [Delve](https://github.com/go-delve/delve). Install the debugger, then let the plugin configure ttt or add the settings yourself.

## Install the debugger

```sh
go install github.com/go-delve/delve/cmd/dlv@latest
```

This puts `dlv` in `$(go env GOPATH)/bin`, usually `~/go/bin`. Add that directory to PATH, or use the absolute path as the first item of `command`. On macOS, `brew install delve` also works. Verify with `dlv version`.

## Configure ttt

Install **Delve Debug Adapter** from the Plugins panel, or add this to `~/.config/ttt/settings.json`:

```json
{
  "debug": {
    "adapters": {
      "go": {
        "provider": "delve",
        "command": ["dlv", "dap", "--listen=unix:${socket}"],
        "transport": "listen",
        "addressPattern": "^DAP server listening at: (.+)$",
        "languages": ["go"],
        "markers": ["go.mod"],
        "fileLaunch": {"program": "${fileDirname}"},
        "fileLaunchOverrides": [{"pattern": "*_test.go", "arguments": {"mode": "test"}}],
        "configurations": [
          {"name": "Launch package", "request": "launch", "program": "${workspaceFolder}"},
          {
            "name": "Debug tests",
            "request": "launch",
            "mode": "test",
            "program": "${workspaceFolder}"
          }
        ]
      }
    }
  }
}
```

The plugin keeps an existing `debug.adapters.go` entry unchanged, and uninstalling it removes only an entry it created that you have not edited.

## Launch a program

**Debug File** launches the package containing the active Go file. For a `_test.go` file it runs the package in test mode.

**Configure** in the Debug sidebar writes the adapter's `configurations` to `.ttt/launch.json`: **Launch package** runs the main package at the workspace root and **Debug tests** runs its tests. Point `program` at another package, such as `${workspaceFolder}/cmd/app`, when needed. Set a gutter breakpoint and select **Run & Debug**.
