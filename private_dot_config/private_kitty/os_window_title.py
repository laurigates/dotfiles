"""Prefix the macOS titlebar (OS window title) with the active tab's cwd
basename, mirroring tab_title_template's "{cwd} · {title}" format.

kitty has tab_title_template but no equivalent for the OS window title, which
otherwise just shows the active window's process title with no cwd context.
This watcher reasserts a cwd-prefixed title on the events that drive the
titlebar.

Push-based by necessity (there is no per-render hook for the OS title), so it
fires on:
  - on_focus_change  — switching tabs swaps which window drives the titlebar
  - on_title_change  — an OSC-emitting program (vim/ssh) changed its title
  - on_cmd_startstop — a shell command started/stopped; cwd may have changed

Only the globally-active window is allowed to write the titlebar, so a
background tab emitting a title never clobbers what you're looking at.

See: kitty.conf `watcher os_window_title.py`.
"""

import os

from kitty.fast_data_types import set_os_window_title


def _cwd_base(window):
    try:
        cwd = window.cwd_of_child or ""
    except Exception:
        cwd = ""
    return os.path.basename(cwd.rstrip("/")) or "~"


def _is_active(boss, window):
    """True when this window currently drives the OS titlebar."""
    try:
        return boss.active_window is window
    except Exception:
        return True


def _apply(window, title):
    base = _cwd_base(window)
    title = (title or "").strip()
    label = f"{base} · {title}" if title and title != base else base
    try:
        set_os_window_title(window.os_window_id, label)
    except Exception:
        pass


def on_focus_change(boss, window, data):
    if data.get("focused"):
        _apply(window, window.title)


def on_title_change(boss, window, data):
    if _is_active(boss, window):
        _apply(window, data.get("title") or window.title)


def on_cmd_startstop(boss, window, data):
    if _is_active(boss, window):
        _apply(window, window.title)
