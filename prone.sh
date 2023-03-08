#!/usr/bin/env bash
# vim:filetype=sh

set -e

lookup() {
	local _dir="$1"
	local plugin="$2"
	local rev="$3"
	local ref="$4"

	# echo "downloading $plugin"
	local tmpfile
	tmpfile="$_dir/${plugin/\//_}"

	# DEBUG:
	# echo "{}" | jq '{name:$plugin}' --arg plugin "$plugin"

	if [[ -z "$ref" ]]; then
		ref=$(gh api "/repos/$plugin" | jq '.default_branch' | xargs -n 1 echo)
	fi

	gh api "/repos/$plugin/git/commits/$rev" |
		jq '{name: $plugin, rev: .sha, ref: $ref}' --arg plugin "$plugin" --arg ref "$ref" |
		tee "$tmpfile"
}

download() {
	declare -a args
	IFS=$'\n' read -r -d '' -a args < <(echo "$@" | tr " " "\n" && printf '\0')

	for arg in "${args[@]}"; do

		if ! grep -q ":" <<<"$arg"; then
			arg="$arg::"
		fi

		declare -a config
		IFS=$'\n' read -r -d '' -a config < <(echo "$arg" | tr ":" '\n')

		plugin="${config[0]}"
		rev="${config[1]}"
		ref="${config[2]}"

		lookup "$TMP" "$plugin" "$rev" "$ref" &
	done

	wait
}

_cleanup_tmp() {
	\rm -rf "$TMP"
}

generate_file() {
	declare -a args
	IFS=$'\n' read -r -d '' -a args < <(ls "$TMP" && printf '\0')

	OUTPUT=""
	# shellcheck disable=2045
	for arg in "${args[@]}"; do
		OUTPUT="$(cat "$TMP/$arg"),$OUTPUT"
	done

	OUTPUT="[$OUTPUT]"
	# shellcheck disable=2001
	OUTPUT=$(echo "$OUTPUT" | sed -e "s_\},]_}]_g")

	echo "$OUTPUT" | jq >versions.json

	_cleanup_tmp
}

fromargs() {
	declare -a args
	IFS=$'\n' read -r -d '' -a args < <(echo "$@" && printf '\0')

	download "${args[@]}" && generate_file
}

fromfile() {
	local _file
	_file="$1"

	local args
	args=$(jq '.[] | {name,rev,ref} | join(":")' versions.json | sed 's/\"//g')

	fromargs "$args"
}

TMP="$(mktemp -d)"

# REVIEW: example
# fromfile versions.json

"$@"
