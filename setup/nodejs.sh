#!/bin/bash

if command -v nvm > /dev/null; then
    nvm install 12
else
    echo "nvm not installed"
fi

if command -v npm > /dev/null; then
    npm install -g yarn
else
    echo "npm not installed"
fi
