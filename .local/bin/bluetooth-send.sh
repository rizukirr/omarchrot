#!/bin/bash

# --- Get file path from user ---
echo "Select file to send (use fzf to browse)"
FILE=$(find ~/ -type f 2>/dev/null | fzf --preview 'head -20 {}')

if [ -z "$FILE" ]; then
  echo "Error: No file selected"
  exit 1
fi

# Expand ~ and $HOME to absolute path
FILE="${FILE/#\~/$HOME}"
FILE=$(eval echo "$FILE")
FILE=$(realpath "$FILE")

if [ ! -f "$FILE" ]; then
  echo "Error: File not found -> $FILE"
  exit 1
fi

echo "File to send: $FILE"
echo

# --- Bluetooth initialization functions ---

# Check and unblock bluetooth via rfkill
check_rfkill() {
  echo "Checking rfkill status..."
  while rfkill list bluetooth | grep -q "Soft blocked: yes"; do
    echo "Bluetooth is blocked. Unblocking..."
    sudo rfkill unblock bluetooth
    sleep 1
    if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
      echo "Failed to unblock. Retrying..."
      sleep 1
    else
      echo "✓ Bluetooth unblocked"
      return 0
    fi
  done
  echo "✓ Bluetooth is not blocked"
  return 0
}

# Check and start bluetooth service
check_service() {
  echo "Checking Bluetooth service..."
  local retry=0
  while ! systemctl is-active --quiet bluetooth; do
    if [ $retry -ge 3 ]; then
      echo "Error: Failed to start Bluetooth service after 3 attempts"
      return 1
    fi
    echo "Bluetooth service is not running. Starting..."
    sudo systemctl start bluetooth
    sleep 2
    retry=$((retry + 1))
  done
  echo "✓ Bluetooth service is running"
  return 0
}

# Power on bluetooth controller
power_on_bluetooth() {
  echo "Powering on Bluetooth controller..."
  local retry=0
  while true; do
    if [ $retry -ge 5 ]; then
      echo "Error: Failed to power on Bluetooth after 5 attempts"
      return 1
    fi

    if bluetoothctl show | grep -q "Powered: yes"; then
      echo "✓ Bluetooth powered on"
      return 0
    else
      bluetoothctl power on >/dev/null 2>&1
      echo "Bluetooth not powered on. Retrying..."
      retry=$((retry + 1))
      sleep 1
    fi
  done
}

pairable_bluetooth() {
  echo "Checking Bluetooth pairable status.."
  local retry=0
  while true; do
    if [ $retry -ge 5 ]; then
      echo "Error: Failed to make Bluetooth pairable after 5 attempts"
      return 1
    fi

    if bluetoothctl show | grep -q "Pairable: yes"; then
      echo "✓ Bluetooth pairable"
      return 0
    else
      bluetoothctl pairable on >/dev/null 2>&1
      echo "Bluetooth not pairable, Retrying.."
      retry=$((retry + 1))
      sleep 1
    fi
  done
}

discoverable_bluetooth() {
  echo "Checking Bluetooth discoverable status.."
  local retry=0
  while true; do
    if [ $retry -ge 5 ]; then
      echo "Error: Failed to make Bluetooth discoverable after 5 attempts"
      return 1
    fi

    if bluetoothctl show | grep -q "Discoverable: yes"; then
      echo "✓ Bluetooth discoverable"
      return 0
    else
      bluetoothctl discoverable on >/dev/null 2>&1
      echo "Bluetooth not discoverable, Retrying.."
      retry=$((retry + 1))
      sleep 1
    fi
  done
}

# Setup bluetooth agent
setup_agent() {
  echo "Setting up Bluetooth agent..."
  {
    echo "agent on"
    sleep 0.5
    echo "default-agent"
    sleep 0.5
  } | bluetoothctl >/dev/null 2>&1
  echo "✓ Bluetooth agent ready"
  return 0
}

# --- Initialize Bluetooth ---
echo "Initializing Bluetooth..."
echo

check_rfkill || exit 1
echo

check_service || exit 1
echo

power_on_bluetooth || exit 1
echo

setup_agent || exit 1
echo

pairable_bluetooth || exit 1
echo

discoverable_bluetooth || exit 1

echo "Bluetooth initialization complete!"
echo

# --- Function to scan for devices ---
scan_devices() {
  echo "Clearing old device cache..."
  bluetoothctl devices | awk '{print $2}' | while read -r mac; do
    bluetoothctl remove "$mac" >/dev/null 2>&1
  done

  echo "Scanning for nearby Bluetooth devices (8s)..."
  SCAN_OUTPUT=$(timeout 8s bluetoothctl --timeout 8 scan on 2>/dev/null | grep "Device")

  # Extract unique devices (avoid duplicates)
  DEVICES=$(echo "$SCAN_OUTPUT" | awk '/Device/ {mac=$3; name=substr($0, index($0,$4)); if (!seen[mac]++) print mac, name}')

  if [ -z "$DEVICES" ]; then
    echo "No devices found."
    return 1
  fi

  echo
  echo "Available devices:"
  echo "$DEVICES" | nl -w2 -s". "
  return 0
}

# --- Initial scan ---
scan_devices

# --- Choose device with rescan option ---
while true; do
  echo
  echo "Enter device number or 'r' to rescan"
  read -r -p "Selection: " NUM

  if [ "$NUM" = "r" ] || [ "$NUM" = "R" ]; then
    echo
    scan_devices
    continue
  fi

  break
done

MAC=$(echo "$DEVICES" | sed -n "${NUM}p" | awk '{print $1}')
NAME=$(echo "$DEVICES" | sed -n "${NUM}p" | cut -d' ' -f2-)

if [ -z "$MAC" ]; then
  echo "Invalid selection"
  exit 1
fi

echo "Selected: $NAME ($MAC)"
echo

# --- Pair device with retry ---
pair_device() {
  local mac="$1"
  local retry=0
  local max_retries=5

  echo "Pairing device $mac..."

  while [ $retry -lt $max_retries ]; do
    INFO=$(bluetoothctl info "$mac" 2>/dev/null)
    PAIRED=$(echo "$INFO" | grep "Paired:" | awk '{print $2}')

    if [[ "$PAIRED" == "yes" ]]; then
      echo "✓ Device already paired"
      return 0
    fi

    echo "Attempt $((retry + 1))/$max_retries - Pairing..."
    if echo -e "pair $mac\nyes" | bluetoothctl 2>&1 | grep -q "Pairing successful\|AlreadyExists"; then
      echo "✓ Paired successfully"
      return 0
    fi

    retry=$((retry + 1))
    [ $retry -lt $max_retries ] && sleep 2
  done

  echo "✗ Failed to pair after $max_retries attempts"
  return 1
}

# --- Trust device with retry ---
trust_device() {
  local mac="$1"
  local retry=0
  local max_retries=5

  echo "Trusting device $mac..."

  while [ $retry -lt $max_retries ]; do
    INFO=$(bluetoothctl info "$mac" 2>/dev/null)
    TRUSTED=$(echo "$INFO" | grep "Trusted:" | awk '{print $2}')

    if [[ "$TRUSTED" == "yes" ]]; then
      echo "✓ Device already trusted"
      return 0
    fi

    echo "Attempt $((retry + 1))/$max_retries - Trusting..."
    bluetoothctl trust "$mac" >/dev/null 2>&1
    sleep 1

    INFO=$(bluetoothctl info "$mac" 2>/dev/null)
    TRUSTED=$(echo "$INFO" | grep "Trusted:" | awk '{print $2}')

    if [[ "$TRUSTED" == "yes" ]]; then
      echo "✓ Trusted successfully"
      return 0
    fi

    retry=$((retry + 1))
    [ $retry -lt $max_retries ] && sleep 1
  done

  echo "✗ Failed to trust after $max_retries attempts"
  return 1
}

# --- Unblock device with retry ---
unblock_device() {
  local mac="$1"
  local retry=0
  local max_retries=5

  echo "Unblocking device $mac..."

  while [ $retry -lt $max_retries ]; do
    INFO=$(bluetoothctl info "$mac" 2>/dev/null)
    BLOCKED=$(echo "$INFO" | grep "Blocked:" | awk '{print $2}')

    if [[ "$BLOCKED" == "no" ]]; then
      echo "✓ Device not blocked"
      return 0
    fi

    echo "Attempt $((retry + 1))/$max_retries - Unblocking..."
    bluetoothctl unblock "$mac" >/dev/null 2>&1
    sleep 1

    INFO=$(bluetoothctl info "$mac" 2>/dev/null)
    BLOCKED=$(echo "$INFO" | grep "Blocked:" | awk '{print $2}')

    if [[ "$BLOCKED" == "no" ]]; then
      echo "✓ Unblocked successfully"
      return 0
    fi

    retry=$((retry + 1))
    [ $retry -lt $max_retries ] && sleep 1
  done

  echo "✗ Failed to unblock after $max_retries attempts"
  return 1
}

# --- Connect device with retry ---
connect_device() {
  local mac="$1"
  local retry=0
  local max_retries=5

  echo "Connecting to device $mac..."

  while [ $retry -lt $max_retries ]; do
    INFO=$(bluetoothctl info "$mac" 2>/dev/null)
    CONNECTED=$(echo "$INFO" | grep "Connected:" | awk '{print $2}')

    if [[ "$CONNECTED" == "yes" ]]; then
      echo "✓ Device already connected"
      return 0
    fi

    echo "Attempt $((retry + 1))/$max_retries - Connecting..."
    bluetoothctl connect "$mac" >/dev/null 2>&1
    sleep 2

    INFO=$(bluetoothctl info "$mac" 2>/dev/null)
    CONNECTED=$(echo "$INFO" | grep "Connected:" | awk '{print $2}')

    if [[ "$CONNECTED" == "yes" ]]; then
      echo "✓ Connected successfully"
      return 0
    fi

    retry=$((retry + 1))
    [ $retry -lt $max_retries ] && sleep 2
  done

  echo "✗ Failed to connect after $max_retries attempts"
  return 1
}

# --- Prepare device for file transfer ---
echo "Preparing device $MAC for file transfer..."
echo

unblock_device "$MAC" || exit 1
echo

pair_device "$MAC" || exit 1
echo

trust_device "$MAC" || exit 1
echo

connect_device "$MAC" || exit 1
echo

# --- Send file with obexctl ---
# Start obexd if not running
if ! pgrep -x obexd >/dev/null; then
  echo "Starting obexd..."
  /usr/lib/bluetooth/obexd &
  sleep 2

  # Wait for obexd to be ready
  retry=0
  while [ $retry -lt 10 ]; do
    if obexctl --help >/dev/null 2>&1 && pgrep -x obexd >/dev/null; then
      echo "✓ obexd is ready"
      break
    fi
    sleep 0.5
    retry=$((retry + 1))
  done
fi

echo "Connecting to $MAC and sending file..."

# Create log file and named pipe
LOG_FILE="/tmp/obexctl_$$.log"
FIFO="/tmp/obexctl_fifo_$$"
mkfifo "$FIFO"

# Start obexctl with script to capture output
script -q -c "obexctl" "$LOG_FILE" <"$FIFO" &
SCRIPT_PID=$!

# Wait for obexctl to start
sleep 1

# Function to send command and wait for output
send_and_wait() {
  local cmd="$1"
  local pattern="$2"
  local timeout="${3:-30}"

  echo "$cmd" >"$FIFO"

  local elapsed=0
  while [ $elapsed -lt $timeout ]; do
    if grep -q "$pattern" "$LOG_FILE" 2>/dev/null; then
      return 0
    fi
    sleep 0.5
    elapsed=$((elapsed + 1))
  done

  echo "Timeout waiting for: $pattern"
  return 1
}

# Connect and wait for client proxy
echo "Establishing connection..."
if send_and_wait "connect $MAC" "Client /org/bluez/obex" 15; then
  echo "✓ Connected"

  # Send file and wait for completion
  echo "Sending file..."
  if send_and_wait "send $FILE" "Transfer /org/bluez/obex\|complete\|failed" 60; then
    if grep -q "failed" "$LOG_FILE"; then
      echo "✗ File transfer failed"
    else
      echo "✓ File sent successfully"
    fi
  else
    echo "✗ File transfer timeout"
  fi
else
  echo "✗ Connection failed"
  cat "$LOG_FILE"
fi

# Quit obexctl
echo "quit" >"$FIFO"
sleep 1

# Cleanup
kill $SCRIPT_PID 2>/dev/null
wait $SCRIPT_PID 2>/dev/null
rm -f "$FIFO" "$LOG_FILE"

echo "Done!"
pkill obexd

if pgrep -x obexd >/dev/null; then
  echo "obexd is running"
  echo "try run:"
  echo "\$ pidof obexd"
  echo "\$ kill <PID>"
  echo "or force kill"
  echo "\$ kill -9 <PID>"
else
  echo "obexd is not running"
fi
