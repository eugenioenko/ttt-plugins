# lang-git

Syntax highlighting for git commit messages and interactive rebase todo lists.

| File | Language |
|------|----------|
| `COMMIT_EDITMSG`, `MERGE_MSG`, `TAG_EDITMSG`, `SQUASH_MSG` | Git Commit |
| `git-rebase-todo` | Git Rebase |

Useful with `git config --global core.editor ttt`.

## What it does

When installed, this plugin copies its grammars to `~/.config/ttt/grammars/` and adds them to the `editor.grammars` setting. When uninstalled, the grammar files and settings entries are removed.

Requires a ttt version with grammar plugin support.

## License

The grammars come from [VS Code's git-base extension](https://github.com/microsoft/vscode/tree/main/extensions/git-base) (MIT). See [NOTICE](NOTICE).
