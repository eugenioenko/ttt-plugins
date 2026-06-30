# lsp-go

Auto-configures `gopls` as the Go language server for ttt.

## Requirements

Install the language server binary:

```sh
go install golang.org/x/tools/gopls@latest
```

## What it does

When installed, this plugin sets `lsp.servers.go` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Go files.

When uninstalled, the setting is automatically removed.
