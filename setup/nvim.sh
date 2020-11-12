#!/bin/bash

if ! nvim --version > /dev/null 2>&1; then
    if ! npm --version > /dev/null 2>&1; then
        npm install -g neovim
    fi
    nvim --headless --noplugin +PlugClean! +PlugInstall +PlugUpdate +qa
    nvim --headless +UpdateRemotePlugins +qa
else
    echo "nvim not installed"
fi
