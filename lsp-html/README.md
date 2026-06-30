# lsp-html

Auto-configures `vscode-html-language-server` as the HTML language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g vscode-langservers-extracted
```

## What it does

When installed, this plugin sets `lsp.servers.html` in your settings to enable LSP features (autocomplete, hover, diagnostics) for HTML files.

When uninstalled, the setting is automatically removed.
