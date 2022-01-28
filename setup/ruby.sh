#!/bin/zsh -e

VERSION=2.6.5

rbenv install -s $VERSION
rbenv global $VERSION
gem install --quiet neovim
rbenv rehash
