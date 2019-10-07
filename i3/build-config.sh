#!/bin/bash
mkdir -p "$HOME/.i3"
touch "$HOME/dotfiles/i3/config.local" &&
cat "$HOME/dotfiles/i3/config.base" "$HOME/dotfiles/i3/config.local" > "$HOME/.i3/config"
