# PR Review

Run **PR Review: Show**. Enter a GitHub repository URL, `owner/repo`, or a pull request URL, then
choose **Load**. Activate a PR to open its description and multi-file diff in
ttt's native detail view. The header's **⋮** switches between open and closed PRs.
**Comments (N)** opens a tab with discussion comments, review messages, and inline
review threads. Each is a collapsible row tagged `Comment`, `Open` or `Resolved`;
only open threads start expanded, with **Reply** and **Resolve** buttons when GitHub
allows them. **Expand all** opens every row. Choose **Review** in the sidebar to write a comment
or approval in a bordered multiline field (Enter adds a line). Check **Merge after approval** to squash-merge after approval.
**⋮ → Save repository** saves the current repository URL. Choose it from
the seven-row **Saved repositories** list below the PR list next time; saved entries persist
across restarts and duplicates are ignored.

The URL input starts empty; choose a saved repository or enter a URL.

Requires `gh` installed and authenticated (`gh auth login`), and a ttt build with
`ttt.open_changes`, `ttt.open_dialog`, and `ttt.close_dialog`. All GitHub calls
run asynchronously through `gh`; the plugin does not read authentication tokens.
Reviews target the displayed commit. A changed head requires reopening the PR,
and merges are pinned to that reviewed SHA. A failed merge can be retried
without submitting another approval.

It lists up to 100 open PRs. The plugin is pending the core API changes linked in its pull request.

Run the real-binary smoke checks with:

```sh
python3 tests/smoke.py /path/to/ttt/bin/ttt
```

These use an isolated configuration and a fake `gh` executable, so they do not
post actual reviews or merge pull requests. The plugin also needs
`panel.editor` permission for its comments tab.
