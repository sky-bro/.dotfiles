#!/bin/bash

function usage() {
  echo "Stop the old process, and create a new one"
  echo "usage: ${0} app arguments"
}

if [ $# -lt 1 ]; then
  usage
fi

app="$1"

# sends TERM signal to stop old process
pgrep "$app" | xargs -rn1 kill
exec "${@:1}"
