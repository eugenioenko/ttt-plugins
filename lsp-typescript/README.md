# lsp-typescript

Auto-configures `typescript-language-server` as the TypeScript/JavaScript language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g typescript-language-server typescript@6
```

> **Note:** TypeScript 7+ removed `tsserver`, which this plugin requires. Use TypeScript 6 or earlier.

## What it does

When installed, this plugin sets `lsp.servers.typescript` in your settings to enable LSP features (autocomplete, hover, diagnostics) for TypeScript/JavaScript files.

When uninstalled, the setting is automatically removed.
