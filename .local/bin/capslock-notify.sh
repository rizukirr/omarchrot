#!/bin/bash

# Track previous state
previous_state=""

# Function to check capslock state
check_capslock() {
  hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .capsLock'
}

# Initialize state
previous_state=$(check_capslock)

# Poll for capslock state changes
while true; do
  current_state=$(check_capslock)

  # Only notify if state changed
  if [ "$current_state" != "$previous_state" ]; then
    if [ "$current_state" = "true" ]; then
      notify-send -u normal -t 2000 "Caps Lock" "ON"
    else
      notify-send -u normal -t 2000 "Caps Lock" "OFF"
    fi
    previous_state="$current_state"
  fi

  sleep 0.1
done
