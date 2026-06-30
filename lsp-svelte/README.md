# lsp-svelte

Auto-configures `svelteserver` as the Svelte language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g svelte-language-server
```

## What it does

When installed, this plugin sets `lsp.servers.svelte` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Svelte files.

When uninstalled, the setting is automatically removed.
