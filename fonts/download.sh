#!/bin/bash

declare -a styles=('Bold' 'Bold Italic' 'Italic' 'Regular')

cd ~/dotfiles/fonts/hack
for style in "${styles[@]}"
do
     wget -N "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Hack/${style// /}/complete/Hack%20$style%20Nerd%20Font%20Complete.ttf"
done
