#!/bin/bash

if command -v bundle > /dev/null; then
    cd ~/.rbenv && src/configure && make -C src
    eval "$(~/.rbenv/bin/rbenv init -)"
    cd ~/dotfiles && gem install bundler && bundle install
else
    echo "bundle not installed"
fi
