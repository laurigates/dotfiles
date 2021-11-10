#!/bin/zsh

export PATH="$HOME/.cargo/bin:$PATH"

if ! rustup --version > /dev/null 2>&1; then
    wget --quiet -O rustup-init.sh https://sh.rustup.rs
    chmod +x rustup-init.sh
    ./rustup-init.sh --no-modify-path -y && rm rustup-init.sh

else
    rustup update
fi

# only run strip if binaries exist
if [ $(find ~/.cargo/bin -type f | wc -l) -gt 0 ]; then
    strip ~/.cargo/bin/*
else
    echo "No cargo binaries found. Skipping stripping them."
fi
