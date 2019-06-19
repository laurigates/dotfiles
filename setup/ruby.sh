#!/bin/bash

if command -v bundle > /dev/null; then
    cd ~/.rbenv && src/configure && make -C src
    ~/.rbenv/bin/rbenv init
    cd ~/dotfiles && bundle install
else
    echo "bundle not installed"
fi
