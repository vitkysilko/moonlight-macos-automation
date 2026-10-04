#!/bin/bash
# Automaticky start po probuzeni Macu (vola ~/.wakeup ze SleepWatcheru).
# Rezim podle externiho monitoru: 3440 -> dual, 2560 -> dual 2K, zadny -> SoloLight.
# SoloLight startuje hned (i na zamcene obrazovce); dvoumonitorove rezimy posilaji
# klavesy pres AppleScript, proto cekaji na odemceni.
DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_IP="10.20.60.243"        # MSI (Apollo, HTTP port 47989)
LOCK="/tmp/moonlight-auto.lock"
exec >>/tmp/moonlight-auto.log 2>&1
echo "=== $(date '+%F %T') probuzeni"

mkdir "$LOCK" 2>/dev/null || { echo "uz bezi jina instance, konec"; exit 0; }
trap 'rmdir "$LOCK"' EXIT

# 1) externi monitor: zkusit hned a po 1 s (pozdni monitor resi hlidani v kroku 4)
externi() { system_profiler SPDisplaysDataType 2>/dev/null | grep -oE "Resolution: (3440|2560) x 1440" | head -1 | awk '{print $2}'; }
W=$(externi)
[ -z "$W" ] && { sleep 1; W=$(externi); }
echo "$(date '+%T') externi monitor: ${W:-zadny}"

# 2) sit (Wi-Fi/VPN) se po probuzeni teprve pripojuje -> cekat na MSI max 30 s
for i in $(seq 1 30); do
  nc -z -G 1 "$HOST_IP" 47989 2>/dev/null && break
  sleep 1
done
if ! nc -z -G 1 "$HOST_IP" 47989 2>/dev/null; then
  echo "$(date '+%T') MSI nedostupny, nic nespoustim"
  exit 0
fi
echo "$(date '+%T') MSI dostupny"

# 3) zamcena obrazovka? (klic CGSSessionScreenIsLocked existuje jen pri zamceni)
cekej_na_odemceni() {
  for i in $(seq 1 1200); do           # max 10 min
    ioreg -n Root -d1 | grep -q CGSSessionScreenIsLocked || return 0
    sleep 0.5
  done
  echo "$(date '+%T') obrazovka se neodemkla, konec"
  return 1
}

spust_dual() {
  cekej_na_odemceni || return
  if [ "$1" = 3440 ]; then echo "$(date '+%T') start dual 3440"; bash "$DIR/moonlight-start.sh"
  else                     echo "$(date '+%T') start dual 2K";   bash "$DIR/moonlight-start-2k.sh"; fi
}

if [ -n "$W" ]; then
  spust_dual "$W"
else
  echo "$(date '+%T') start SoloLight"
  bash "$DIR/moonlight-start-solo-light.sh"
  # 4) monitor se po probuzeni obcas ohlasi pozde -> 15 s hlidat a pripadne prepnout
  for i in $(seq 1 10); do
    sleep 1.5
    W=$(externi)
    if [ -n "$W" ]; then
      echo "$(date '+%T') monitor ${W} se objevil pozdeji -> prepinam"
      spust_dual "$W"
      break
    fi
  done
fi
echo "$(date '+%T') hotovo"
