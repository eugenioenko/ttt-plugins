# LLVM lldb-dap for ttt

Install **LLVM LLDB Debug Adapter** in the Plugins panel. Install LLVM’s [lldb-dap executable](https://lldb.llvm.org/use/lldbdap.html) and put its bin directory on PATH. If the distribution installs a versioned executable, set the command in `debug.adapters.lldb-dap` to that name. The plugin uses the LLVM adapter over stdio.

Compile a C program with debug symbols, for example `cc -g -O0 main.c -o example`. Save this configuration as `.ttt/launch.json`, set a breakpoint, and choose **Run & Debug**.

```json
{
  "configurations": [
    {
      "name": "Launch example",
      "type": "lldb-dap",
      "request": "launch",
      "program": "${workspaceFolder}/example",
      "sourcePath": "${workspaceFolder}"
    }
  ]
}
```

For a local process, use `"request": "attach"` with a numeric `pid` and the path to its executable. For a gdbserver endpoint, use `gdb-remote-host` and numeric `gdb-remote-port` with the executable path. **Detach Debugger** releases the process so it can continue running.
