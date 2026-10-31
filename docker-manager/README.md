# Docker Manager

Manage Docker or Podman containers, images and volumes from the sidebar.

## Commands

| Command | Keybinding | Description |
|---|---|---|
| `Docker: Refresh` | `Ctrl+K R` | Refresh all containers, images and volumes |
| `Docker: Prune Containers` | | Remove all stopped containers |
| `Docker: Prune Images` | | Remove all unused images |
| `Docker: Prune Volumes` | | Remove all unused volumes |
| `Docker: Switch Runtime (Docker / Podman)` | | Toggle the container runtime and save it to settings |

## Sidebar Shortcuts

| Key | Action |
|---|---|
| `R` | Refresh all |
| `Enter` | Expand / collapse |
| Right-click | Context menu (start, stop, restart, remove) |

## Settings

Choose the container runtime in `settings.json`. Use `"docker"` (the default) or `"podman"`; any other value falls back to Docker.

```json
{
  "docker": {
    "runtime": "podman"
  }
}
```

The Runtime footer at the bottom of the sidebar shows the active runtime. Click its selector to choose Docker or Podman; the current runtime has a checkmark. You can also switch from the sidebar menu or the command palette. After editing `settings.json` by hand, reload settings and refresh the sidebar with `R`.

## Requirements

The selected runtime must be installed, and its CLI (`docker` or `podman`) must be available in your PATH.
