#!/usr/bin/env bash

# Update script for refreshing all tools after a vacation

# Update asdf and its plugins
asdf update
asdf plugin-update --all

# Update Homebrew packages
brew update

# Update Neovim plugins and tools
nvim --headless "+Lazy! sync" "+MasonUpdate" +qa

# Update Python packages managed by pipx
pipx upgrade-all

# TODO: Add any missing update actions
# The idea here is that this script can be run to update everything after a vacation
