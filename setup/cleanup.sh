#!/bin/zsh -e

# check if files are not symbolic, meaning they
# are the default files and not symlinked to the
# dotfiles repo files

for conffile
do
  if eval "test -f $conffile || test -d $conffile && test ! -L $conffile"; then
    eval "mv -v $conffile $conffile.old"
  fi
done
