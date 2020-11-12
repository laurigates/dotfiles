#!/bin/bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

if command -v nvim > /dev/null; then
    if command -v npm > /dev/null; then
        npm install -g neovim
    fi
    nvim --headless --noplugin +PlugClean! +PlugInstall +PlugUpdate +qa
    nvim --headless +UpdateRemotePlugins +qa
else
    echo "nvim not installed"
fi
