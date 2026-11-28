# NetCoreDbg for ttt

Debug .NET programs with [NetCoreDbg](https://github.com/Samsung/netcoredbg). Install the debugger, then let the plugin configure ttt or add the settings yourself.

## Install the debugger

Install the [.NET SDK](https://dotnet.microsoft.com/download) to build the project. Then download NetCoreDbg for your platform from the [releases page](https://github.com/Samsung/netcoredbg/releases): `netcoredbg-linux-amd64.tar.gz`, `netcoredbg-linux-arm64.tar.gz`, `netcoredbg-osx-arm64.zip` or `netcoredbg-win64.zip`.

```sh
mkdir -p ~/.local/share && cd ~/.local/share
curl -L https://github.com/Samsung/netcoredbg/releases/latest/download/netcoredbg-linux-amd64.tar.gz | tar xz
```

Keep the support files together. Add `~/.local/share/netcoredbg` to PATH, or use the absolute path to `netcoredbg` as the first item of `command`. Verify with `netcoredbg --version`.

## Configure ttt

Install **NetCoreDbg Debug Adapter** from the Plugins panel, or add this to `~/.config/ttt/settings.json`:

```json
{
  "debug": {
    "adapters": {
      "coreclr": {
        "command": ["netcoredbg", "--interpreter=vscode"],
        "transport": "stdio",
        "languages": ["csharp"],
        "markers": ["*.csproj", "*.sln"],
        "configurations": [
          {
            "name": "Launch Example",
            "request": "launch",
            "program": "${workspaceFolder}/bin/Debug/net8.0/Example.dll",
            "cwd": "${workspaceFolder}"
          },
          {"name": "Attach to process", "request": "attach", "processId": "${command:pickProcess}"}
        ]
      }
    }
  }
}
```

The plugin keeps an existing `debug.adapters.coreclr` entry unchanged, and uninstalling it removes only an entry it created that you have not edited.

## Launch a program

Run `dotnet build -c Debug`. Keep the portable PDB beside the DLL, and open the source tree used for the build. **Configure** in the Debug sidebar writes **Launch Example** and **Attach to process** targets to `.ttt/launch.json`. Adjust the framework and assembly name in `program`, set a source breakpoint, and select **Run & Debug**. **Attach to process** opens a process picker; use **Detach Debugger** to leave the attached process running.
