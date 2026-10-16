# Contributing

Thanks for your interest in contributing a plugin to ttt.

This repo holds community plugins for the [ttt terminal text editor](https://github.com/eugenioenko/ttt). Each plugin lives in its own subdirectory with a `plugin.ttt.json` manifest.

## Before you start

- Read the [plugin authoring guide](https://tttedit.dev/guides/plugin-authoring/) for the manifest format, permissions, and the `ttt` Lua API.
- For a new plugin, consider opening an issue first describing what it does, so we can agree on scope before you write it.
- Fixes and improvements to existing plugins can go straight to a pull request.

## Adding a plugin

1. Create a directory named after the plugin. The directory name must match `name` in `plugin.ttt.json`.
2. Add `plugin.ttt.json` and the Lua entry file it names.
3. Request only the permissions the plugin needs. Users see and approve each one on install.
4. Add a `README.md` explaining what the plugin does, what it requires (for example, an external binary), and how to use it.
5. Add a row for the plugin to the matching table in the root `README.md`.
6. Try it in ttt. The [testing guide](https://tttedit.dev/guides/plugin-testing/) shows how to load it with `ttt --plugin` and drive it headlessly with `--exec`.

## Listing it in ttt's Plugins panel

ttt's in-editor Plugins panel reads its list from `community-plugins.json` in the [ttt repo](https://github.com/eugenioenko/ttt). Once your plugin is merged here, open a PR there that adds an entry pointing at this repo:

```json
{
  "name": "my-plugin",
  "displayName": "My Plugin",
  "author": "your-github-username",
  "description": "One line describing what it does",
  "repo": "https://github.com/eugenioenko/ttt-plugins",
  "path": "my-plugin",
  "version": "0.1.0",
  "tags": ["..."]
}
```

## Updating a plugin

Users get your changes when they run **Plugins: Update** in ttt, which pulls the latest code from this repo. If an update requests new permissions, ttt asks the user to approve them again.

Bump `version` in the plugin's `plugin.ttt.json`, and the matching entry in ttt's `community-plugins.json`, so the version users see matches the code.

## Credit for your plugin

If you contribute a plugin, you're welcome to credit yourself in the same PR:

- **In the plugin's README:** add a line under the introduction, `Contributed by [@your-username](https://github.com/your-username).`
- **In the root README:** add your handle to the **Contributed by** column of your plugin's row.

## Pull requests

- Keep each PR to one plugin or one change.
- Use a [conventional commit](https://www.conventionalcommits.org/) title, for example `feat(my-plugin): add ...` or `fix(lsp-go): ...`.
- Explain what changed and how you tried it.
