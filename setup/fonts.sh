#!/bin/bash

if command -v fc-cache > /dev/null; then
    ../fonts/download.sh
    fc-cache -f -v
else
    echo "fc-cache not found"
fi
