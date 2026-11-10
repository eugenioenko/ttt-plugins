# Terminal Theme

Generates a regular TTT theme snapshot from the client terminal palette exposed by `ttt.terminal.palette()`.

Contributed by [@danielmrdev](https://github.com/danielmrdev).

TTT reads static themes from `{config}/themes/<name>.json`. This plugin converts the client terminal's reported foreground, background, and ANSI colors into that format and writes `terminal.json`. Palette capture is performed by TTT core; the plugin does not inspect environment variables or terminal configuration files. This also works when TTT runs over SSH, provided the client terminal reports its palette to core.

## API availability

The `ttt.terminal.palette()` API and `terminal.palette` permission are available only in TTT builds that include the pending core change; they are not available in the latest merged release. The manifest requests that permission, so this plugin requires such a build and does not fall back to environment variables or terminal config files. Core makes 20 OSC color queries for a single capture, then reports `pending`, `partial`, `unavailable`, or `complete`. A final `partial` result may be used if foreground and background are valid. Missing ANSI entries use the plugin's fallback palette. Missing or malformed foreground/background values leave the prior snapshot untouched.

## How it works

- Requests one terminal palette capture per plugin load, after the plugin is wired, then checks the resulting snapshot with temporary timeouts while it is pending.
- Writes `{config}/themes/terminal.json` only when the parsed palette changes. It never switches the selected theme.
- Runs `settings.reload` after a successful write, and only while the `theme` setting is exactly `terminal`.
- Pending/unavailable results, API errors, and write failures are retried with one-shot 250 ms timeouts for up to 80 retries (20 seconds), without another capture or OSC request. This allows core's capture to finish even after two coalesced rounds of OSC queries (up to 14 seconds). Complete and valid partial results stop polling; reloading the plugin requests a fresh capture.
- The snapshot is never deleted, so it remains available if the plugin is disabled or uninstalled.
- Colors used for TTT UI and syntax highlighting are contrast-corrected against the terminal background. The 16 `terminal` ANSI colors are copied unchanged so TTT's integrated terminal matches the source terminal.

## Requirements

- A TTT build containing the pending `terminal.palette` API/permission change, plus scoped `fs.write` permissions.
- The `{config}/themes` directory has to exist. The plugin filesystem API cannot create directories, and refuses to open a missing root:

  ```sh
  mkdir -p ~/.config/ttt/themes
  ```

- `commands: true`, because TTT exposes `ttt.exec_command` — used here only for `settings.reload` — through that permission alone.
- `terminal.palette: true`, to read the palette captured by core.

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

- `~/.config/ttt/themes/terminal.json` appears after the one palette capture completes.
- A successful sync stays silent. On failure the output panel shows `[terminal-theme] Terminal theme: …` and the same text appears in the status bar.
- Once core reports the requested capture, the snapshot is written; an editor with the `terminal` theme selected recolors. A new capture happens only after reloading the plugin.

If nothing happens, run TTT with `--debug` and check `{config}/ttt.log`: a plugin that never loaded leaves a `skip plugin` warning there, while a plugin that loaded but could not read or write explains itself in the output panel and status bar.

## Permissions

```json
{
  "fs.write": ["{config}/themes"],
  "settings": true,
  "settings_keys": ["theme"],
  "commands": true,
  "terminal.palette": true
}
```

The plugin reads only `settings.theme` and the palette returned by core; it never reads terminal configs or environment variables and never writes settings. Its only write target is `{config}/themes`. `commands: true` is broad — it also grants command registration and clipboard access — but TTT offers no narrower way to reach `settings.reload`; this plugin calls `ttt.exec_command` for that command.

## Limitations

- Palette capture is performed asynchronously by core after one `terminal.request_palette()` call per plugin load. Core makes 20 OSC color queries for that capture. The plugin checks the captured snapshot using one-shot timeouts (never a permanent interval) and sends no further queries; reloading the plugin requests another single capture.

## Write behavior

The snapshot is built in memory and written with a single scoped filesystem write. Failed writes and `settings.reload` calls get bounded timeout retries; the plugin never removes the snapshot.

Empty style groups (for example `button.focused`, `syntax.bold`, `fileIcons.red`) are omitted from the snapshot rather than written as `[]`, because TTT decodes those keys into structs and every empty Lua table encodes as an array. The host rejects the whole file with `cannot unmarshal array into Go struct field ... of type config.StyleDef` and stops reading there, so an omitted key — which keeps TTT's own default — is both safer and equivalent.

## Tests

```sh
lua terminal-theme/tests/run.lua
```

The suite mocks `ttt.terminal.palette()` and covers capture states, OSC color mapping, writes, reload gating, retries, and preservation of the last good snapshot.
