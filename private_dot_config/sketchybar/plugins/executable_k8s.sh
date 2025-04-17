#!/bin/sh

sketchybar --set "$NAME" label="$(kubectl config current-context | cut -d'_' -f4)"
