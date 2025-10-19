#!/usr/bin/env bash

base="$(dirname "$0")"

# generate defaults.lua and the options doc
node "$base/options.js"

# generate the main doc
cd "$base/panvimdoc"
prj="auto-input-switch.nvim"

./panvimdoc.sh \
	--input-file "../../README.md" \
	--project-name "$prj" \
	--shift-heading-level-by -1 \
	--demojify true \

cp -f "doc/$prj.txt" "../../doc/$prj.txt"

# force neovim to reindex the doc
nvim --headless -c "helptags ../../doc" -c "q"

