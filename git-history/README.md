# Git History

Browse the active file's commit history in ttt's **History** sidebar and inspect earlier versions without leaving the editor.

## Requirements

Git must be on PATH, and the file must belong to a Git repository.

## Usage

Install **Git History** from ttt's Plugins panel and approve its permissions. Open a tracked file, then select the **History** sidebar panel.

The panel shows up to 100 commits for the active file, following renames. Switching file tabs updates the history. Use **Refresh** in the panel header to reload it after new commits.

Select a commit to open its compact diff. Right-click a commit for more actions:

| Action | Description |
|---|---|
| Compact diff | Show the selected commit's changes to the file. |
| Extended diff | Compare the file before and after the selected commit with full context. |
| Compare with HEAD | Compare the selected version with the current committed version. |
| View file at commit | Open the selected version in a read-only tab. |
| Copy commit hash | Copy the full commit hash to the clipboard. |

## Permissions

The plugin uses a sidebar panel, reads the active file path, listens for editor events, and runs Git commands to retrieve history and file contents.

## Troubleshooting

- **Not a git repository:** open ttt in the file's repository or workspace.
- **No commits for this file:** commit the file first, or use **Refresh** after committing.
- **No file open:** select a file tab to load its history.
