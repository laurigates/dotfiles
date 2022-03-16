#!/bin/zsh -e

# Always run install_nvim so it's at the latest version.
# Too many things break otherwise.
# Defined in ~/.zshenv
install_nvim
if npm --version > /dev/null 2>&1; then
    npm install -g neovim
fi

nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
