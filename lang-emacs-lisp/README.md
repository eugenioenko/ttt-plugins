# lang-emacs-lisp

Full syntax highlighting for Emacs Lisp: `*.el`, `*.eld`, `.emacs`, `_emacs`, `.spacemacs`, `Cask`, `Eask`, `Easkfile` and related files.

Without this plugin, ttt highlights these files with its built-in Common Lisp grammar. This plugin adds Elisp-specific forms (`defcustom`, `interactive`, `defvar-local`, `?a` character literals) and highlights the names of Emacs library functions, variables and faces.

The grammar is about 800 KB, mostly lists of Emacs library names, which is why it is a plugin rather than built in.

## What it does

When installed, this plugin copies its grammar to `~/.config/ttt/grammars/` and adds it to the `editor.grammars` setting. When uninstalled, the grammar file and settings entry are removed.

Requires a ttt version with grammar plugin support.

## License

The grammar comes from [Alhadis/language-emacs-lisp](https://github.com/Alhadis/language-emacs-lisp) (ISC). See [NOTICE](NOTICE).
