#!/bin/bash

ffmpeg -f alsa -i default "$HOME/Music/$(date +%Y%m%d_%H%M%S).wav"
