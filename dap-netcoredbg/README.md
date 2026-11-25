# NetCoreDbg for ttt

Install **NetCoreDbg Debug Adapter** in the Plugins panel. Install the [.NET SDK](https://dotnet.microsoft.com/download) to build the project and extract [NetCoreDbg](https://github.com/Samsung/netcoredbg/releases) for your platform. Keep its support files together and add the directory containing `netcoredbg` to PATH.

Run `dotnet build -c Debug`. Keep the portable PDB beside the DLL, and open the source tree used for the build. For a .NET 8 project named Example, save the following as `.ttt/launch.json` and select **Run & Debug**. Adjust the framework and assembly name for your project.

```json
{
  "configurations": [
    {
      "name": "Launch Example",
      "type": "coreclr",
      "request": "launch",
      "program": "${workspaceFolder}/bin/Debug/net8.0/Example.dll",
      "cwd": "${workspaceFolder}"
    },
    {
      "name": "Attach to Example",
      "type": "coreclr",
      "request": "attach",
      "processId": 12345
    }
  ]
}
```

Replace 12345 with the running managed process ID. Set a source breakpoint and use **Detach Debugger** to leave the attached process running.
