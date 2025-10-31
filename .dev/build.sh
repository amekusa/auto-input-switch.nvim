#!/usr/bin/env bash

base="$(dirname "$0")"
cd "$base"

# create/clean doc dir
if [ -d ../doc ]
	then rm ../doc/*
	else mkdir ../doc
fi

# do other tasks
node "./build.js"

# force neovim to reindex the doc
nvim --headless -c "helptags ../doc" -c "q"

