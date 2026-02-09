#!/bin/bash

PDFDIR="$HOME/Zotero/storage"

# Use find, then print "filename (folder)::fullpath" for each PDF, all in one pipeline.
choices=$(find "$PDFDIR" -type f -iname "*.pdf" -printf "%f (%h)\n")

# Pick selection via rofi
picked=$(printf '%s' "$choices" | rofi -dmenu -i -p "Open Paper")

# Exit if nothing picked
[ -z "$picked" ] && exit

# Extract just the filename and folder
filename=$(echo "$picked" | sed -E 's/ \((.*)\)//')
folder=$(echo "$picked" | sed -E 's/.* \((.*)\)/\1/')

# Find the full path (handle duplicate filenames by folder name)
fullpath=$(find "$folder" -maxdepth 1 -type f -name "$filename")

# Open with xdg-open (change to zathura if desired)
[ -n "$fullpath" ] && xdg-open "$fullpath"
