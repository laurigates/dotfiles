#!/bin/bash

# check if files are not symbolic, meaning they
# are the default files and not symlinked to the
# dotfiles repo files
if [[ ! -h ~/.profile ]]; then
  mv ~/.profile ~/.profile.old 
fi

if [[ ! -h ~/.bashrc ]]; then
  mv ~/.bashrc ~/.bashrc.old 
fi
