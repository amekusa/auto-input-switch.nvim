#!/usr/bin/env bash

base="$(dirname "$0")"
cd "$base"

# create/clean doc dir
if [ -d ../doc ]
	then rm ../doc/*
	else mkdir ../doc
fi

# generate the main doc
cd "panvimdoc"
prj="auto-input-switch"

./panvimdoc.sh \
	--input-file "../../README.md" \
	--description "*auto-input-switch.nvim*" \
	--project-name "$prj" \
	--shift-heading-level-by -1 \
	--toc false \
	--ignore-rawblocks false \
	--demojify false \

cp -f "doc/$prj.txt" "../../doc/$prj.txt"
cd ..

# do other tasks
node "./build.js"

# force neovim to reindex the doc
nvim --headless -c "helptags ../doc" -c "q"

