# Packages
## General
vim git tmux zsh
build-essential firmware-linux linux-headers-amd64

## Puppet development packages
apt: ruby ruby-dev
gems: puppet-lint ruby-bundler
pip: yamllint

## zsh requirements
pip: pygments (colorize plugin)
apt: fonts-powerline (zsh theme)
apt: powerline (vim, tmux theme)

## tmux requirements
apt: xclip (to integrate copying with x selection)
