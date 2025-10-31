#!/bin/bash

screenrecording_active() {
  pgrep -x wl-screenrec >/dev/null || pgrep -x wf-recorder >/dev/null
}

if screenrecording_active; then
  echo true
else
  echo false
fi
