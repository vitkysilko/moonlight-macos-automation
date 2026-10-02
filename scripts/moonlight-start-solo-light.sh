#!/bin/bash
# Solo rezim LIGHT: MSI stream v polovicnim rozliseni (1728x1080) na vestavene Retine.
# Rychla verze: Moonlight startuje rovnou ve fullscreenu (borderless = pod vyrezem),
# skript na nic neceka a hned konci -> zadny AppleScript, zadne cekani na log.

# === 0) nejdriv natvrdo ukoncit pripadne bezici streamy (napr. po zavreni vika) ===
bash "$(dirname "$0")/moonlight-stop.sh"

nohup /Applications/Moonlight.app/Contents/MacOS/Moonlight stream --no-absolute-mouse --no-quit-after --display-mode borderless --resolution 1728x1080 --fps 60 --bitrate 3000 "MSI" "Desktop" >/dev/null 2>&1 &
