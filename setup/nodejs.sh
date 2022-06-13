#!/bin/zsh -e

VERSION=18.3.0

nodenv install -s $VERSION
nodenv global $VERSION
nodenv rehash
nodenv default-packages install
