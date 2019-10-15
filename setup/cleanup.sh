#!/bin/bash

# check if files are not symbolic, meaning they
# are the default files and not symlinked to the
# dotfiles repo files
if [[ -f ~/.profile ]] && [[ ! -h ~/.profile ]]; then
  mv ~/.profile ~/.profile.old 
fi

if [[ -f ~/.bashrc ]] && [[ ! -h ~/.bashrc ]]; then
  mv ~/.bashrc ~/.bashrc.old 
fi
