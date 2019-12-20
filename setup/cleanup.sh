#!/bin/bash

# check if files are not symbolic, meaning they
# are the default files and not symlinked to the
# dotfiles repo files

conffiles=(
    "~/.config/dunst/dunstrc"
    "~/.profile"
    "~/.bashrc"
    "~/.xinitrc"
    "~/.Xresources"
    "~/.config/compton.conf"
)

for conffile in "${conffiles[@]}"
do
  if eval "test -f $conffile && test ! -L $conffile"; then
    eval "mv -v $conffile $conffile.old"
  fi
done
