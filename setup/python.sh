#!/bin/bash

if command -v pip; then
    pip install --user --upgrade -r requirements.txt
else
    echo "pip not installed"
fi

if command -v pip3; then
    pip3 install --user --upgrade -r requirements.txt
else
    echo "pip3 not installed"
fi