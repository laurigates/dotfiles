# Packages

## General

xsel
git

## i3

i3 i3-wm
i3status i3blocks i3blocks-contrib
picom hsetroot
i3lock i3lock-fancy
rofi
dunst
wmctrl x11-xserver-utils

### i3blocks calendar

yad xdotool

## terminal

kitty
tmux
tmuxinator
ripgrep
fd-find
bat
lsd
jq
task tasksh
pet

## zsh

zsh
pygments (colorize plugin)
powerline (vim, tmux theme)

## neovim

nvim
universal-ctags global

## nodejs

nvm

## music

playerctl google-play-music-desktop-player

## email

thunderbird

## rustc & cargo

curl https://sh.rustup.rs -sSf | sh

## php

phan
phpactor

# TODO

- Display or log errors from dotfiles setup scripts
- Pre-cleanup existing configuration files (.bashrc, .bash_profile, .profile)
- Source the .env file at start of dotfiles installation
- themes
  - qt5ct
  - gtk2
  - gtk3
  - kvantum

- local mail delivery (postfix)
  - root alias
- sysctl optimizations (swappiness)

- dnsmasq, openresolv, systemd-resolvd

- set primary display with `xrandr --output DVI-D-0 --primary` for i3blocks tray to work

- systemd-swap

Symlink /home/lgates/.local/share/nvim/plugged/phpactor under /usr/local/bin
Phpactor dependencies not installed. Run `composer install` (https://getcomposer.org) in "/home/lgates/.local/share/nvim/plugged/phpactor"
docker build -t laurigates/dotfiles .
