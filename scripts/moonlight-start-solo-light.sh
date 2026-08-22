#!/bin/bash
# Solo rezim LIGHT: MSI stream v polovicnim rozliseni (1728x1080) na vestavene Retine.

LOG_BEFORE=$(ls -t /tmp/Moonlight-*.log 2>/dev/null | head -1)

/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 1728x1080 --fps 60 --bitrate 3000 "MSI" "Desktop" &

# --- pockej az realne nabehne obraz ---
LOG=""
for i in $(seq 1 40); do
  CANDIDATE=$(ls -t /tmp/Moonlight-*.log 2>/dev/null | head -1)
  if [ -n "$CANDIDATE" ] && [ "$CANDIDATE" != "$LOG_BEFORE" ]; then
    LOG="$CANDIDATE"
    break
  fi
  sleep 0.5
done

for i in $(seq 1 180); do
  grep -q "Received first video packet" "$LOG" 2>/dev/null && break
  sleep 0.5
done

MSI_PID=$(pgrep -f "Moonlight.app/Contents/MacOS/Moonlight stream")

# fullscreen
osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$MSI_PID"') to true' \
          -e 'delay 0.3' \
          -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'
