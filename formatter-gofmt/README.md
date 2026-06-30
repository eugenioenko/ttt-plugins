# formatter-gofmt

Auto-configures [gofmt](https://pkg.go.dev/cmd/gofmt) as the formatter for Go files.

## Requirements

`gofmt` is included with the Go toolchain. Install Go from [go.dev](https://go.dev/dl/).

## Usage

Install this plugin and `gofmt` will be automatically configured. Format files with `Ctrl+K F` or enable `editor.formatOnSave` in settings.

## Settings

This plugin sets:
```json
{ "formatters": { "go": "gofmt" } }
```
