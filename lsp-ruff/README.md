# lsp-ruff

Auto-configures [Ruff](https://docs.astral.sh/ruff/) as the Python language server for ttt.

## Requirements

Install the Ruff binary:

```sh
pip install ruff
```

or with uv:

```sh
uv tool install ruff
```

## What it does

When installed, this plugin sets `lsp.servers.python` in your settings to enable LSP features (autocomplete, hover, diagnostics) for Python files.

When uninstalled, the setting is automatically removed.

## Note

Ruff and [lsp-python](../lsp-python/) both provide the `python` language server. Only enable one of them.
