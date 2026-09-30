# formatter-ruff

Auto-configures [Ruff](https://docs.astral.sh/ruff/) as the formatter for Python files.

## Requirements

Install Ruff via pip:
```sh
pip install ruff
```

## Usage

Install this plugin and Ruff will be automatically configured. Format files with `Ctrl+L E` (external formatter) or enable `editor.formatOnSave` in settings.

## Settings

This plugin sets:
```json
{ "formatters": { "py": "ruff format --stdin-filename {file} -" } }
```

`--stdin-filename` lets Ruff resolve project configuration (and per-file exclusions) from the file being formatted, while `ruff format -` reads the buffer from stdin and writes the formatted result to stdout.
