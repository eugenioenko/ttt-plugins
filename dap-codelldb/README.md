# CodeLLDB for ttt

Debug C, C++ and Rust programs with [CodeLLDB](https://github.com/vadimcn/codelldb). Install the debugger, then let the plugin configure ttt or add the settings yourself.

## Install the debugger

Download the VSIX for your platform from the [releases page](https://github.com/vadimcn/codelldb/releases): `codelldb-linux-x64.vsix`, `codelldb-linux-arm64.vsix`, `codelldb-darwin-arm64.vsix`, `codelldb-darwin-x64.vsix` or `codelldb-win32-x64.vsix`. A VSIX is a zip archive:

```sh
mkdir -p ~/.local/share/codelldb && cd ~/.local/share/codelldb
curl -LO https://github.com/vadimcn/codelldb/releases/latest/download/codelldb-linux-x64.vsix
unzip -o codelldb-linux-x64.vsix
```

Keep the extracted layout. Add `~/.local/share/codelldb/extension/adapter` to PATH, or use the absolute path to `extension/adapter/codelldb` as the first item of `command`. Verify with `codelldb --help`.

## Configure ttt

Install **CodeLLDB Debug Adapter** from the Plugins panel, or add this to `~/.config/ttt/settings.json`:

```json
{
  "debug": {
    "adapters": {
      "lldb": {
        "command": ["codelldb", "--port", "${port}"],
        "transport": "server",
        "languages": ["c", "cpp", "rust"],
        "markers": ["Cargo.toml", "CMakeLists.txt", "Makefile"],
        "configurations": [
          {
            "name": "Launch program",
            "request": "launch",
            "program": "${workspaceFolder}/example",
            "cwd": "${workspaceFolder}"
          }
        ]
      }
    }
  }
}
```

The plugin keeps an existing `debug.adapters.lldb` entry unchanged, and uninstalling it removes only an entry it created that you have not edited.

## Launch a program

Compile with debug symbols, for example `cc -g -O0 main.c -o example`, `c++ -g -O0 main.cpp -o example` or `cargo build`. **Configure** in the Debug sidebar writes a **Launch program** target to `.ttt/launch.json`. Change `program` to your binary, such as `${workspaceFolder}/target/debug/app` for Rust, set a gutter breakpoint, and select **Run & Debug**. At a breakpoint inside a method, expand `this` in Variables to inspect its members.
