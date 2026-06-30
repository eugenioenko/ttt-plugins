# lsp-tailwindcss

Auto-configures `tailwindcss-language-server` as the Tailwind CSS language server for ttt.

## Requirements

Install the language server binary:

```sh
npm install -g @tailwindcss/language-server
```

## What it does

When installed, this plugin sets `lsp.servers.tailwindcss` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Tailwind CSS files.

When uninstalled, the setting is automatically removed.
