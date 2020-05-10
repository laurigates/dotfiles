#!/bin/bash

source terminal/env

# nodejs environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

if command -v nvm > /dev/null; then
    nvm install 12
else
    echo "nvm not installed"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    nvm install 12
    npm install -g yaml-language-server
    npm install -g neovim
fi
