# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Cursor, and others) working in this repository.

## What this repo is

A collection of Lua plugins for [ttt](https://github.com/eugenioenko/ttt), a terminal text editor written in Go. This repo holds plugin source only; the editor, the plugin runtime, and the plugin API live in the ttt repo.

## How it ties to ttt

- **Install source.** Each plugin is a subdirectory of this repo. ttt installs one by cloning this repo and loading the subdirectory named in its registry entry.
- **Registry.** ttt's in-editor Plugins panel lists what is in `community-plugins.json` at the root of the ttt repo. An entry points here with `"repo": "https://github.com/eugenioenko/ttt-plugins"` and `"path": "<plugin-dir>"`. A plugin added here does not appear in the Plugins panel until it also has an entry there, added by a separate PR to ttt.
- **Plugins outside this repo.** The registry can also point at a plugin's own repository (no `path`). Those plugins may be listed in the root README for discovery, but their code is not here.
- **Runtime and API.** ttt runs plugins in a sandboxed Lua VM (gopher-lua) and exposes the `ttt` module. The API, manifest format, and permission model are defined by ttt, not by this repo.

## Plugin layout

```
<plugin-name>/
  plugin.ttt.json   manifest: name, displayName, description, version, author, entry, api, permissions
  <entry>.lua       the file named by "entry" (plugin.lua or init.lua)
  README.md         what it does, requirements, usage
  tests/            optional
```

- The directory name, the manifest `name`, and the registry `path` must match.
- `permissions` must request only what the plugin uses; users approve them on install, and a plugin update that requests more asks for approval again.
- Users update by pulling the latest code from this repo, so whatever is merged here is what they get. `version` is shown to users but does not gate updates; bump it in the manifest when changing a plugin and keep the registry entry's `version` in sync.

## Plugin API reference

The ttt docs are the source of truth. Read them before deriving the API from ttt's source:

- [Plugin authoring](https://tttedit.dev/guides/plugin-authoring/): manifest, permissions, widgets, and every `ttt.*` function
- [Plugins](https://tttedit.dev/guides/plugins/): installing and managing plugins
- [Testing plugins](https://tttedit.dev/guides/plugin-testing/): driving a plugin headlessly with `ttt --plugin` and `--exec`

Things that are easy to miss:

- Plugins must `local ttt = require("ttt")`; the module is preloaded, not global.
- `ttt.*` callbacks such as `notify` or `exec_command` work from command handlers and event callbacks, not at plugin load time.
- When testing with `--exec`, set `TTT_CONFIG_DIR` to a throwaway directory so the real `~/.config/ttt` is not read or changed.

## README conventions

The root README groups plugins into tables by kind. When adding a plugin, add a row to the matching table and keep the plugin's own README next to its code.

## Crediting contributors

When a plugin is contributed by someone outside the project, credit them in two places:

- **The plugin's README:** a line under the introduction, `Contributed by [@username](https://github.com/username).`
- **The root README:** their handle in the **Contributed by** column of the plugin's row.

Leave the column blank for plugins written by the maintainer. Contributors are welcome to add these credits in their own PR.
