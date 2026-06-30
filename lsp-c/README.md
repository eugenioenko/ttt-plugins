# lsp-c

Auto-configures `clangd` as the C/C++ language server for ttt.

## Requirements

Install the language server binary:

Install via your system package manager (e.g. `apt install clangd` or `brew install llvm`)

## What it does

When installed, this plugin sets `lsp.servers.c` in your settings to enable LSP features (autocomplete, hover, diagnostics) for C/C++ files.

When uninstalled, the setting is automatically removed.
