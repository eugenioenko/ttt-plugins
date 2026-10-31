# Working on ttt plugins

This repository contains community plugins for the [ttt terminal editor](https://github.com/eugenioenko/ttt). Most plugins are sandboxed Lua 5.1 programs; grammar and theme plugins may contain only declarative assets. Each plugin lives in its own directory with a `plugin.ttt.json` manifest. The root README lists the available plugins.

## Read the host documentation first

The maintained plugin system documentation lives in the ttt repository:

- [Plugin authoring and API reference](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugin-authoring.md): manifests, permissions, lifecycle, every `ttt.*` module, widgets, raw cells, styles, and callbacks.
- [Testing plugins](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugin-testing.md): headless interaction, screenshots, debug state, and isolated configuration.
- [Installing and managing plugins](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/guides/plugins.md): discovery, approval, updates, reloads, and uninstall behavior.
- [Editor settings](https://github.com/eugenioenko/ttt/blob/main/docs-web/src/content/docs/reference/settings.md): host settings and defaults.

If ttt is checked out alongside this repository, read the same files under `../ttt/docs-web/src/content/docs/`. Use the documentation for the host version you are testing. The former `docs/PLUGINS.md` path is obsolete.

When documentation leaves a behavior unclear, inspect the host implementation:

- `internal/plugin/`: Lua bindings (`lua_*.go`), manifests, permissions, sandboxing, widget descriptors, and widget construction.
- `internal/widgets/`: shared controls, layout, focus, and interaction.
- `internal/app/commands_plugin.go`: application wiring for plugin APIs and panels.

Do not invent plugin APIs or assume that a standard Lua library is available in the sandbox. If a feature requires a new host API, identify that dependency and coordinate the host change and its documentation.

## Implementation expectations

- Keep each change scoped to the affected plugin. Preserve stable plugin names, command IDs, settings keys, and item IDs unless a migration is intended.
- Load modules explicitly, for example `local ttt = require("ttt")`; `ttt` is not a global. Register commands and panels with `ttt.register`.
- Respect host-wiring timing. Registration can happen at load time, but application callbacks such as notifications and command execution need the host APIs to be wired. Put those calls in documented lifecycle hooks, command handlers, or event callbacks.
- Keep render callbacks repeatable. They may run frequently; avoid launching external work on every redraw. Start asynchronous work from the appropriate action or a guarded initialization path, and redraw when its results change visible state.
- Use documented async process APIs for slow external work. Prevent old results from replacing the state for a newer query, selection, or resource. Handle missing binaries and failed processes visibly.
- Use widget primitives and named styles instead of hardcoded colors or manual hit testing. Preserve focus and selection through stable item IDs. Check keyboard and mouse interactions, narrow panels, and loading, empty, and error states.
- Treat byte offsets, rune indices, and terminal display columns as distinct values. Prefer widget layout and host width handling over assuming that one character occupies one cell.
- Match the manifest permissions to the APIs used. Keep external binaries explicit in `system.exec`, scope settings with `settings_keys`, and use documented filesystem and network scopes. Do not embed personal paths or credentials.
- Use documented lifecycle hooks for external resources. Uninstall cleanup must only remove settings or data owned by the plugin.
- Keep the plugin README consistent with its commands, shortcuts, settings, dependencies, and permissions. Update the root README when adding or renaming a listed plugin.
- Add comments for hidden constraints or non-obvious invariants, not to narrate the code.

## Verify changes in the editor

There is no repository-wide build or test runner here. Use a built ttt binary and the host's plugin testing guide. If needed, build the sibling checkout with `make -C ../ttt build`.

Run scripts with a temporary `TTT_CONFIG_DIR` so settings and plugin approvals do not touch the user's real configuration. For example, from this repository:

```sh
ttt_test_dir=$(mktemp -d)
TTT_CONFIG_DIR="$ttt_test_dir/config" ../ttt/bin/ttt \
  --size 100x30 --plugin ./docker-manager/init.lua \
  --exec "exec \"Docker: Switch Runtime (Docker / Podman)\"; debug $ttt_test_dir/state.json; quit"
```

Replace the plugin and actions with the behavior under test. `--plugin` reads the adjacent manifest and uses its name and exact permissions, including its external binary allowlist. A script can therefore run real external commands; choose actions and fixtures appropriate to the plugin.

Scripted input is acknowledged after handling and redraw. Use `wait-for` with a unique visible result for asynchronous transitions; do not insert sleeps between synchronous actions. `panel ID` opens a bottom panel, not a sidebar panel. Use the documented UI actions to reach sidebar plugins.

For visible changes, capture `screenshot PATH`. Use `debug PATH` to verify callbacks through output logs, focus, panel state, or the widget tree. Exercise the intended behavior before and after the change; use a compact terminal size when changing layout. Check persistence across reload or restart when changing settings.

Use the smallest deterministic test that proves the changed behavior. Add host tests in ttt when a host boundary needs coverage; do not add a duplicate test framework to each plugin. Before opening a PR, run `git diff --check` and describe the actual verification, including a screenshot excerpt for visible changes.

## Code review

Use a conventional commit title such as `fix(docker-manager): describe the behavior`. Explain the user-visible problem, the final behavior, and how it was verified. Prioritize actionable correctness, permission, lifecycle, and UX findings. Check API claims against the host documentation or source before requesting changes.

CodeRabbit reads this file through `.coderabbit.yaml`. Its path instructions cover Lua sources, manifests, and READMEs, and its linked repository supplies context from the ttt host.
