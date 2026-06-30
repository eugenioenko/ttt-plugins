# formatter-stylua

Auto-configures [StyLua](https://github.com/JohnnyMorganz/StyLua) as the formatter for Lua files.

## Requirements

Install StyLua via cargo or download from GitHub releases:
```sh
cargo install stylua
```

## Usage

Install this plugin and StyLua will be automatically configured. Format files with `Ctrl+K F` or enable `editor.formatOnSave` in settings.

## Settings

This plugin sets:
```json
{ "formatters": { "lua": "stylua -" } }
```
