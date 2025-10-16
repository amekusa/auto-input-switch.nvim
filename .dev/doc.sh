#!/usr/bin/env bash

base="$(dirname "$0")"

cd "$base/panvimdoc"
prj="auto-input-switch.nvim"

./panvimdoc.sh \
	--project-name "$prj" \
	--input-file "../../README.md" \
	--shift-heading-level-by -1

cp -f "doc/$prj.txt" "../../doc/$prj.txt"

