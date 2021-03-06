#!/bin/bash

if command -v pip > /dev/null; then
    pip install --user --upgrade pip
    pip install --user --upgrade -q -r requirements.txt
else
    echo "pip3 not installed"
fi
