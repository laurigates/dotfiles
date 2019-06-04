#!/bin/bash

if command -v bundle > /dev/null; then
    bundle install
else
    echo "bundle not installed"
fi
