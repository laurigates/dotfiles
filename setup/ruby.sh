#!/bin/zsh -e

VERSION=3.1.2

rbenv install -s $VERSION
rbenv global $VERSION
gem install --quiet neovim
rbenv rehash
