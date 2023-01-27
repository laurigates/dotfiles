#!/bin/zsh -e

if ! rustup --version > /dev/null 2>&1; then
    curl -so rustup-init.sh https://sh.rustup.rs
    chmod +x rustup-init.sh
    ./rustup-init.sh --no-modify-path -y && rm rustup-init.sh
else
    rustup update
fi

# Update completions definition
mkdir -p ~/.zfunc
rustup completions zsh > ~/.zfunc/_rustup
rustup completions zsh cargo > ~/.zfunc/_cargo

# only run strip if binaries exist
if [ $(find ~/.cargo/bin -type f | wc -l) -gt 0 ]; then
    strip ~/.cargo/bin/*
else
    echo "No cargo binaries found. Skipping stripping them."
fi
