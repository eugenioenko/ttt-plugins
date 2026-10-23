# lsp-typescript-native

Auto-configures TypeScript 7's built-in language server (`tsc --lsp --stdio`) for TypeScript and JavaScript in ttt.

## Requirements

- TypeScript 7 or later installed, with `tsc` available on `PATH`.
- A ttt release that includes the native LSP fix from [#816](https://github.com/eugenioenko/ttt/pull/816).

## What it does

When installed, this plugin sets `lsp.servers.typescript` to use `tsc --lsp --stdio`. Hover and other request-based LSP features work.

TypeScript 7 reports diagnostics through LSP pull diagnostics (`textDocument/diagnostic`), which ttt does not support yet ([#761](https://github.com/eugenioenko/ttt/issues/761)). Inline diagnostics are unavailable until ttt adds support.

When uninstalled, the setting is automatically removed.

For TypeScript 6 and earlier, use [lsp-typescript](../lsp-typescript/), which configures `typescript-language-server`. Both plugins configure `lsp.servers.typescript`; install only one. Installing both overwrites the setting, and uninstalling either removes it.
