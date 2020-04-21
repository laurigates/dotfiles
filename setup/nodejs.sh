#!/bin/bash

# nodejs environment
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

if command -v nvm > /dev/null; then
    nvm install 12
else
    echo "nvm not installed"

    # prompt whether or not to install nvm
    if setup/prompt.sh; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    fi
fi

if command -v npm > /dev/null; then
    npm install -g yaml-language-server
    npm install -g neovim
else
    echo "npm not installed"
fi
