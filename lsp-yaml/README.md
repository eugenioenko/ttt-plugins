# lsp-yaml

Auto-configures `yaml-language-server` as the YAML language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g yaml-language-server
```

## What it does

When installed, this plugin sets `lsp.servers.yaml` in your settings to enable LSP features (autocomplete, hover, diagnostics) for YAML files.

When uninstalled, the setting is automatically removed.
