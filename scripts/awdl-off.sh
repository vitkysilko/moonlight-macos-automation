#!/bin/bash
PIDFILE="/tmp/awdl_watchdog.pid"
[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
nohup /bin/bash -c '
while true; do
  ifconfig awdl0 | grep -q "status: active" && ifconfig awdl0 down
  sleep 1
done
' >/dev/null 2>&1 &
echo $! > "$PIDFILE"
