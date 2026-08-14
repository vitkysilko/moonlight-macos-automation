#!/bin/bash
PIDFILE="/tmp/awdl_watchdog.pid"
[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
rm -f "$PIDFILE"
ifconfig awdl0 up
