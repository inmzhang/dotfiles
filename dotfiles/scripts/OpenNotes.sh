#!/bin/bash

NOTESDIR="$HOME/Documents/note-taking"

# Array of directories to exclude
excluded_dirs=( "pdfs" ".git" )   # Add more directory names here as needed

exclude_args=()
for ex in "${excluded_dirs[@]}"; do
    exclude_args+=( ! -name "$ex" )
done

mapfile -t notedirs < <(eval find "\"$NOTESDIR\"" -mindepth 1 -maxdepth 1 -type d "${exclude_args[@]}" | sort)

choices=()
for dir in "${notedirs[@]}"; do
    choices+=("$(basename "$dir")")
done

picked=$(printf '%s\n' "${choices[@]}" | rofi -dmenu -i -p "Open Note")

[ -z "$picked" ] && exit

selected_dir="$NOTESDIR/$picked"

if [[ -f "$selected_dir/notes.typ" ]]; then
    note_file="$selected_dir/notes.typ"
elif [[ -f "$selected_dir/notes.md" ]]; then
    note_file="$selected_dir/notes.md"
else
    notify-send "No note file found in $picked"
    exit 1
fi

if [[ "$note_file" == *.typ ]]; then
    TYPST_ROOT="$NOTESDIR" ghostty -e 'nvim -c "set autochdir | TypstPreview" -- '"$note_file"
else
    ghostty -e 'nvim -c "set autochdir" -- '"$note_file"
fi
