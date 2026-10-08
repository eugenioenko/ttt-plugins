# Bookmarks

Bookmark lines and jump back to them from the sidebar. Bookmarks are saved per file and survive restarts.

## Usage

| Action | How |
|---|---|
| Add or remove a bookmark | Click left of the line number, or right-click a line and choose **Add Bookmark** / **Remove Bookmark** |
| Jump to a bookmark | Click it in the **Bookmarks** sidebar panel |
| Remove one bookmark | Click **✕** on its row |
| Remove a file's bookmarks | Click **✕** on the file row |
| Remove every bookmark | **Remove All Bookmarks** in the panel's **⋮** menu |

## Commands

| Command | Description |
|---|---|
| `Bookmarks: Toggle Bookmark` | Add or remove a bookmark on the cursor line |
| `Bookmarks: Remove All Bookmarks` | Remove every bookmark, after confirming |

## Notes

Bookmarks stay on their line number: inserting or deleting lines above one does not move it. The sidebar snippet refreshes when the file is saved.

## Requirements

ttt with the `gutter.click` plugin event.
