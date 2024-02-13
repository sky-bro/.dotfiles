#!/bin/bash

# This is totally chatgpt generated code!!!
# I just need to say what I want...

# If you are not satisfied with your results, give it more information, it will fix it!

BATTERY_LEVEL_THRESHOLD=${1:-20}

while true; do
    for DEVICE in $(adb devices | awk '$2 == "device" {print $1}'); do
        BATTERY_LEVEL=$(adb -s $DEVICE shell "dumpsys battery | grep level" | cut -d ":" -f 2)
        CHARGING_STATUS=$(adb -s $DEVICE shell "dumpsys battery | grep status" | cut -d ":" -f 2)
        if [ $BATTERY_LEVEL -le $BATTERY_LEVEL_THRESHOLD ] && [ "$CHARGING_STATUS" != "Charging" ]; then
            notify-send "Battery Low" "Device $DEVICE battery level is at $BATTERY_LEVEL%"
        fi
    done

    sleep 300
done
