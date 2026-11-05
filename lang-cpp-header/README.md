# lang-cpp-header

Syntax highlighting for `.h` header files.

ttt's built-in grammars already cover `.hpp`, `.hh` and `.hxx`, but leave `.h` as plain text because it is shared by C and C++. This plugin highlights `.h` files with ttt's built-in C++ grammar, which also reads well for C headers.

## What it does

When installed, this plugin copies its grammar to `~/.config/ttt/grammars/` and adds it to the `editor.grammars` setting. When uninstalled, the grammar file and settings entry are removed.

The grammar is a small wrapper that includes the embedded `source.cpp` grammar, so highlighting stays in sync with ttt's C++ support.

Requires a ttt version with grammar plugin support.

## License

MIT. The wrapped C++ grammar ships with ttt.
