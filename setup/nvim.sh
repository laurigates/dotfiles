#!/bin/bash

if command -v nvim > /dev/null; then
    nvim --headless --noplugin +PlugClean! +PlugInstall +PlugUpdate +qa
    nvim --headless +UpdateRemotePlugins +qa
    if command -v npm > /dev/null; then
        npm install -g neovim
    fi
else
    echo "nvim not installed"
fi
