#!/bin/zsh

if ! command -v rbenv > /dev/null; then
    cd ~/.rbenv && src/configure && make -C src
    rbenv install 2.6.5
    rbenv global 2.6.5
    gem install bundler
fi

bundle install
