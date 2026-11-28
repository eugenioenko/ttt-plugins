# Python Debugger for ttt

Debug Python programs with [debugpy](https://github.com/microsoft/debugpy). Install the debugger, then let the plugin configure ttt or add the settings yourself.

## Install the debugger

Install debugpy into the Python environment your project uses. ttt uses the workspace's `.venv` when it exists:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install debugpy
```

Skip the first line if the project already has a `.venv`. On Windows, use `.venv\Scripts\python`. Verify with `.venv/bin/python -m debugpy --version`. Set `python` on a launch target to use another interpreter.

## Configure ttt

Install **Python Debugger** from the Plugins panel, or add this to `~/.config/ttt/settings.json`:

```json
{
  "debug": {
    "adapters": {
      "debugpy": {
        "provider": "debugpy",
        "command": ["${python}", "-m", "debugpy.adapter"],
        "transport": "stdio",
        "languages": ["python"],
        "markers": ["pyproject.toml", "requirements.txt", "setup.py"],
        "fileLaunch": {"program": "${file}"},
        "configurations": [
          {"name": "Launch main.py", "request": "launch", "program": "${workspaceFolder}/main.py"}
        ]
      }
    }
  }
}
```

The plugin keeps an existing `debug.adapters.debugpy` entry unchanged, and uninstalling it removes only an entry it created that you have not edited.

## Launch a program

**Debug File** launches the active Python file using the workspace interpreter.

**Configure** in the Debug sidebar writes a **Launch main.py** target to `.ttt/launch.json`. Change `program` to your entry point, set a gutter breakpoint, and select **Run & Debug**.
