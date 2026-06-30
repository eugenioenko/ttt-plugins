# formatter-shfmt

Auto-configures [shfmt](https://github.com/mvdan/sh) as the formatter for shell script files.

## Requirements

Install shfmt via Go:
```sh
go install mvdan.cc/sh/v3/cmd/shfmt@latest
```

Or download a binary from [GitHub releases](https://github.com/mvdan/sh/releases).

## Usage

Install this plugin and `shfmt` will be automatically configured for `.sh` and `.bash` files. Format files with `Ctrl+K F` or enable `editor.formatOnSave` in settings.

## Settings

This plugin sets:
```json
{
  "formatters": {
    "sh": "shfmt",
    "bash": "shfmt"
  }
}
```
