#!/bin/zsh

export PATH="$HOME/.nodenv/shims:$HOME/.nodenv/bin:$PATH"

if ! nodenv --version > /dev/null 2>&1; then
    cd ~/.nodenv && src/configure && make -C src
fi

nodenv install 15.6.0
nodenv global 15.6.0
npm i -g neovim
nodenv rehash
