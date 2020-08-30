#!/bin/bash

if ! command -v cargo > /dev/null; then
    wget -O rustup-init.sh https://sh.rustup.rs
    ./rustup-init.sh --no-modify-path -y && rm rustup-init.sh

    # only run strip if binaries exist
    if [ $(find ~/.cargo/bin -type f | wc -l) -gt 0 ]; then
        strip ~/.cargo/bin/*
    else
        echo "No cargo binaries found. Skipping stripping them."
    fi
else
    echo "cargo not installed"
fi
