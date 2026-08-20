#!/bin/bash
# Spusti oba streamy, pocka az realne nabehne obraz, rozmisti okna a prepne do fullscreenu.

# --- funkce: pocka na novy Moonlight log a v nem na prvni video paket ---
cekej_na_obraz() {
  local BEFORE="$1"
  local LOG=""
  # najdi novy logfile (max 20 s)
  for i in $(seq 1 40); do
    local CANDIDATE
    CANDIDATE=$(ls -t /tmp/Moonlight-*.log 2>/dev/null | head -1)
    if [ -n "$CANDIDATE" ] && [ "$CANDIDATE" != "$BEFORE" ]; then
      LOG="$CANDIDATE"
      break
    fi
    sleep 0.5
  done
  [ -z "$LOG" ] && return 1
  # cekej na prvni video paket (max 90 s)
  for i in $(seq 1 180); do
    grep -q "Received first video packet" "$LOG" 2>/dev/null && return 0
    sleep 0.5
  done
  return 1
}

# --- funkce: prepne okno procesu do fullscreenu ---
fullscreen() {
  local PID="$1"
  osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$PID"') to true' \
            -e 'delay 0.3' \
            -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'
}

# === 1) MSI stream - horni monitor ===
LOG_BEFORE=$(ls -t /tmp/Moonlight-*.log 2>/dev/null | head -1)
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 3440x1440 --fps 60 --bitrate 30000 "MSI" "Desktop" &
cekej_na_obraz "$LOG_BEFORE"

MSI_PID=$(pgrep -f "Moonlight.app/Contents/MacOS/Moonlight stream")
osascript -e 'tell application "System Events" to tell (first process whose unix id is '"$MSI_PID"') to set position of window 1 to {100, -1400}'
fullscreen "$MSI_PID"

# === 2) Apollo2 stream - Retina ===
LOG_BEFORE=$(ls -t /tmp/Moonlight-*.log 2>/dev/null | head -1)
/Applications/Moonlight2.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 3456x2160 --fps 60 --bitrate 10000 "Apollo2" "Virtual Display" &
cekej_na_obraz "$LOG_BEFORE"

AP2_PID=$(pgrep -f "Moonlight2.app/Contents/MacOS/Moonlight stream")
osascript -e 'tell application "System Events" to tell (first process whose unix id is '"$AP2_PID"') to set position of window 1 to {100, 100}'
fullscreen "$AP2_PID"
