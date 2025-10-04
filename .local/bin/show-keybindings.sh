#!/bin/bash

# A script to display Hyprland keybindings from JSON file
# using fzf in a terminal for an interactive search menu.

JSON_FILE="$HOME/.config/hypr/keybindings.json"

# Parse JSON and format keybindings
format_keybindings() {
  jq -r '.[] |
    if .modifiers == "" then
      .key + " → " + .description
    else
      .modifiers + " + " + .key + " → " + .description
    end' "$JSON_FILE"
}

tmp_file=$(mktemp)
format_keybindings > "$tmp_file"

kitty --class floating -e sh -c "fzf --prompt='Keybindings: ' --reverse --border < '$tmp_file'; rm '$tmp_file'"
