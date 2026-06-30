# lsp-json

Auto-configures `vscode-json-language-server` as the JSON language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g vscode-langservers-extracted
```

## What it does

When installed, this plugin sets `lsp.servers.json` in your settings to enable LSP features (autocomplete, hover, diagnostics) for JSON files.

When uninstalled, the setting is automatically removed.
