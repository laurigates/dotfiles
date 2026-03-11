# Kitty Terminal Reference

## Remote Control

Requires `allow_remote_control yes` (or `socket-only`) in `~/.config/kitty/kitty.conf`,
or start with `kitty -o allow_remote_control=yes`.

### Listing Tabs and Windows

```sh
# Full JSON dump of all OS windows, tabs, and panes
kitty @ ls

# Tab titles
kitty @ ls | jq '.[].tabs[].title'

# Foreground process in each window
kitty @ ls | jq '.[].tabs[].windows[].foreground_processes'

# Current working directory of each window
kitty @ ls | jq '.[].tabs[].windows[].cwd'
```

### Data Available via `kitty @ ls`

- **OS windows** — id, platform window id, focused state
- **Tabs** — id, title, layout, active window, focused state
- **Windows (panes)** — id, pid, cwd, title, command line, foreground processes, lines/columns, env vars

### Other Useful Remote Commands

```sh
kitty @ focus-tab
kitty @ set-tab-title
kitty @ close-tab
kitty @ launch
kitty @ --help          # full list
```
