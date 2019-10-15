#!/bin/bash

if command -v nvim > /dev/null; then
    nvim +PlugInstall +PlugUpdate +UpdateRemotePlugins +qa --headless
    nvim +CocInstall coc-eslint coc-yaml coc-css coc-python coc-tsserver coc-json coc-solargraph coc-snippets +qa --headless
else
    echo "nvim not installed"
fi
