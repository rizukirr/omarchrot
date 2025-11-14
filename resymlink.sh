#!/usr/bin/env bash

set -e

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 OLD_PATH NEW_PATH"
    exit 1
fi

OLD=$(realpath "$1")
NEW=$(realpath "$2")

echo "Old path: $OLD"
echo "New path: $NEW"
echo ""
echo "Rewriting symlinks..."
echo "====================="

# Directories to search
SEARCH_DIRS=(
    "$HOME/.config"
    "$HOME/.local/bin"
    "$HOME/.local/share"
    "$HOME"
)

for DIR in "${SEARCH_DIRS[@]}"; do
    [[ ! -d "$DIR" ]] && continue

    find "$DIR" -type l 2>/dev/null | while read -r link; do
        target=$(readlink "$link")

        # Only modify symlinks that contain OLD path
        if [[ "$target" == *"$OLD"* ]]; then
            new_target="${target//$OLD/$NEW}"

            echo "Updating: $link"
            echo "  $target → $new_target"

            rm "$link"
            ln -s "$new_target" "$link"
        fi
    done
done

echo ""
echo "Done."

