#!/usr/bin/env bash

base="$(dirname "$0")"
cwd="$(pwd -P)"

clone() {
	local src="$1"; shift
	local dst="$1"; shift
	[ -n "$dst" ] || dst="$(basename "$src")"
	if [ -d "$dst" ]; then
		cd "$dst"
		git pull origin
		cd "$cwd"
	else
		git clone "$src" "$dst"
	fi
}

clone "git@github.com:kdheepak/panvimdoc.git" "$base/panvimdoc"

