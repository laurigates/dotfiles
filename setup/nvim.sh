#!/bin/zsh -e

if nvim --version > /dev/null 2>&1; then
    if npm --version > /dev/null 2>&1; then
        npm install -g neovim
    fi
    nvim --headless --noplugin +PlugClean! +qa
    nvim --headless +PlugInstall! +PlugUpdate! +qa
    nvim --headless +UpdateRemotePlugins +qa
else
    echo "Neovim is not installed!"
    # Defined in ~/.zshenv
    install_nvim
fi
