# ttt Plugins

Community plugins for the [ttt terminal text editor](https://github.com/eugenioenko/ttt).

## Plugins

| Plugin | Description |
|--------|-------------|
| [cheat-sheet](cheat-sheet/) | Interactive cheat sheet browser |
| [color-picker](color-picker/) | Color picker with hex/RGB support |
| [docker-manager](docker-manager/) | Docker container management sidebar |
| [go-test-runner](go-test-runner/) | Run and view Go test results |
| [http-client](http-client/) | HTTP request client |
| [json-viewer](json-viewer/) | JSON tree viewer for the current file |
| [markdown-preview](markdown-preview/) | Markdown preview panel |
| [notepad](notepad/) | Scratchpad for quick notes |
| [spell-demo](spell-demo/) | Demo spell-checker showing the diagnostics + context-menu API |
| [todo-scanner](todo-scanner/) | Scan workspace for TODO/FIXME/HACK/NOTE comments |

## Formatters

Formatter plugins auto-configure external formatters via the `formatters` setting. Install the plugin and the formatter binary, then use `Ctrl+K F` to format or enable `editor.formatOnSave`.

| Plugin | Language(s) | Binary |
|--------|-------------|--------|
| [formatter-gofmt](formatter-gofmt/) | Go | `gofmt` |
| [formatter-prettier](formatter-prettier/) | JS, TS, JSX, TSX, CSS, HTML, JSON, Markdown, YAML | `prettier` |
| [formatter-black](formatter-black/) | Python | `black` |
| [formatter-rustfmt](formatter-rustfmt/) | Rust | `rustfmt` |
| [formatter-stylua](formatter-stylua/) | Lua | `stylua` |
| [formatter-clang-format](formatter-clang-format/) | C, C++ | `clang-format` |
| [formatter-shfmt](formatter-shfmt/) | Shell (sh, bash) | `shfmt` |

## LSP Servers

LSP plugins auto-configure language servers via the `lsp.servers` setting. Install the plugin and the language server binary to enable autocomplete, hover, and diagnostics.

| Plugin | Language | Binary |
|--------|----------|--------|
| [lsp-go](lsp-go/) | Go | `gopls` |
| [lsp-typescript](lsp-typescript/) | TypeScript/JavaScript | `typescript-language-server` |
| [lsp-python](lsp-python/) | Python | `pyright-langserver` |
| [lsp-c](lsp-c/) | C/C++ | `clangd` |
| [lsp-rust](lsp-rust/) | Rust | `rust-analyzer` |
| [lsp-lua](lsp-lua/) | Lua | `lua-language-server` |
| [lsp-zig](lsp-zig/) | Zig | `zls` |
| [lsp-vue](lsp-vue/) | Vue | `vue-language-server` |
| [lsp-svelte](lsp-svelte/) | Svelte | `svelteserver` |
| [lsp-css](lsp-css/) | CSS/SCSS/LESS | `vscode-css-language-server` |
| [lsp-html](lsp-html/) | HTML | `vscode-html-language-server` |
| [lsp-json](lsp-json/) | JSON | `vscode-json-language-server` |
| [lsp-yaml](lsp-yaml/) | YAML | `yaml-language-server` |
| [lsp-bash](lsp-bash/) | Shell | `bash-language-server` |
| [lsp-docker](lsp-docker/) | Dockerfile | `docker-langserver` |
| [lsp-tailwindcss](lsp-tailwindcss/) | Tailwind CSS | `tailwindcss-language-server` |
| [lsp-kotlin](lsp-kotlin/) | Kotlin | `kotlin-language-server` |
| [lsp-java](lsp-java/) | Java | `jdtls` |
| [lsp-ruby](lsp-ruby/) | Ruby | `ruby-lsp` |
| [lsp-dart](lsp-dart/) | Dart | `dart` |
| [lsp-elixir](lsp-elixir/) | Elixir | `elixir-ls` |
| [lsp-php](lsp-php/) | PHP | `phpactor` |
| [lsp-terraform](lsp-terraform/) | Terraform | `terraform-ls` |
| [lsp-markdown](lsp-markdown/) | Markdown | `marksman` |

## Installation

Plugins can be installed directly from ttt:

1. Open the command palette (`Ctrl+P`) and run **Plugins: Show Panel**
2. Search for a plugin and click **Install**

Or install from URL via the command palette: **Plugins: Install from URL**

```
https://github.com/eugenioenko/ttt-plugins
```

Each plugin lives in its own subdirectory with a `plugin.ttt.json` manifest.

## Creating a Plugin

See the [Plugin Documentation](https://github.com/eugenioenko/ttt/blob/main/docs/PLUGINS.md) for the full API reference.
