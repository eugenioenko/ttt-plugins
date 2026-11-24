# Python Debugger for ttt

Install **Python Debugger** from the Plugins panel to register `debugpy` in `debug.adapters`. The plugin supplies adapter settings. Install the debugger separately.

## Requirements

Install [debugpy](https://github.com/microsoft/debugpy) in the interpreter used for debugging with `python -m pip install debugpy`. Verify with `python -m debugpy --version`. ttt uses the workspace’s `.venv` when available. Set `python` on a launch target to select another interpreter.

## Launch a program

Use an existing Python entry point. Save this target in `.ttt/launch.json`, set a gutter breakpoint, and select **Run & Debug** in the Debug sidebar.

```json
{
  "configurations": [
    {
      "name": "Launch Python example",
      "type": "debugpy",
      "request": "launch",
      "program": "${workspaceFolder}/main.py"
    }
  ]
}
```

You can customize the adapter in user `settings.json`. Installation preserves existing entries. Uninstall removes only entries this plugin created that still match its installed settings.
