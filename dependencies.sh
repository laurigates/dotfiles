#!/bin/bash -e
packages=(
fonts-font-awesome fonts-hack fonts-powerline
zsh
tmux tmuxinator
i3 i3-wm i3blocks i3lock i3lock-fancy i3status rofi compton wmctrl xrdb
git
playerctl google-play-music-desktop-player
)

for package in ${packages[@]}; do
    if ! dpkg -s $package > /dev/null 2>&1; then
        echo "$package is missing. Install it (y/n)?"
        read answer
        if [ "$answer" != "${answer#[Yy]}" ]; then
            sudo apt-get install $package
        fi
    else
        echo "$package found."
    fi
done

