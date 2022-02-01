#!/bin/zsh -e

VERSION=17.4.0

nodenv install -s $VERSION
nodenv global $VERSION
npm i -g neovim
nodenv rehash
