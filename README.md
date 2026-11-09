# ttt Plugins

Community plugins for the [ttt terminal text editor](https://github.com/eugenioenko/ttt).

## Plugins

| Plugin | Description | Contributed by |
|--------|-------------|----------------|
| [bookmarks](bookmarks/) | Bookmark lines from the gutter and browse them in the sidebar | |
| [cheat-sheet](cheat-sheet/) | Interactive cheat sheet browser | |
| [color-picker](color-picker/) | Color picker with hex/RGB support | |
| [docker-manager](docker-manager/) | Docker and Podman container management sidebar | |
| [go-test-runner](go-test-runner/) | Run and view Go test results | |
| [http-client](http-client/) | HTTP request client | |
| [json-viewer](json-viewer/) | JSON tree viewer for the current file | |
| [markdown-preview](markdown-preview/) | Markdown preview panel | |
| [notepad](notepad/) | Scratchpad for quick notes | |
| [omarchy-theme](omarchy-theme/) | Generate a TTT theme snapshot from the active Omarchy palette | [@danielmrdev](https://github.com/danielmrdev) |
| [pdf-viewer](https://github.com/sercanatalik/ttt-pdf) | View and search PDFs in an editor tab, with fit width and auto-reload | [@sercanatalik](https://github.com/sercanatalik) |
| [port-finder](port-finder/) | Find and kill processes listening on TCP ports | |
| [pr-review](pr-review/) | Browse GitHub pull requests, read comments, and submit reviews or approvals |
| [todo-scanner](todo-scanner/) | Scan workspace for TODO/FIXME/HACK/NOTE comments | |

## Formatters

Formatter plugins auto-configure external formatters via the `formatters` setting. Install the plugin and the formatter binary, then use `Ctrl+K F` to format or enable `editor.formatOnSave`.

| Plugin | Language(s) | Binary | Contributed by |
|--------|-------------|--------|----------------|
| [formatter-gofmt](formatter-gofmt/) | Go | `gofmt` | |
| [formatter-prettier](formatter-prettier/) | JS, TS, JSX, TSX, CSS, HTML, JSON, Markdown, YAML | `prettier` | |
| [formatter-black](formatter-black/) | Python | `black` | |
| [formatter-ruff](formatter-ruff/) | Python | `ruff` | [@RhenCloud](https://github.com/RhenCloud) |
| [formatter-rustfmt](formatter-rustfmt/) | Rust | `rustfmt` | |
| [formatter-stylua](formatter-stylua/) | Lua | `stylua` | |
| [formatter-clang-format](formatter-clang-format/) | C, C++ | `clang-format` | |
| [formatter-shfmt](formatter-shfmt/) | Shell (sh, bash) | `shfmt` | |

## Grammars

Grammar plugins add syntax highlighting for languages that ttt does not embed. Install the plugin and open a matching file; no binary is needed.

| Plugin | Language(s) | Files |
|--------|-------------|-------|
| [lang-git](lang-git/) | Git commit messages, rebase todo lists | `COMMIT_EDITMSG`, `git-rebase-todo` |
| [lang-astro](lang-astro/) | Astro | `.astro` |
| [lang-just](lang-just/) | Just | `justfile`, `.just` |
| [lang-emacs-lisp](lang-emacs-lisp/) | Emacs Lisp | `.el`, `.emacs`, `Cask`, `Eask` |

## Themes

Theme plugins contribute color themes without Lua or filesystem permissions. Requires ttt with manifest theme contributions (eugenioenko/ttt#1247). After installation, select the theme with **Switch Theme**.

| Plugin | Theme |
|--------|-------|
| [theme-bluloco](theme-bluloco/) | Bluloco Dark, Bluloco Light, Bluloco Light with dark terminal |
| [theme-catppuccin-mocha](theme-catppuccin-mocha/) | Catppuccin Mocha |

## Display languages

Language packs translate the core interface. Requires TTT 1.12.0 or later. Install a pack, choose **Change Display Language**, and restart. All language plugin names and folders use the `ttt-i18n-` prefix. Generate translations with `make languages` and validate them with `make languages-check`; see [incremental generation and maintenance](i18n/README.md).

| Plugin | Language |
|--------|----------|
| [ttt-i18n-ar](ttt-i18n-ar/) | Arabic — العربية |
| [ttt-i18n-bn](ttt-i18n-bn/) | Bengali — বাংলা |
| [ttt-i18n-cs](ttt-i18n-cs/) | Czech — Čeština |
| [ttt-i18n-da](ttt-i18n-da/) | Danish — Dansk |
| [ttt-i18n-de](ttt-i18n-de/) | German — Deutsch |
| [ttt-i18n-el](ttt-i18n-el/) | Greek — Ελληνικά |
| [ttt-i18n-es](ttt-i18n-es/) | Spanish — Español |
| [ttt-i18n-fa](ttt-i18n-fa/) | Persian — فارسی |
| [ttt-i18n-fi](ttt-i18n-fi/) | Finnish — Suomi |
| [ttt-i18n-fr](ttt-i18n-fr/) | French — Français |
| [ttt-i18n-he](ttt-i18n-he/) | Hebrew — עברית |
| [ttt-i18n-hi](ttt-i18n-hi/) | Hindi — हिन्दी |
| [ttt-i18n-hu](ttt-i18n-hu/) | Hungarian — Magyar |
| [ttt-i18n-id](ttt-i18n-id/) | Indonesian — Bahasa Indonesia |
| [ttt-i18n-it](ttt-i18n-it/) | Italian — Italiano |
| [ttt-i18n-ja](ttt-i18n-ja/) | Japanese — 日本語 |
| [ttt-i18n-ko](ttt-i18n-ko/) | Korean — 한국어 |
| [ttt-i18n-nb](ttt-i18n-nb/) | Norwegian Bokmål — Norsk bokmål |
| [ttt-i18n-nl](ttt-i18n-nl/) | Dutch — Nederlands |
| [ttt-i18n-pl](ttt-i18n-pl/) | Polish — Polski |
| [ttt-i18n-pt-br](ttt-i18n-pt-br/) | Brazilian Portuguese — Português (Brasil) |
| [ttt-i18n-ro](ttt-i18n-ro/) | Romanian — Română |
| [ttt-i18n-ru](ttt-i18n-ru/) | Russian — Русский |
| [ttt-i18n-sl](ttt-i18n-sl/) | Slovenian — Slovenščina |
| [ttt-i18n-sv](ttt-i18n-sv/) | Swedish — Svenska |
| [ttt-i18n-th](ttt-i18n-th/) | Thai — ไทย |
| [ttt-i18n-tr](ttt-i18n-tr/) | Turkish — Türkçe |
| [ttt-i18n-uk](ttt-i18n-uk/) | Ukrainian — Українська |
| [ttt-i18n-vi](ttt-i18n-vi/) | Vietnamese — Tiếng Việt |
| [ttt-i18n-zh-cn](ttt-i18n-zh-cn/) | Simplified Chinese (mainland China) — 简体中文 |
| [ttt-i18n-zh-tw](ttt-i18n-zh-tw/) | Traditional Chinese (Taiwan) — 繁體中文 |

## LSP Servers

LSP plugins auto-configure language servers via the `lsp.servers` setting. Install the plugin and server binary to enable supported LSP features; see each plugin's README for capabilities and limitations.

| Plugin | Language | Binary | Contributed by |
|--------|----------|--------|----------------|
| [lsp-go](lsp-go/) | Go | `gopls` | |
| [lsp-typescript](lsp-typescript/) | TypeScript/JavaScript (TS 6 and earlier) | `typescript-language-server` | |
| [lsp-typescript-native](lsp-typescript-native/) | TypeScript/JavaScript (TS 7+) | `tsc --lsp --stdio` | [@danielmrdev](https://github.com/danielmrdev) |
| [lsp-python](lsp-python/) | Python | `pyright-langserver` | |
| [lsp-ruff](lsp-ruff/) | Python | `ruff` | [@RhenCloud](https://github.com/RhenCloud) |
| [lsp-c](lsp-c/) | C/C++ | `clangd` | |
| [lsp-rust](lsp-rust/) | Rust | `rust-analyzer` | |
| [lsp-lua](lsp-lua/) | Lua | `lua-language-server` | |
| [lsp-zig](lsp-zig/) | Zig | `zls` | |
| [lsp-vue](lsp-vue/) | Vue | `vue-language-server` | |
| [lsp-svelte](lsp-svelte/) | Svelte | `svelteserver` | |
| [lsp-css](lsp-css/) | CSS/SCSS/LESS | `vscode-css-language-server` | |
| [lsp-html](lsp-html/) | HTML | `vscode-html-language-server` | |
| [lsp-json](lsp-json/) | JSON | `vscode-json-language-server` | |
| [lsp-yaml](lsp-yaml/) | YAML | `yaml-language-server` | |
| [lsp-bash](lsp-bash/) | Shell | `bash-language-server` | |
| [lsp-docker](lsp-docker/) | Dockerfile | `docker-langserver` | |
| [lsp-tailwindcss](lsp-tailwindcss/) | Tailwind CSS | `tailwindcss-language-server` | |
| [lsp-kotlin](lsp-kotlin/) | Kotlin | `kotlin-language-server` | |
| [lsp-java](lsp-java/) | Java | `jdtls` | |
| [lsp-ruby](lsp-ruby/) | Ruby | `ruby-lsp` | |
| [lsp-dart](lsp-dart/) | Dart | `dart` | |
| [lsp-elixir](lsp-elixir/) | Elixir | `elixir-ls` | |
| [lsp-php](lsp-php/) | PHP | `phpactor` | |
| [lsp-terraform](lsp-terraform/) | Terraform | `terraform-ls` | |
| [lsp-markdown](lsp-markdown/) | Markdown | `marksman` | |
| [lsp-haskell](lsp-haskell/) | Haskell | `haskell-language-server-wrapper` | |

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

See the [Plugin Authoring Guide](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugin-authoring.md) for the full API reference and [Testing Plugins](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugin-testing.md) for the headless test harness. Agents working in this repository should read [AGENT.md](AGENT.md).
