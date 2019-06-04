#!/bin/bash

if command -v cargo > /dev/null; then
    mkdir -p ~/.cargo/bin
    # only run strip if binaries exist
    if [ $(find ~/.cargo/bin -type f | wc -l) -gt 0 ]; then
        strip ~/.cargo/bin/*
    else
        echo "No cargo binaries found. Skipping stripping them."
    fi
else
    echo "cargo not installed"
fi
