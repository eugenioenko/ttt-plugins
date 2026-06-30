# lsp-docker

Auto-configures `docker-langserver` as the Dockerfile language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g dockerfile-language-server-nodejs
```

## What it does

When installed, this plugin sets `lsp.servers.docker` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Dockerfile files.

When uninstalled, the setting is automatically removed.
