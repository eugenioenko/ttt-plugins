# ttt Plugins

Community plugins for the [ttt terminal text editor](https://github.com/eugenioenko/ttt).

## Plugins

| Plugin | Description |
|--------|-------------|
| [cheat-sheet](cheat-sheet/) | Interactive cheat sheet browser |
| [color-picker](color-picker/) | Color picker with hex/RGB support |
| [docker-manager](docker-manager/) | Docker container management sidebar |
| [go-test-runner](go-test-runner/) | Run and view Go test results |
| [http-client](http-client/) | HTTP request client |
| [json-viewer](json-viewer/) | JSON tree viewer for the current file |
| [markdown-preview](markdown-preview/) | Markdown preview panel |
| [notepad](notepad/) | Scratchpad for quick notes |
| [todo-scanner](todo-scanner/) | Scan workspace for TODO/FIXME/HACK/NOTE comments |

## Installation

Plugins can be installed directly from ttt:

1. Open the command palette (`Ctrl+P`) and run **Plugins: Show Panel**
2. Search for a plugin and click **Install**

Or install from URL via the command palette: **Plugins: Install from URL**

```
https://github.com/eugenioenko/ttt-plugins
```

Each plugin lives in its own subdirectory with a `plugin.ttt.json` manifest.

## Creating a Plugin

See the [Plugin Documentation](https://github.com/eugenioenko/ttt/blob/main/docs/PLUGINS.md) for the full API reference.
