#!/bin/bash

# Install, cleanup and update neovim plugins
nvim --headless "+Lazy! sync" "+MasonUpdate" +qa

# The checkhealth just runs forever
# Check neovim health
# nvim --headless "+checkhealth" +qa

