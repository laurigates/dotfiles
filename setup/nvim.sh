#!/bin/zsh

if nvim --version > /dev/null 2>&1; then
    if npm --version > /dev/null 2>&1; then
        npm install -g neovim
    fi
    nvim --headless --noplugin +PlugClean! +PlugInstall +PlugUpdate +qa
    nvim --headless +UpdateRemotePlugins +qa
else
    echo "Neovim is not installed!"

    if read -q "choice?Press Y/y to install neovim binaries to your home directory: "; then
        wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz
        tar xaf nvim-linux64.tar.gz --strip-components=1 -C ~/.local
    else
       echo "Skipping neovim installation."
    fi
fi
