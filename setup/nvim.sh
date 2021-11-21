#!/bin/zsh

if nvim --version > /dev/null 2>&1; then
    if npm --version > /dev/null 2>&1; then
        npm install -g neovim
    fi
    nvim --headless --noplugin +PlugClean! +PlugInstall +PlugUpdate +qa
    nvim --headless +UpdateRemotePlugins +qa
else
    echo "Neovim is not installed!"
    install_nvim
fi

install_nvim () {
    if read -q "choice?Press Y/y to install neovim binaries to your home directory: "; then
        case "$(uname)" in
          'Darwin') OS=macos ;;
          'Linux') OS=linux64 ;;
        esac

        # Should add the option to choose whether to install globally
        INSTALL_DIR=/usr/local
        INSTALL_DIR=~/.local

        if [[ -v OS ]]; then
          wget https://github.com/neovim/neovim/releases/download/nightly/nvim-$OS.tar.gz
          # If installing globally, sudo is needed
          tar xaf nvim-$OS.tar.gz --strip-components=1 -C $INSTALL_DIR
        fi
    else
       echo "Skipping neovim installation."
    fi
}
