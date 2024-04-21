#!/bin/bash

rofi \
  -show window \
  -kb-cancel "Alt+Escape,Escape" \
  -kb-accept-entry "!Alt-Tab,!Alt_L,Return" \
  -kb-row-down "Alt+Tab,Alt+Down" \
  -kb-row-up "Alt+ISO_Left_Tab,Alt+Up" &
xdotool keyup Tab
xdotool keydown Tab
xdotool keyup Tab
