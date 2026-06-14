#!/bin/bash

# Status line derived from bashrc PS1: [\u@\h \W]\$
# The trailing "$" is omitted as it is not meaningful in the Claude Code status bar.

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
dir=$(basename "${cwd:-$(pwd)}")

printf '[%s@%s %s]\n' "$(whoami)" "$(hostname -s)" "$dir"
