# GDB for ttt

Debug C and C++ programs with [GDB](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Debugger-Adapter-Protocol.html)'s built-in DAP interpreter. Install the debugger, then let the plugin configure ttt or add the settings yourself.

## Install the debugger

Use GDB 16.3 or later, built with Python support, as distribution packages are. GDB 14 can run past a startup breakpoint before configuration completes.

| Platform | Command |
| --- | --- |
| Debian, Ubuntu | `sudo apt install gdb` |
| Fedora | `sudo dnf install gdb` |
| Arch | `sudo pacman -S gdb` |

Check the version with `gdb --version`; if your distribution ships an older release, install a newer GDB from source or a backports repository. Verify the DAP interpreter with `gdb -q -nx -i dap </dev/null`. GDB does not run on Apple Silicon Macs; use CodeLLDB or lldb-dap there.

## Configure ttt

Install **GDB Debug Adapter** from the Plugins panel, or add this to `~/.config/ttt/settings.json`:

```json
{
  "debug": {
    "adapters": {
      "gdb": {
        "command": ["gdb", "-q", "-nx", "-i", "dap"],
        "transport": "stdio",
        "languages": ["c", "cpp"],
        "markers": ["CMakeLists.txt", "Makefile", "meson.build"],
        "configurations": [
          {
            "name": "Launch program",
            "request": "launch",
            "program": "${workspaceFolder}/example",
            "cwd": "${workspaceFolder}"
          },
          {"name": "Attach to process", "request": "attach", "pid": "${command:pickProcess}"}
        ]
      }
    }
  }
}
```

The plugin keeps an existing `debug.adapters.gdb` entry unchanged, and uninstalling it removes only an entry it created that you have not edited.

## Launch a program

Compile with debug symbols, for example `cc -g -O0 main.c -o example`. **Configure** in the Debug sidebar writes **Launch program** and **Attach to process** targets to `.ttt/launch.json`. Change `program` to your binary, set a gutter breakpoint, and select **Run & Debug**. **Attach to process** opens a process picker.
