# lsp-bash

Auto-configures `bash-language-server` as the Shell language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g bash-language-server
```

## What it does

When installed, this plugin sets `lsp.servers.bash` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Shell files.

When uninstalled, the setting is automatically removed.
