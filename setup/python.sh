#!/bin/zsh -e

VERSION=3.10.1

pyenv install -s $VERSION
pyenv global $VERSION
pip install pynvim pyyaml
pyenv rehash
