# formatter-prettier

Auto-configures [Prettier](https://prettier.io/) as the formatter for JavaScript, TypeScript, CSS, HTML, JSON, Markdown, and YAML files.

## Requirements

Install Prettier via npm:
```sh
npm install -g prettier
```

## Usage

Install this plugin and Prettier will be automatically configured for all supported file types. Format files with `Ctrl+K F` or enable `editor.formatOnSave` in settings.

## Settings

This plugin sets:
```json
{
  "formatters": {
    "js": "prettier --stdin-filepath {file}",
    "ts": "prettier --stdin-filepath {file}",
    "jsx": "prettier --stdin-filepath {file}",
    "tsx": "prettier --stdin-filepath {file}",
    "css": "prettier --stdin-filepath {file}",
    "html": "prettier --stdin-filepath {file}",
    "json": "prettier --stdin-filepath {file}",
    "md": "prettier --stdin-filepath {file}",
    "yaml": "prettier --stdin-filepath {file}"
  }
}
```
