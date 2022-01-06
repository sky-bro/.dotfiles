#!/bin/bash

function send_notification {
  notification_id=1101
  delay=2000 # 2 second
  dunstify -r $notification_id -t $delay -u normal "$1"
}

emacsclient -nc || ( \
  send_notification "STARTING EMACS SERVER" && \
    (emacs --daemon && \
      send_notification "EMACS SERVER STARTED, ENJOY!" && \
      emacsclient -nc || send_notification "EMACS START FAILED!!" \
    ) \
)
