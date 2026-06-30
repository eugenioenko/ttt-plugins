# lsp-terraform

Auto-configures `terraform-ls` as the Terraform language server for ttt.

## Requirements

Install the language server binary:

```sh
See https://github.com/hashicorp/terraform-ls for installation instructions
```

## What it does

When installed, this plugin sets `lsp.servers.terraform` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Terraform files.

When uninstalled, the setting is automatically removed.
