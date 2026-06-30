# formatter-black

Auto-configures [Black](https://black.readthedocs.io/) as the formatter for Python files.

## Requirements

Install Black via pip:
```sh
pip install black
```

## Usage

Install this plugin and Black will be automatically configured. Format files with `Ctrl+K F` or enable `editor.formatOnSave` in settings.

## Settings

This plugin sets:
```json
{ "formatters": { "py": "black -q -" } }
```
