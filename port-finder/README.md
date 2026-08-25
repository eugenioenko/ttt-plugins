# Port Finder

Shows which apps on your machine have an open TCP port — the process name and the port it's listening on, in a sidebar list you can filter and kill from. It answers "what's running on port 3000" without leaving the editor for a terminal incantation (`lsof -i`, `ss -tlnp`, `netstat -ano`).

It only lists processes with a listening socket. A script or build tool with no server component won't show up — this isn't a general process manager, just a way to find and stop whatever's holding a port.

## Sidebar

Open the **Ports** panel from the sidebar. Each row shows the process name and its port. Type in the filter box to narrow by name or port number.

| Action | How |
|---|---|
| Kill a process | Click the `✕` on its row, or select it and press `k` |
| Refresh the list | `...` header menu → Refresh, or run `Ports: Refresh` |

## Commands

| Command | Description |
|---|---|
| `Ports: Refresh` | Re-scan listening ports |

## Requirements

- **Linux:** `ss` (iproute2, installed by default on most distributions)
- **macOS:** `lsof` (preinstalled)
- **Windows:** `netstat` and `tasklist` (preinstalled)

Killing a process requires permission to signal it — you can only kill processes you own, same as `kill`/`taskkill` from a terminal.
