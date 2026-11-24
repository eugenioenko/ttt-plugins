# CodeLLDB for ttt

Install **CodeLLDB Debug Adapter** from the Plugins panel to register `lldb` in `debug.adapters`. The plugin supplies adapter settings. Install the debugger separately.

## Requirements

Download the [CodeLLDB VSIX for your platform](https://github.com/vadimcn/codelldb/releases). Extract the archive, keep its directory layout, and add its `extension/adapter` directory to PATH. Run `codelldb --help` to verify.

## Launch a program

Compile your C program with debug symbols, for example `cc -g -O0 main.c -o example`. Save this target in `.ttt/launch.json`, set a gutter breakpoint, and select **Run & Debug** in the Debug sidebar.

```json
{
  "configurations": [
    {
      "name": "Launch C example",
      "type": "lldb",
      "request": "launch",
      "program": "${workspaceFolder}/example",
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

You can customize the adapter in user `settings.json`. Installation preserves existing entries. Uninstall removes only entries this plugin created that still match its installed settings.
