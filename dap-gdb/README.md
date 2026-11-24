# GDB for ttt

Install **GDB Debug Adapter** from the Plugins panel to register `gdb` in `debug.adapters`. The plugin supplies adapter settings. Install the debugger separately.

## Requirements

Use GDB 16.3 or later. GDB 14 can run past a startup breakpoint before configuration completes. Install a Python-enabled build of [GNU GDB](https://sourceware.org/gdb/current/onlinedocs/gdb.html/Debugger-Adapter-Protocol.html) with the DAP interpreter. Run `gdb -q -nx -i dap </dev/null` to verify the interpreter is available.

## Launch a program

Compile your C program with debug symbols, for example `cc -g -O0 main.c -o example`. Save this target in `.ttt/launch.json`, set a gutter breakpoint, and select **Run & Debug** in the Debug sidebar.

```json
{
  "configurations": [
    {
      "name": "Launch C example",
      "type": "gdb",
      "request": "launch",
      "program": "${workspaceFolder}/example",
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

You can customize the adapter in user `settings.json`. Installation preserves existing entries. Uninstall removes only entries this plugin created that still match its installed settings.
