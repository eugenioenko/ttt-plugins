# lsp-java

Auto-configures `jdtls` as the Java language server for ttt.

## Requirements

Install the language server binary:

```sh
See https://github.com/eclipse-jdtls/eclipse.jdt.ls for installation instructions
```

## What it does

When installed, this plugin sets `lsp.servers.java` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Java files.

When uninstalled, the setting is automatically removed.
