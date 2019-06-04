#!/bin/bash

if command -v nvim; then
    nvim +PlugInstall +PlugUpdate +UpdateRemotePlugins +qa --headless
else
    echo "nvim not installed"
fi
