#!/bin/sh

# notification_id=1998
notify-send -r 1998 "click the window you want to kill"

# look behind & look ahead
# https://unix.stackexchange.com/questions/437405/opposite-of-k-to-keep-the-stuff-right
# IIRC the difference between pat\K and (?<=pat) is that \K permits variable-length lookbehind
# AFAIK there's no such restriction for the lookahead version
# which is perhaps why there's no lookahead equivalent of \K

xprop WM_NAME _NET_WM_PID \
  | grep -oP '_NET_WM_PID[^0-9]+\K\d+|WM_NAME[^"]+"\K.+(?="$)' \
  | xargs -d'\n' sh -c 'notify-send -r 1998 "killing window \"$0\" with pid $1" && kill -9 $1'
