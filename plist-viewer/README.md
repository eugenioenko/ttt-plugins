# PLIST Viewer

Open macOS/iOS binary property lists (`bplist00`) as an interactive tree with
keys and values in two left-aligned columns separated by a rule. Files ttt
otherwise shows as a binary card — app preferences, `Info.plist` files from
iOS app bundles, and other Apple configuration data — open read-only, decoded
by a pure-Lua parser with no external tools.

XML plists are plain text and keep opening as normal editor tabs; only binary
plists are intercepted.

## Layout

- Keys form a fixed column (sized per file from the widest key), values start
  at one shared column for every nesting depth, and a `│` rule separates them.
- Leaves carry a type glyph (string, number, bool, date, data, UID); dict and
  array rows show a chevron and a `N keys` / `N items` count.
- Integers beyond 2^53 render as exact hex (`0x4000000000000000`) instead of
  silently losing precision. Dates render as UTC timestamps.

## Interaction

| Input | Action |
|---|---|
| Click, Enter, Space | Toggle the row's children |
| Up/Down, j/k | Move selection |
| Left, h | Collapse, or jump to the parent row |
| Right, l | Expand |
| Home/End, PgUp/PgDn | Scroll the tree |

Keyboard focus moves into the tree when the tab opens and when you switch back
to it.

## Permissions

| Permission | Why |
|---|---|
| `editor.file_handlers` | Register the `bplist00` handler |
| `fs.read: ["*"]` | A file handler must read plists from any path, not just the workspace |
| `events.file` | Focus the tree when its file opens, clean up on close |
| `events.editor` | Refocus when switching back to the tab |

No command execution, no network, no writes.
