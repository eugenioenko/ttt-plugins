# Terminal Theme

Generates a regular TTT theme snapshot from the palette of the terminal emulator running TTT.

Contributed by [@danielmrdev](https://github.com/danielmrdev).

TTT reads static themes from `{config}/themes/<name>.json`. This plugin parses the running terminal's own configuration, converts its foreground, background, cursor, selection, and 16 ANSI colors into that format, and writes `terminal.json`. The result is an ordinary TTT theme, so no host changes or terminal queries are involved.

## Supported terminals

| Terminal | Config files | Includes |
|----------|--------------|----------|
| Foot | `~/.config/foot/foot.ini` | `include=` |
| Ghostty | `~/.config/ghostty/config`, `~/.config/ghostty/config.ghostty`, macOS Application Support | `config-file =`, `theme = light:…,dark:…` |
| Kitty | `~/.config/kitty/kitty.conf`, macOS Application Support | `include` |
| Alacritty | `~/.config/alacritty/alacritty.toml`, macOS Application Support | `general.import` / `[general] import` |
| WezTerm | `~/.config/wezterm/wezterm.lua`, `~/.wezterm.lua`, macOS Application Support | inline `colors` table only |

Each config may pull its palette from an included file, which is how an Omarchy, Pywal, or similar setup usually applies a theme. Includes are followed recursively up to 32 files. Unresolvable includes are skipped rather than treated as fatal.

Ghostty `theme =` names are resolved from `~/.config/ghostty/themes`, the macOS resources directory, `/usr/share/ghostty/themes`, and `/Applications/Ghostty.app/Contents/Resources/ghostty/themes`. Built-in Ghostty theme names that are not backed by a file cannot be resolved.

## Detection

The source terminal is selected in this order:

1. `TTT_TERMINAL_THEME` (`foot`, `ghostty`, `kitty`, `alacritty`, or `wezterm`).
2. The environment: `TERM`, `TERM_PROGRAM`, `KITTY_WINDOW_ID`, `WEZTERM_PANE`, `ALACRITTY_SOCKET`, and Ghostty's resource variables.
3. Probing the known config paths. If several exist, the first in the table above is used and the ambiguity is logged with a `TTT_TERMINAL_THEME` hint.

If the environment identifies a terminal whose config file does not exist, the plugin reports `… config not found` instead of silently borrowing another terminal's palette. Set `TTT_TERMINAL_THEME` to point at a terminal whose config does exist.

## How it works

- Checks the source every two seconds.
- Writes `{config}/themes/terminal.json` only when the parsed palette changes. It never switches the selected theme.
- Runs `settings.reload` after a successful write, and only while the `theme` setting is exactly `terminal`.
- A missing, unreadable, or palette-less config is non-fatal: the previous snapshot is left untouched, and the reason is logged to the output panel and shown once in the status bar.
- The snapshot is never deleted, so it keeps working if the terminal config disappears or the plugin is disabled or uninstalled.
- Colors used for TTT UI and syntax highlighting are contrast-corrected against the terminal background. The 16 `terminal` ANSI colors are copied unchanged so TTT's integrated terminal matches the source terminal.

## Requirements

- A TTT build with scoped `fs.read` / `fs.write` manifest paths ([eugenioenko/ttt#908](https://github.com/eugenioenko/ttt/pull/908)). On a build where those permissions are plain booleans the manifest cannot be parsed and TTT skips the plugin.
- The `{config}/themes` directory has to exist. The plugin filesystem API cannot create directories, and refuses to open a missing root:

  ```sh
  mkdir -p ~/.config/ttt/themes
  ```

- `commands: true`, because TTT exposes `ttt.exec_command` — used here only for `settings.reload` — through that permission alone.
- `system.env: true`, for terminal detection.
- The terminal config must define both a foreground and a background color. A config with only a few ANSI colors still works; missing ANSI slots fall back to TTT's defaults and an informational line is logged.
- A terminal config must be in one of the paths listed above. `XDG_CONFIG_HOME` locations other than `~/.config` are not probed unless `TTT_TERMINAL_THEME` is set to a supported terminal whose config is in a known path.

## Install

TTT installs plugins from a repository root. This repository is a monorepo, so `terminal-theme` can only be installed from the plugin panel once it is listed in the [community registry](https://github.com/eugenioenko/ttt/blob/main/community-plugins.json) with a `path` entry. Until then, install it by hand:

```sh
mkdir -p ~/.config/ttt/plugins ~/.config/ttt/themes
cp -a terminal-theme ~/.config/ttt/plugins/
```

Restart TTT and approve the permission prompt. Selecting the theme stays a manual step — run **Switch Theme** from the command palette and pick **Terminal**.

To try the plugin without installing the manifest:

```sh
bin/ttt --plugin ~/.config/ttt/plugins/terminal-theme/init.lua
```

## Verifying it works

- `~/.config/ttt/themes/terminal.json` appears within a couple of seconds of TTT starting.
- A successful sync stays silent. On failure the output panel shows `[terminal-theme] Terminal theme: …` and the same text appears in the status bar.
- Change the terminal theme (or re-run your theme switcher): the snapshot is rewritten within two seconds, and an editor with the `terminal` theme selected recolors.

If nothing happens, run TTT with `--debug` and check `{config}/ttt.log`: a plugin that never loaded leaves a `skip plugin` warning there, while a plugin that loaded but could not read or write explains itself in the output panel and status bar.

## Permissions

```json
{
  "fs.read": [
    "~/.config/foot",
    "~/.config/ghostty",
    "~/.config/kitty",
    "~/.config/alacritty",
    "~/.config/wezterm",
    "~/.wezterm.lua",
    "~/.local/state/omarchy",
    "~/Library/Application Support/com.mitchellh.ghostty",
    "~/Library/Application Support/kitty",
    "~/Library/Application Support/alacritty",
    "~/Library/Application Support/wezterm",
    "/usr/share/ghostty/themes",
    "/Applications/Ghostty.app/Contents/Resources/ghostty/themes"
  ],
  "fs.write": ["{config}/themes"],
  "settings": true,
  "settings_keys": ["theme"],
  "commands": true,
  "system.env": true
}
```

The plugin reads only terminal configuration, its include targets, and the Omarchy theme state directory that common setups include from. It reads only `settings.theme` and never writes settings. Its only write target is `{config}/themes`. `commands: true` is broad — it also grants command registration and clipboard access — but TTT offers no narrower way to reach `settings.reload`; this plugin calls `ttt.exec_command` for that one command.

An include that points outside the declared read paths is skipped by the sandbox, so the palette may fall back to what the main config defines. Add the include's directory to `fs.read` if your setup stores terminal colors elsewhere.

## Limitations

- **WezTerm `color_scheme` names** cannot be resolved from files. Use an inline `config.colors` table, or set `TTT_TERMINAL_THEME` to a terminal whose config defines colors. The plugin reports this explicitly.
- **Alacritty** support is TOML only; the legacy YAML format is not parsed. Glob imports are skipped.
- **Kitty** `globinclude`, `envinclude`, and `geninclude` are not followed.
- **Foot** uses `[colors]` first, then `[colors-dark]`, then `[colors-light]`; each section only fills keys the previous one left undefined. A config with separate dark and light palettes always resolves to the dark one unless `[colors]` is present.
- **No OSC queries.** The palette is read from files only, so a terminal that keeps its palette entirely in memory (for example, a named built-in Ghostty theme) is reported as unresolved.

## Write behavior

The snapshot is built in memory and written with a single scoped filesystem write. That write is not atomic, so a failure can truncate or damage an existing snapshot rather than leaving the old file intact. The plugin retries on the next poll and never removes the snapshot.

Empty style groups (for example `button.focused`, `syntax.bold`, `fileIcons.red`) are omitted from the snapshot rather than written as `[]`, because TTT decodes those keys into structs and every empty Lua table encodes as an array. The host rejects the whole file with `cannot unmarshal array into Go struct field ... of type config.StyleDef` and stops reading there, so an omitted key — which keeps TTT's own default — is both safer and equivalent.

## Tests

```sh
lua terminal-theme/tests/run.lua
```

The suite mocks `ttt`, `ttt.fs`, `ttt.settings`, `ttt.json`, and `ttt.system` and covers each parser, include/import following, detection precedence, palette conversion, contrast correction, snapshot writes, reload gating, retry behavior, and failure paths.
