#!/usr/bin/env bash

# You can call this script like this:
# $ ./volumeControl.sh up
# $ ./volumeControl.sh down
# $ ./volumeControl.sh mute

# Script modified from these wonderful people:
# https://github.com/dastorm/volume-notification-dunst/blob/master/volume.sh
# https://gist.github.com/sebastiencs/5d7227f388d93374cebdf72e783fbd6a

function get_volume {
	amixer get Master | grep '%' | head -n 1 | cut -d '[' -f 2 | cut -d '%' -f 1
}

function is_mute {
	amixer get Master | grep '%' | grep -oE '[^ ]+$' | grep off >/dev/null
}

# notification not needed: use pasystray --notify=all

# function send_notification {
#   icon_theme="Adwaita"
#   iconSound="audio-volume-high"
#   iconMuted="audio-volume-muted"
#   if is_mute ; then
#     dunstify -i $iconMuted -r 2593 -u normal "mute"
#   else
#     volume=$(get_volume)
#     # Make the bar with the special character ─ (it's not dash -)
#     # https://en.wikipedia.org/wiki/Box-drawing_character
#     bar=$(printf '+%.0s' {1..20} | sed "s/+/─/g$(((volume+5)/5))")
#     # bar=$(seq --separator="─" 0 "$((volume / 5))" | sed 's/[0-9]//g')
#     # Send the notification
#     dunstify -i $iconSound -r 2593 -t 1000 -u normal "$volume% $bar"
#   fi
# }

case $1 in
up)
	# set the volume on (if it was muted)
	# amixer -D pulse set Master on > /dev/null
	pactl set-sink-mute @DEFAULT_SINK@ false
	# up the volume (+ 5%)
	# amixer -D pulse sset Master 5%+ > /dev/null
	pactl set-sink-volume @DEFAULT_SINK@ +5%
	# send_notification
	;;
down)
	# amixer -D pulse set Master on > /dev/null
	pactl set-sink-mute @DEFAULT_SINK@ false
	# amixer -D pulse sset Master 5%- > /dev/null
	pactl set-sink-volume @DEFAULT_SINK@ -5%
	# send_notification
	;;
mute)
	# toggle mute
	# amixer -D pulse set Master 1+ toggle > /dev/null
	pactl set-sink-mute @DEFAULT_SINK@ toggle
	# send_notification
	;;
esac
