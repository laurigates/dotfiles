#!/bin/bash

if command -v nvim > /dev/null; then
    nvim --headless +PlugInstall +PlugUpdate +UpdateRemotePlugins +qall
    # TODO: Fix this command so that it doesn't leave a bunch of dependencies lying
    # around under ~/.config/coc/extensions. The CocInstall command only leaves the
    # plugins there, but I have not succeeded in running CocInstall headless.
    # nvim +CocInstall +qa --headless
    cd ~/.config/coc/extensions && npm install --ignore-scripts --no-package-lock --only=production
else
    echo "nvim not installed"
fi
