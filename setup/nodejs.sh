#!/bin/zsh -e

VERSION=15.6.0

if ! nodenv --version > /dev/null 2>&1; then
    cd ~/.nodenv && src/configure && make -C src
fi

nodenv install --skip-existing $VERSION
nodenv global $VERSION
npm i -g neovim
nodenv rehash
