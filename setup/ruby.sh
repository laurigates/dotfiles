#!/bin/zsh -e

VERSION=2.6.5

if ! rbenv --version > /dev/null 2>&1; then
    cd ~/.rbenv && src/configure && make -C src
fi

rbenv install -s $VERSION
rbenv global $VERSION
gem install --quiet bundler
rbenv rehash
bundle install --quiet
rbenv rehash
