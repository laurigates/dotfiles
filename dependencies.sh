#!/bin/bash -e
aptpackages=(
fonts-font-awesome fonts-hack fonts-powerline
zsh
tmux
neovim
i3 i3-wm i3blocks i3lock i3lock-fancy i3status rofi wmctrl x11-xserver-utils dunst
compton hsetroot
git
playerctl google-play-music-desktop-player
xsel
universal-ctags global
)

for package in ${aptpackages[@]}; do
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

cargo install bat
cargo install lsd
cargo install ripgrep
cargo install fd-find
