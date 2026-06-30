# formatter-rustfmt

Auto-configures [rustfmt](https://github.com/rust-lang/rustfmt) as the formatter for Rust files.

## Requirements

`rustfmt` is included with the Rust toolchain. Install Rust via [rustup](https://rustup.rs/):
```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Usage

Install this plugin and `rustfmt` will be automatically configured. Format files with `Ctrl+K F` or enable `editor.formatOnSave` in settings.

## Settings

This plugin sets:
```json
{ "formatters": { "rs": "rustfmt" } }
```
