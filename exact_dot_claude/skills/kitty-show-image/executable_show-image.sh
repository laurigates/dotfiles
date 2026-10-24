#!/usr/bin/env bash
# Show images to the user in a new, clearly labelled kitty tab.
#
# The agent's Bash tool and the user's `!` commands have no /dev/tty, so a
# plain `kitty +kitten icat` fails there ("open /dev/tty: device not
# configured"). This launches icat in its own tab through kitty remote
# control instead. One key press closes the tab and kitty returns focus to
# the previous tab.
#
# Never pass --hold to `kitty @ launch`: it leaves a shell prompt behind,
# which looks exactly like Claude Code exited.
#
# Usage: show-image.sh FILE [FILE...]
# Exit codes: 0 launched, 1 bad arguments / missing file, 2 not usable here
# (not inside kitty, or remote control unavailable).
set -euo pipefail

if [ "$#" -eq 0 ]; then
    echo "usage: show-image.sh FILE [FILE...]" >&2
    exit 1
fi

files=()
for f in "$@"; do
    if [ ! -f "$f" ]; then
        echo "show-image: no such file: $f" >&2
        exit 1
    fi
    files+=("$(cd "$(dirname "$f")" && pwd)/$(basename "$f")")
done

if [ -z "${KITTY_WINDOW_ID:-}" ] || [ -z "${KITTY_LISTEN_ON:-}" ]; then
    echo "show-image: not inside kitty with remote control (KITTY_WINDOW_ID/KITTY_LISTEN_ON unset)" >&2
    exit 2
fi
if ! kitty @ ls >/dev/null 2>&1; then
    echo "show-image: kitty remote control is not reachable at $KITTY_LISTEN_ON" >&2
    exit 2
fi

banner='\n  \033[1;7m Claude Code image viewer \033[0m  press any key to close this tab and return\n\n'
# The inner sh expands $0 (banner) and $@ (files), so the quotes are single.
# shellcheck disable=SC2016
kitty @ launch --type=tab --tab-title "Claude: image viewer" \
    sh -c 'printf "%b" "$0"; kitty +kitten icat --hold "$@"' "$banner" "${files[@]}"
