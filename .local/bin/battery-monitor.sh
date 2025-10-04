#!/bin/bash

# Battery notification script - alerts when battery is low
# Designed to be run by systemd timer every 30 seconds

BATTERY_THRESHOLD=20
NOTIFICATION_FLAG="/run/user/$UID/battery_notified"

get_battery_percentage() {
  upower -i "$(upower -e | grep 'BAT')" |
    awk -F: '/percentage/ {
      gsub(/[%[:space:]]/, "", $2);
      val=$2;
      printf("%d\n", (val+0.5))
      exit
    }'
}

get_battery_state() {
  upower -i $(upower -e | grep 'BAT') | grep -E "state" | awk '{print $2}'
}

send_notification() {
  notify-send -u critical "󱐋 Time to recharge!" "Battery is down to ${1}%" -I battery-caution -t 30000
  brightnessctl set 20%
}

BATTERY_LEVEL=$(get_battery_percentage)
BATTERY_STATE=$(get_battery_state)

if [[ "$BATTERY_STATE" == "discharging" && "$BATTERY_LEVEL" -le "$BATTERY_THRESHOLD" ]]; then
  if [[ ! -f "$NOTIFICATION_FLAG" ]]; then
    send_notification "$BATTERY_LEVEL"
    touch "$NOTIFICATION_FLAG"
  fi
else
  rm -f "$NOTIFICATION_FLAG"
fi
