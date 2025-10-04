#!/bin/bash

OUTPUT_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"

if [[ ! -d "$OUTPUT_DIR" ]]; then
  notify-send "Screen recording directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  exit 1
fi

# Selects region or output
SCOPE="$1"

# Selects audio inclusion or not
AUDIO=$([[ $2 == "audio" ]] && echo "--audio")

start_screenrecording() {
  filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"

  # Use ffmpeg for screen recording
  if [[ "$1" == "-g" ]]; then
    # Region recording with geometry from slurp
    region="$2"
    # Parse slurp geometry (format: WIDTHxHEIGHT+X+Y)
    width_height=$(echo "$region" | cut -d'+' -f1)
    x_offset=$(echo "$region" | cut -d'+' -f2)
    y_offset=$(echo "$region" | cut -d'+' -f3)

    if [[ -n "$AUDIO" ]]; then
      ffmpeg -f pulse -i default -f x11grab -s "$width_height" -i "${DISPLAY:-:0.0}+$x_offset,$y_offset" -c:v h264_nvenc -preset fast -b:v 8M -movflags +faststart -c:a aac "$filename" &
    else
      ffmpeg -f x11grab -s "$width_height" -i "${DISPLAY:-:0.0}+$x_offset,$y_offset" -c:v h264_nvenc -preset fast -b:v 8M -movflags +faststart "$filename" &
    fi
  else
    # Full screen recording
    if [[ -n "$AUDIO" ]]; then
      ffmpeg -f pulse -i default -f x11grab -s $(xrandr | grep '\*' | awk '{print $1}' | head -1) -i ${DISPLAY:-:0.0} -c:v h264_nvenc -preset fast -b:v 8M -movflags +faststart -c:a aac "$filename" &
    else
      ffmpeg -f x11grab -s $(xrandr | grep '\*' | awk '{print $1}' | head -1) -i ${DISPLAY:-:0.0} -c:v h264_nvenc -preset fast -b:v 8M -movflags +faststart "$filename" &
    fi
  fi

  toggle_screenrecording_indicator
}

stop_screenrecording() {
  pkill -x ffmpeg

  notify-send "Screen recording saved to $OUTPUT_DIR" -t 2000

  sleep 0.2 # ensures the process is actually dead before we check
  toggle_screenrecording_indicator
}

toggle_screenrecording_indicator() {
  pkill -RTMIN+8 waybar
}

screenrecording_active() {
  pgrep -x ffmpeg >/dev/null
}

if screenrecording_active; then
  notify-send "screen record stop"
  stop_screenrecording
elif [[ "$SCOPE" == "output" ]]; then
  notify-send "screen record start"
  start_screenrecording
else
  region=$(slurp) || exit 1
  notify-send "screen record start"
  start_screenrecording -g "$region"
fi
