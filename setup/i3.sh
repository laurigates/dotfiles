#!/bin/zsh -e

if command -v i3 > /dev/null; then
    i3/build-config.sh
else
    echo "i3 not installed"
fi
