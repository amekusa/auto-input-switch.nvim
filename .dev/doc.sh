#!/usr/bin/env bash

base="$(dirname "$0")"
cd "$base"

# clear old docs
rm ../doc/*

# generate defaults.lua and the options doc
node "./options.js"

# generate the main doc
cd "panvimdoc"
prj="auto-input-switch"

./panvimdoc.sh \
	--input-file "../../README.md" \
	--description "*auto-input-switch.nvim*" \
	--project-name "$prj" \
	--shift-heading-level-by -1 \
	--demojify true \

cp -f "doc/$prj.txt" "../../doc/$prj.txt"

# force neovim to reindex the doc
nvim --headless -c "helptags ../../doc" -c "q"

