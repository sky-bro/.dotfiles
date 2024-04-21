#!/bin/bash

function send_notification {
	notification_id=1101
	delay=2000 # 2 second
	dunstify -r $notification_id -t $delay -u normal "$1"
}

# export LC_CTYPE=zh_CN.UTF-8;

emacsclient -nc || (
	send_notification "STARTING EMACS SERVER" &&
		(
			emacs &&
				send_notification "EMACS SERVER STARTED, ENJOY!"
			# emacs --daemon &&
			#	send_notification "EMACS SERVER STARTED, ENJOY!" &&
			#	emacsclient -nc || send_notification "EMACS START FAILED!!"
		)
)
