# lang-just

Syntax highlighting for [just](https://github.com/casey/just) command runner files: `justfile`, `Justfile`, `.justfile` and `*.just`.

Recipe bodies that use a shebang for Python, Ruby, Perl, JavaScript or TypeScript are highlighted with ttt's built-in grammars for those languages.

## What it does

When installed, this plugin copies its grammar to `~/.config/ttt/grammars/` and adds it to the `editor.grammars` setting. When uninstalled, the grammar file and settings entry are removed.

Requires a ttt version with grammar plugin support.

## License

The grammar comes from [nefrob/vscode-just](https://github.com/nefrob/vscode-just) (MIT). See [NOTICE](NOTICE).
