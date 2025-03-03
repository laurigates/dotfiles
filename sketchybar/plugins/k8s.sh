#!/bin/sh

sketchybar --set "$NAME" label="$(kubectl config current-context)"
