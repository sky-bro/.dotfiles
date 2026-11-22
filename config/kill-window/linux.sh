#!/bin/sh
set -eu

notify-send -r 1998 'Click the window to close'
properties=$(xprop _NET_WM_PID)
pid=$(printf '%s\n' "$properties" | awk '/^_NET_WM_PID\(CARDINAL\) = [0-9]+$/ { print $NF }')

case "$pid" in
  ''|*[!0-9]*) echo 'No process ID found for the selected window.' >&2; exit 1 ;;
esac
[ "$pid" -gt 1 ] || exit 1
notify-send -r 1998 "Force quitting PID $pid"
kill -KILL "$pid"
