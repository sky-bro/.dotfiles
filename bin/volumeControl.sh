#!/usr/bin/env bash

# You can call this script like this:
# $ ./volumeControl.sh up
# $ ./volumeControl.sh down
# $ ./volumeControl.sh mute

# sudo pacman -S pamixer

# Script modified from these wonderful people:
# https://github.com/dastorm/volume-notification-dunst/blob/master/volume.sh
# https://gist.github.com/sebastiencs/5d7227f388d93374cebdf72e783fbd6a

function get_volume {
  pamixer --get-volume
}

function is_mute {
  pamixer --get-volume-human | grep muted || [ $(pamixer --get-volume) -eq 0 ]
}

function get_icon {
  volume=$1
  if [ $volume -lt 34 ]; then
    echo 🔈
  elif [ $volume -lt 67 ]; then
    echo 🔉
  else
    echo 🔊
  fi
}

# notification not needed: use pasystray --notify=all

function send_notification {
  notification_id=2593
  expire_time=1000
  if is_mute; then
    notify-send -r $notification_id -u normal "🔇 mute"
  else
    volume=$(get_volume)
    # printf:
    #  1. one pattern used for all arguemnts
    #  2. ".x" length of output is x (default to 0 if not given)
    #  3. "%.s" print as string of 0 length

    # sed
    #  1. "s/+/-/" replace + as -
    #  2. "g" replace all
    #  3. "x" start from x-th character
    charA="█"
    charB="░"
    bar=$(printf "$charA%.s" {1..20} | sed "s/$charA/$charB/g$(((volume + 5) / 5))")
    # Send the notification
    notify-send -r $notification_id -t $expire_time -u normal "$(get_icon $volume) $volume% $bar"
  fi
}

STEP=5

case $1 in
  up)
    # unmute
    pamixer -u
    # volume up
    pamixer -i $STEP
    send_notification
    ;;
  down)
    pamixer -u
    # volume down
    pamixer -d $STEP
    send_notification
    ;;
  mute)
    # toggle mute
    pamixer -t
    send_notification
    ;;
esac
