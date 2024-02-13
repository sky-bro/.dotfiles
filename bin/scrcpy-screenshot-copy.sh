#!/usr/bin/env bash

# focus on a scrcpy window, with window title set to device serial
# bind this

serial=$(xprop -id $(xprop -root _NET_ACTIVE_WINDOW | grep -oP 'id # \K\S+') WM_NAME | cut -d '"' -f 2)

adb -s "$serial" get-state && adb -s "$serial" exec-out screencap -p | copyq copy image/png - && notify-send "screen copied to clipboard" -t 1000 || dunstify "failed" -t 1000
