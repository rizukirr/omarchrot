#!/bin/bash

case "$1" in
toggle)
  # check current status
  if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off
  else
    bluetoothctl power on
  fi
  ;;
status)
  if bluetoothctl show | grep -q "Powered: yes"; then
    echo "true"
  else
    echo "false"
  fi
  ;;
*)
  echo "Usage: $0 {toggle|status}"
  exit 1
  ;;
esac
