#!/bin/bash

if command -v nvim > /dev/null; then
    nvim +PlugInstall +PlugUpdate +UpdateRemotePlugins +qa --headless
else
    echo "nvim not installed"
fi
