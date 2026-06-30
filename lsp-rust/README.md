# lsp-rust

Auto-configures `rust-analyzer` as the Rust language server for ttt.

## Requirements

Install the language server binary:

```sh
rustup component add rust-analyzer
```

## What it does

When installed, this plugin sets `lsp.servers.rust` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Rust files.

When uninstalled, the setting is automatically removed.
