# formatter-clang-format

Auto-configures [clang-format](https://clang.llvm.org/docs/ClangFormat.html) as the formatter for C and C++ files.

## Requirements

Install clang-format via your package manager:
```sh
# Debian/Ubuntu
sudo apt install clang-format

# macOS
brew install clang-format
```

## Usage

Install this plugin and `clang-format` will be automatically configured for `.c`, `.cpp`, `.h`, and `.hpp` files. Format files with `Ctrl+K F` or enable `editor.formatOnSave` in settings.

## Settings

This plugin sets:
```json
{
  "formatters": {
    "c": "clang-format",
    "cpp": "clang-format",
    "h": "clang-format",
    "hpp": "clang-format"
  }
}
```
