#!/bin/bash

# 1) MSI stream – horní monitor
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 3440x1440 --fps 60 --bitrate 30000 "MSI" "Desktop" &

# 2) Apollo2 stream – Retina
/Applications/Moonlight2.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 3456x2160 --fps 60 --bitrate 10000 "Apollo2" "Virtual Display" &

# počkej, než se streamy připojí a otevřou okna
sleep 8

MSI_PID=$(pgrep -f "Moonlight.app/Contents/MacOS/Moonlight stream")
AP2_PID=$(pgrep -f "Moonlight2.app/Contents/MacOS/Moonlight stream")

# 3) MSI okno nahoru + fullscreen
osascript -e 'tell application "System Events" to tell (first process whose unix id is '"$MSI_PID"') to set position of window 1 to {100, -1400}'
osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$MSI_PID"') to true' -e 'delay 0.3' -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'

sleep 1

# 4) Apollo2 okno na Retinu + fullscreen
osascript -e 'tell application "System Events" to tell (first process whose unix id is '"$AP2_PID"') to set position of window 1 to {100, 100}'
osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$AP2_PID"') to true' -e 'delay 0.3' -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'
