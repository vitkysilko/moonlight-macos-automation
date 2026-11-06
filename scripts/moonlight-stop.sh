#!/bin/bash
# Ukonci VSE: vsechny instance Moonlight/Moonlight2 na Macu (vcetne rucne otevrenych)
# a relace na obou hostech (MSI, Apollo2) - stejne jako tlacitko "stop" v Moonlightu.

# 1) zavri vsechny klienty na Macu
pkill -9 -f "Contents/MacOS/Moonlight"
sleep 0.5

# 2) ukonci relaci na hostu: pocka na "Quit response" v logu a proces hned zabije
#    (jinak by Moonlight jeste nekolik sekund zbytecne prohledaval sit).
#    Max 10 s - kdyz je host vypnuty, nevisi to.
quit_host() {
  local APP="$1" HOST="$2"
  local BEFORE LOG="" C
  BEFORE=$(ls -t /tmp/Moonlight-*.log 2>/dev/null | head -1)
  "$APP" quit "$HOST" >/dev/null 2>&1 &
  local PID=$!
  for i in $(seq 1 20); do
    kill -0 "$PID" 2>/dev/null || return 0
    if [ -z "$LOG" ]; then
      C=$(ls -t /tmp/Moonlight-*.log 2>/dev/null | head -1)
      [ -n "$C" ] && [ "$C" != "$BEFORE" ] && LOG="$C"
    fi
    [ -n "$LOG" ] && grep -q "Quit response" "$LOG" 2>/dev/null && break
    sleep 0.5
  done
  { kill -9 "$PID"; wait "$PID"; } 2>/dev/null
}

# postupne, ne paralelne (obe kopie Moonlightu sdileji nastaveni a paralelne si prekazi)
quit_host /Applications/Moonlight.app/Contents/MacOS/Moonlight "MSI"
quit_host /Applications/Moonlight2.app/Contents/MacOS/Moonlight "Apollo2"
exit 0
