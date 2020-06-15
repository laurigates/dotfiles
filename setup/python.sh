#!/bin/bash

if command -v pip3 > /dev/null; then
    pip3 install --user --upgrade -q -r requirements.txt
else
    echo "pip3 not installed"
fi
