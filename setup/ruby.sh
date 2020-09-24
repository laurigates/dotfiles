#!/bin/bash

if ! command -v rbenv > /dev/null; then
    cd ~/.rbenv && src/configure && make -C src
    eval "$(~/.rbenv/bin/rbenv init -)"
    rbenv install 2.6.5
    rbenv global 2.6.5
    gem install bundler
fi

bundle install
