#!/bin/zsh

export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"

if ! rbenv --version > /dev/null 2>&1; then
    cd ~/.rbenv && src/configure && make -C src
fi

rbenv install -s 2.6.5
rbenv global 2.6.5
gem install --quiet bundler
bundle install --quiet
