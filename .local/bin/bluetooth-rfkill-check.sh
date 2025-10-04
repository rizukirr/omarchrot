#!/usr/bin/env bash

# Check if rfkill exists
if ! command -v rfkill &>/dev/null; then
  exit 1
fi

rfkill_output=$(rfkill list bluetooth)

if [[ -z "$rfkill_output" ]]; then
  exit 1
fi

echo "$rfkill_output"

# Check if blocked
soft_blocked=$(echo "$rfkill_output" | grep -i "Soft blocked" | awk '{print $3}')
hard_blocked=$(echo "$rfkill_output" | grep -i "Hard blocked" | awk '{print $3}')

if [[ "$soft_blocked" == "yes" || "$hard_blocked" == "yes" ]]; then
  sudo rfkill unblock bluetooth
fi
