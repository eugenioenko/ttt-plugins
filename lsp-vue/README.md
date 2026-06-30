# lsp-vue

Auto-configures `vue-language-server` as the Vue language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g @vue/language-server
```

## What it does

When installed, this plugin sets `lsp.servers.vue` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Vue files.

When uninstalled, the setting is automatically removed.
