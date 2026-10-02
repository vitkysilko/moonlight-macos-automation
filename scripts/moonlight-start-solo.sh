#!/bin/bash
# Solo rezim: MSI stream v plnem rozliseni na vestavene Retine.
# Rychla verze: Moonlight startuje rovnou ve fullscreenu (borderless = pod vyrezem),
# skript na nic neceka a hned konci -> zadny AppleScript, zadne cekani na log.

# === 0) nejdriv natvrdo ukoncit pripadne bezici streamy (napr. po zavreni vika) ===
bash "$(dirname "$0")/moonlight-stop.sh"

nohup /Applications/Moonlight.app/Contents/MacOS/Moonlight stream --no-absolute-mouse --no-quit-after --display-mode borderless --resolution 3456x2160 --fps 60 --bitrate 30000 "MSI" "Desktop" >/dev/null 2>&1 &
