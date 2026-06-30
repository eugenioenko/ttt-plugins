# lsp-css

Auto-configures `vscode-css-language-server` as the CSS/SCSS/LESS language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g vscode-langservers-extracted
```

## What it does

When installed, this plugin sets `lsp.servers.css` in your settings to enable LSP features (autocomplete, hover, diagnostics) for CSS/SCSS/LESS files.

When uninstalled, the setting is automatically removed.
