# Moonlight na macOS: dva streamy, dva monitory, jedno kliknutí

Kompletní návod na automatizaci Moonlight streamování na Macu — vypnutí AWDL (fix microstutteringu), spuštění streamů, automatické rozmístění na monitory, fullscreen a ovládání přes ikony v Docku.

**Prostředí:** MacBook Pro 16" M1, externí monitor 3440x1440 (nad Retinou), dva hosty: „MSI" (Desktop) a „Apollo2" (Virtual Display, Apollo/SudoVDA). Dvě kopie klienta: `/Applications/Moonlight.app` a `/Applications/Moonlight2.app` (kvůli dvěma současným instancím).

**Kde žijí skripty:** přímo v tomto repu (`~/moonlight-macos-automation/scripts/`) a zkratky je odsud rovnou volají. Žádná kopie jinde na disku — jediné místo pravdy. Workflow pro úpravy: uprav → otestuj z Docku → commit + push (commituje se až ověřený stav; rozbitou úpravu vrátí `git checkout -- <soubor>`).

---

## 1. Proč vypínat AWDL

Rozhraní `awdl0` (Apple Wireless Direct Link — AirDrop, Handoff, Sidecar) periodicky skenuje éter a způsobuje microstuttering ve streamu přes Wi-Fi. Řešení: `sudo ifconfig awdl0 down`. Problém: macOS si ho samo znovu zapíná, proto běží hlídací smyčka na pozadí.

**Vedlejší efekt:** dokud smyčka běží, nefunguje AirDrop, Handoff, Sidecar a část AirPlay. Po ukončení (CloseMoonlight) se vše vrátí.

## 2. Jak se pozná, že stream opravdu běží

Klávesová zkratka pro fullscreen (Ctrl+Alt+Shift+X) funguje až po plném připojení. Čekat pevný počet sekund je nespolehlivé — reálné časy se liší podle sítě: **9 sekund na lokální síti, 24 sekund přes VPN**.

Řešení: Moonlight píše log do `/tmp/Moonlight-<timestamp>.log` a ve chvíli, kdy začne téct obraz, se v něm objeví řádek:

```
Received first video packet after 200 ms
```

Skripty tedy počkají na vznik nového logu, pak ve smyčce hlídají tenhle řádek a fullscreen pošlou přesně ve chvíli, kdy obraz naskočí. Timeout 90 s zabrání zaseknutí, když se stream nepřipojí vůbec.

## 3. Skripty

Skripty jsou ve složce `scripts/` tohoto repa. Po naklonování stačí:

```bash
chmod +x ~/moonlight-macos-automation/scripts/*.sh
```

### scripts/awdl-off.sh — spustí hlídací smyčku

```bash
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
```

Pozn.: bez `sudo` — skript volá zkratka s „Run as Administrator", takže běží pod rootem. Smyčka nepřežije restart Macu (záměrně).

### scripts/awdl-on.sh — ukončí smyčku a vrátí AWDL

```bash
#!/bin/bash
PIDFILE="/tmp/awdl_watchdog.pid"
[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
rm -f "$PIDFILE"
ifconfig awdl0 up
```

### scripts/moonlight-start.sh — oba streamy (dva monitory)

```bash
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
```

Klíčové triky:
- `--display-mode windowed` — fullscreen okno se přesouvat nedá; okenní ano.
- Souřadnice `{100, -1400}` — horní monitor je „nad" Retinou, takže má záporné Y (1440 bodů výšky → cca -1400).
- **Streamy se spouštějí postupně, ne souběžně.** Detekce hledá nejnovější logfile, a při současném startu obou klientů by se dva nové logy popletly. Trvá to o pár sekund déle, ale je to spolehlivé.
- `--bitrate` je v Kbps (30 Mbps = 30000).

### scripts/moonlight-start-solo.sh — jen MSI na Retině (bez ext. monitoru)

```bash
#!/bin/bash
# Solo rezim: MSI stream v plnem rozliseni na vestavene Retine.

LOG_BEFORE=$(ls -t /tmp/Moonlight-*.log 2>/dev/null | head -1)

/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 3456x2160 --fps 60 --bitrate 30000 "MSI" "Desktop" &

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
```

### scripts/moonlight-start-solo-light.sh — sólo režim v polovičním rozlišení

Odlehčená varianta pro slabší připojení nebo úsporu výkonu. Rozlišení 1728x1080 je přesně polovina nativních 3456x2160, takže se na Retině škáluje celočíselně a obraz zůstává ostrý.

Skript je identický s `moonlight-start-solo.sh`, jen s jiným rozlišením:

```bash
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 1728x1080 --fps 60 --bitrate 30000 "MSI" "Desktop" &
```

### scripts/moonlight-stop.sh — ukončení streamů

```bash
#!/bin/bash
pkill -f "Contents/MacOS/Moonlight stream"
```

## 4. Užitečné Moonlight CLI příkazy

```bash
# výpis aplikací na hostu
/Applications/Moonlight.app/Contents/MacOS/Moonlight list "MSI"

# všechny přepínače pro stream
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --help

# posledni log (diagnostika)
ls -t /tmp/Moonlight-*.log | head -1 | xargs cat
```

Bez CLI přepínačů se použije nastavení z GUI — pozor, obě kopie appky sdílejí bundle ID a tedy i nastavení, proto je lepší předávat parametry explicitně.

## 5. Zkratky (Shortcuts)

Zkratky volají skripty přímo z repa. Cesty s `JMENO` nahraď svým uživatelským jménem (`whoami`).

### OpenMoonlight (dva monitory)
1. **Run Shell Script**, Run as Administrator ✅: `bash /Users/JMENO/moonlight-macos-automation/scripts/awdl-off.sh`
2. **Run Shell Script**, bez administrátora: `bash /Users/JMENO/moonlight-macos-automation/scripts/moonlight-start.sh`

### OpenMoonlightSolo (jen MacBook, plné rozlišení)
1. Stejná admin akce s `awdl-off.sh`
2. `bash /Users/JMENO/moonlight-macos-automation/scripts/moonlight-start-solo.sh` (bez admina)

### OpenMoonlightSoloLight (jen MacBook, poloviční rozlišení)
1. Stejná admin akce s `awdl-off.sh`
2. `bash /Users/JMENO/moonlight-macos-automation/scripts/moonlight-start-solo-light.sh` (bez admina)

### CloseMoonlight
1. **Run Shell Script**, bez administrátora: `bash /Users/JMENO/moonlight-macos-automation/scripts/moonlight-stop.sh`
2. **Run Shell Script**, Run as Administrator ✅: `bash /Users/JMENO/moonlight-macos-automation/scripts/awdl-on.sh`

## 6. Dock a oprávnění (nejzáludnější část)

„Přidat do Docku" vyrobí ze zkratky mini-aplikaci v `~/Applications` (ne /Applications!). Ta má **vlastní identitu a vlastní oprávnění** — nezdědí je od Shortcuts.

Potřebná oprávnění v **Nastavení systému → Soukromí a zabezpečení**:

| Oprávnění | Kdo ho potřebuje | Na co |
|---|---|---|
| **Automation → System Events** | každá dock appka (OpenMoonlight.app, OpenMoonlightSolo.app, …) | přesun oken |
| **Device Control and Data Access** (dříve Accessibility) | dock appky, které posílají klávesy | keystroke pro fullscreen |

Symptomy chybějících oprávnění:
- `osascript is not allowed to send keystrokes (1002)` → chybí Device Control and Data Access pro danou dock appku. Přidat přes **+**, cesta `~/Applications` (v dialogu Cmd+Shift+G).
- Okna se nepřesouvají → chybí Automation → System Events.

**Pozor:** po smazání a novém vytvoření dock appky (např. kvůli změně ikony) vzniká nová aplikace s čistými oprávněními — celé se to musí povolit znovu. Totéž platí pro každou nově přidanou variantu zkratky. Pouhá změna obsahu shell akce (např. úprava cesty ke skriptu) oprávnění neresetuje.

## 7. Vlastní ikony

1. V aplikaci Zkratky: dvojklik na zkratku → klik na ikonku vedle názvu → barva + symbol.
2. Vytáhnout staré ikony z Docku, smazat staré obaly v `~/Applications`.
3. Pravý klik na zkratku → Add to Dock.
4. Znovu nastavit oprávnění (viz výše).

Když Dock ukazuje staré ikony (cache):

```bash
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock
killall Finder
```

Osvědčený postup: ikony z Docku odstranit → vyčistit cache → teprve pak přetáhnout appky z `~/Applications` do Docku.

## 8. DPI / škálování streamované plochy

Moonlight jen zobrazuje pixely — DPI se řeší na hostu (Windows → Nastavení → Displej → Měřítko, např. 200 % pro 3456x2160 na 16").

U **Apolla s virtual display** stačí nastavit jednou během streamu: Apollo přiřazuje každému klientovi pevnou identitu displeje, takže si Windows škálování pamatuje pro každý klient zvlášť.

Pro automatické přepínání existuje utilita **SetDPI** (Windows CLI), jde napojit na do/undo příkazy v Apollo/Sunshine.

## 9. Řešení problémů

| Problém | Řešení |
|---|---|
| Okna neskáčou na místo | Oprávnění Automation → System Events pro spouštěcí proces |
| Chyba 1002 (keystrokes) | Device Control and Data Access pro dock appku |
| Fullscreen se nezapne | Zkontrolovat log, jestli tam je „Received first video packet"; při extrémně pomalém připojení zvýšit timeout ve smyčce |
| Skript skončí, ale stream nenaběhl | Host je offline nebo nedostupný — ověřit `Moonlight list "NAZEV"` |
| Po aktualizaci macOS přestaly fungovat přesuny | macOS občas resetuje oprávnění — zkontrolovat a znovu povolit |
| Fungovalo z aplikace Zkratky, ale ne z Docku/menu baru | Každý spouštěcí kontext = jiný proces = jiná oprávnění |
| Staré ikony v Docku | Vyčistit iconservices cache (bod 7) |
| Chyby typu „unknown file attribute" při kopírování do terminálu | Terminál běží v zsh, skripty jsou psané pro bash — spouštět jako soubor, ne vkládat po řádcích |

## 10. Obnova po reinstalaci Macu — checklist

1. Nainstalovat Moonlight, vytvořit kopii `Moonlight2.app`, **spárovat oba hosty** (párování je vázané na instalaci, nepřenáší se).
2. Naklonovat repo a zprovoznit skripty:
   ```bash
   git clone https://github.com/vitkysilko/moonlight-macos-automation.git ~/moonlight-macos-automation
   chmod +x ~/moonlight-macos-automation/scripts/*.sh
   ```
3. Zkratky: při stejném Apple ID se synchronizují přes iCloud samy; jinak import ze `shortcuts/`. V obou případech zkontrolovat cesty v Run Shell Script akcích.
4. Add to Dock, nastavit ikony.
5. Povolit oprávnění (Automation + Device Control and Data Access) pro dock appky.
6. Git identita pro pushování: `git config --global user.name/user.email`, `gh auth login`.
7. Otestovat všechny režimy + Close.
