#!/bin/zsh -e

VERSION=15.6.0

nodenv install -s $VERSION
nodenv global $VERSION
npm i -g neovim
nodenv rehash
