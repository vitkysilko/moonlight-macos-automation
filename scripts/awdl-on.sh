#!/bin/bash
# Zastavi sluzbu drzici AWDL vypnute a AWDL zapne (AirDrop, Handoff).
# Po restartu Macu se sluzba spusti znovu sama (RunAtLoad) -> AWDL je zase vypnute.
launchctl bootout system/local.moonlight.awdl-off 2>/dev/null
# uklid pripadne stare smycky z drivejsi verze skriptu
PIDFILE="/tmp/awdl_watchdog.pid"
[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
rm -f "$PIDFILE"
ifconfig awdl0 up
