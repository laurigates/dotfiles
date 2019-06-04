#!/bin/bash

if command -v bundle; then
    bundle install
else
    echo "bundle not installed"
fi
