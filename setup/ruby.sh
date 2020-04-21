#!/bin/bash

if ! command -v rbenv > /dev/null; then
    cd ~/.rbenv && src/configure && make -C src
    eval "$(~/.rbenv/bin/rbenv init -)"
    rbenv install 2.6.5
    rbenv global 2.6.5
fi

if ! command -v bundle > /dev/null; then
    cd ~/dotfiles && gem install --user-install bundler
fi

bundle install
