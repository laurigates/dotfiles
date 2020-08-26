#!/bin/bash

if command -v nvim > /dev/null; then
    nvim --headless +PlugInstall +PlugUpdate +UpdateRemotePlugins +qall
else
    echo "nvim not installed"
fi
