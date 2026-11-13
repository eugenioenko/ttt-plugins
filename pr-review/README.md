# PR Review

Run **PR Review: Show**. Enter a GitHub repository URL, `owner/repo`, or a pull request URL, then
choose **Load**. Activate a PR to open its description and multi-file diff in
ttt's native detail view. The header's **⋮** switches between open and closed PRs.
**Comments ()** opens a tab with discussion comments, review messages, and inline
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

The **CI ()** checklist button opens the jobs tab. Separate counts beside it show passed
(green), pending/running (warning color), and
failed (red) counts; a fourth muted count also appears for skipped, neutral, or cancelled
jobs. It opens a CI tab with each job's icon, name, and status. Checks and external
commit statuses are fetched for the opened PR's commit, refreshed every 30 seconds
while that PR is selected or its CI tab remains open. **Refresh** updates immediately.
Reopen the PR after a new push to review its new commit. An **!** beside the CI icon means status could
not be loaded completely; open the tab for the error and any available jobs.
Counts use ordinary styled labels and need no styled-button API.

**Timeline** lists the PR’s commits, newest first, with author, commit time, short
hash, and message. Select a row to see the full hash and author/committer details.
**Refresh** fetches the latest list; reopening an existing Timeline tab refreshes it
too. GitHub returns at most 250 commits through this endpoint, and the tab marks
that limit when reached. Authors and committers come from commit metadata; GitHub’s
commit list does not identify the person who pushed each commit.

The action order is Comments (**** with its count), Timeline (****), CI (****
with separate colored counts), then right-aligned **Review**. The three icons use
Nerd Fonts, and every action button has one column of left/right padding. All four actions share one row;
widen the sidebar to see the full row, or use its **⋮** menu or command palette.

It lists up to 100 open PRs. The plugin is pending the core API changes linked in its pull request.

Run the real-binary smoke checks with:

```sh
python3 tests/smoke.py /path/to/ttt/bin/ttt
python3 tests/ci.py /path/to/ttt/bin/ttt
python3 tests/timeline.py /path/to/ttt/bin/ttt
```

These use an isolated configuration and a fake `gh` executable, so they do not
post actual reviews or merge pull requests. The plugin also needs
`panel.editor` permission for its comments tab.
