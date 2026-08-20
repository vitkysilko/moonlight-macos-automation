#!/bin/bash

# MSI stream na vestavěné Retině
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 1728x1080 --fps 60 --bitrate 30000 "MSI" "Desktop" &

# počkej na připojení
sleep 15

MSI_PID=$(pgrep -f "Moonlight.app/Contents/MacOS/Moonlight stream")

# fullscreen
osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$MSI_PID"') to true' -e 'delay 0.3' -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'
