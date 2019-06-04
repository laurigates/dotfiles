#!/bin/bash

if command -v cargo; then
    mkdir -p ~/.cargo/bin
    strip ~/.cargo/bin/*
else
    echo "cargo not installed"
fi
