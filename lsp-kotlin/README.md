# lsp-kotlin

Auto-configures `kotlin-language-server` as the Kotlin language server for ttt.

## Requirements

Install the language server binary:

```sh
See https://github.com/fwcd/kotlin-language-server for installation instructions
```

## What it does

When installed, this plugin sets `lsp.servers.kotlin` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Kotlin files.

When uninstalled, the setting is automatically removed.
