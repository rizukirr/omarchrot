#!/bin/bash

# Script to auto-update keybindings.json from binding.conf
# This reads your Hyprland binding.conf and generates a JSON file

BINDING_CONF="$HOME/.config/hypr/binding.conf"
OUTPUT_JSON="$HOME/.config/hypr/keybindings.json"

# Start JSON array
echo "[" > "$OUTPUT_JSON"

first=true

# Parse binding.conf and convert to JSON
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    # Match bind/binde/bindm lines
    if [[ "$line" =~ ^(bind|binde|bindm)[[:space:]]*=[[:space:]]*([^,]+),[[:space:]]*([^,]+),[[:space:]]*(.+)$ ]]; then
        mods="${BASH_REMATCH[2]}"
        key="${BASH_REMATCH[3]}"
        action="${BASH_REMATCH[4]}"

        # Clean up modifiers (replace $mainMod with SUPER)
        mods="${mods//\$mainMod/SUPER}"
        mods="${mods// /}"

        # Clean up action (remove leading/trailing whitespace)
        action="${action#"${action%%[![:space:]]*}"}"
        action="${action%"${action##*[![:space:]]}"}"

        # Escape special characters for JSON
        action="${action//\\/\\\\}"
        action="${action//\"/\\\"}"

        # Generate description from action
        description="$action"

        # Add comma if not first entry
        if [ "$first" = false ]; then
            echo "," >> "$OUTPUT_JSON"
        fi
        first=false

        # Write JSON object
        cat >> "$OUTPUT_JSON" <<EOF
  {
    "key": "$key",
    "modifiers": "$mods",
    "action": "$action",
    "description": "$description"
  }
EOF
    fi
done < "$BINDING_CONF"

# Close JSON array
echo "" >> "$OUTPUT_JSON"
echo "]" >> "$OUTPUT_JSON"

echo "Keybindings JSON updated at $OUTPUT_JSON"
