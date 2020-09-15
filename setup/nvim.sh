#!/bin/bash

if command -v nvim > /dev/null; then
    nvim --headless --noplugin +PlugClean! +PlugInstall +PlugUpdate +qa
    nvim --headless +UpdateRemotePlugins +qa
else
    echo "nvim not installed"
fi
