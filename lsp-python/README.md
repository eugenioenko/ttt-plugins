# lsp-python

Auto-configures `pyright-langserver` as the Python language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g pyright
```

## What it does

When installed, this plugin sets `lsp.servers.python` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Python files.

When uninstalled, the setting is automatically removed.
