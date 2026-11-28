# LLVM lldb-dap for ttt

Debug C programs with LLVM's [lldb-dap](https://lldb.llvm.org/use/lldbdap.html). Install the debugger, then let the plugin configure ttt or add the settings yourself.

## Install the debugger

| Platform | Command |
| --- | --- |
| macOS | Included with recent Xcode command line tools; `xcrun -f lldb-dap` prints its path. Or `brew install llvm` and use `$(brew --prefix llvm)/bin/lldb-dap`. |
| Debian, Ubuntu | `sudo apt install lldb` |
| Fedora | `sudo dnf install lldb` |
| Arch | `sudo pacman -S lldb` |

Distributions may install the binary with a version suffix, such as `lldb-dap-18`; check with `ls /usr/bin/lldb-dap*`. Use that name, or an absolute path, as the first item of `command`. Verify with `lldb-dap --help`.

## Configure ttt

Install **LLVM LLDB Debug Adapter** from the Plugins panel, or add this to `~/.config/ttt/settings.json`:

```json
{
  "debug": {
    "adapters": {
      "lldb-dap": {
        "command": ["lldb-dap"],
        "transport": "stdio",
        "languages": ["c"],
        "markers": ["CMakeLists.txt", "Makefile"],
        "configurations": [
          {
            "name": "Launch program",
            "request": "launch",
            "program": "${workspaceFolder}/example",
            "sourcePath": "${workspaceFolder}"
          }
        ]
      }
    }
  }
}
```

The plugin keeps an existing `debug.adapters.lldb-dap` entry unchanged, and uninstalling it removes only an entry it created that you have not edited.

## Launch a program

Compile with debug symbols, for example `cc -g -O0 main.c -o example`. **Configure** in the Debug sidebar writes a **Launch program** target to `.ttt/launch.json`. Change `program` to your binary, set a breakpoint, and choose **Run & Debug**.

For a local process, use `"request": "attach"` with a numeric `pid` and the path to its executable. For a gdbserver endpoint, use `gdb-remote-host` and numeric `gdb-remote-port` with the executable path. **Detach Debugger** releases the process so it can continue running.
