#!/bin/bash

source terminal/env

if ! command -v rbenv > /dev/null; then
    cd ~/.rbenv && src/configure && make -C src
    eval "$(~/.rbenv/bin/rbenv init -)"
else
    rbenv install 2.6.5
    rbenv global 2.6.5
fi

gem install bundler
bundle install
