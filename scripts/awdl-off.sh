#!/bin/bash
# Spusti systemovou sluzbu, ktera drzi awdl0 vypnute (volano s pravy admina).
PLIST="/Library/LaunchDaemons/local.moonlight.awdl-off.plist"
launchctl bootstrap system "$PLIST" 2>/dev/null || launchctl kickstart system/local.moonlight.awdl-off
ifconfig awdl0 down
