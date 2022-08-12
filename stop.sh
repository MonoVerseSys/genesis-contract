#!/bin/bash



kill $(ps -e | grep 'geth' | awk "{print $2}")

HOME="/home/ubuntu"

rm -rf "${HOME}/work"
