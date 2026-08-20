# Moonlight na macOS: dva streamy, dva monitory, jedno kliknutí

Kompletní návod na automatizaci Moonlight streamování na Macu — vypnutí AWDL (fix microstutteringu), spuštění dvou streamů najednou, automatické rozmístění na monitory, fullscreen a ovládání přes ikony v Docku.

**Prostředí:** MacBook Pro 16" M1, externí monitor 3440x1440 (nad Retinou), dva hosty: „MSI" (Desktop) a „Apollo2" (Virtual Display, Apollo/SudoVDA). Dvě kopie klienta: `/Applications/Moonlight.app` a `/Applications/Moonlight2.app` (kvůli dvěma současným instancím).

---

## 1. Proč vypínat AWDL

Rozhraní `awdl0` (Apple Wireless Direct Link — AirDrop, Handoff, Sidecar) periodicky skenuje éter a způsobuje microstuttering ve streamu přes Wi-Fi. Řešení: `sudo ifconfig awdl0 down`. Problém: macOS si ho samo znovu zapíná, proto běží hlídací smyčka na pozadí.

**Vedlejší efekt:** dokud smyčka běží, nefunguje AirDrop, Handoff, Sidecar a část AirPlay. Po ukončení (CloseMoonlight) se vše vrátí.

## 2. Skripty

Všechny skripty žijí v `~/scripts`. Vytvoření:

```bash
mkdir -p ~/scripts
```

### ~/scripts/awdl-off.sh — spustí hlídací smyčku

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

### ~/scripts/awdl-on.sh — ukončí smyčku a vrátí AWDL

```bash
#!/bin/bash
PIDFILE="/tmp/awdl_watchdog.pid"
[ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
rm -f "$PIDFILE"
ifconfig awdl0 up
```

### ~/scripts/moonlight-start.sh — oba streamy (dva monitory)

```bash
#!/bin/bash

# 1) MSI stream – horní monitor
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 3440x1440 --fps 60 --bitrate 30000 "MSI" "Desktop" &

# 2) Apollo2 stream – Retina
/Applications/Moonlight2.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 3456x2160 --fps 60 --bitrate 10000 "Apollo2" "Virtual Display" &

# počkej, než se streamy připojí a otevřou okna
sleep 8

MSI_PID=$(pgrep -f "Moonlight.app/Contents/MacOS/Moonlight stream")
AP2_PID=$(pgrep -f "Moonlight2.app/Contents/MacOS/Moonlight stream")

# 3) MSI okno nahoru + fullscreen
osascript -e 'tell application "System Events" to tell (first process whose unix id is '"$MSI_PID"') to set position of window 1 to {100, -1400}'
osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$MSI_PID"') to true' -e 'delay 0.3' -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'

sleep 1

# 4) Apollo2 okno na Retinu + fullscreen
osascript -e 'tell application "System Events" to tell (first process whose unix id is '"$AP2_PID"') to set position of window 1 to {100, 100}'
osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$AP2_PID"') to true' -e 'delay 0.3' -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'
```

Klíčové triky:
- `--display-mode windowed` — fullscreen okno se přesouvat nedá; okenní ano.
- Souřadnice `{100, -1400}` — horní monitor je „nad" Retinou, takže má záporné Y (1440 bodů výšky → cca -1400).
- `keystroke "x" using {control down, option down, shift down}` — Moonlight zkratka Ctrl+Alt+Shift+X pro přepnutí do fullscreenu; aktivuje se na monitoru, kde okno právě je.
- `--bitrate` je v Kbps (30 Mbps = 30000).

### ~/scripts/moonlight-start-solo.sh — jen MSI na Retině (bez ext. monitoru)

```bash
#!/bin/bash

# MSI stream na vestavěné Retině
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 3456x2160 --fps 60 --bitrate 30000 "MSI" "Desktop" &

# počkej na připojení
sleep 8

MSI_PID=$(pgrep -f "Moonlight.app/Contents/MacOS/Moonlight stream")

# fullscreen
osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$MSI_PID"') to true' -e 'delay 0.3' -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'
```

### ~/scripts/moonlight-start-solo-light.sh — sólo režim v polovičním rozlišení

Odlehčená varianta pro slabší připojení nebo úsporu výkonu. Rozlišení 1728x1080 je přesně polovina nativních 3456x2160, takže se na Retině škáluje celočíselně a obraz zůstává ostrý.

```bash
#!/bin/bash

# MSI stream na vestavěné Retině
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --display-mode windowed --resolution 1728x1080 --fps 60 --bitrate 30000 "MSI" "Desktop" &

# počkej na připojení
sleep 15

MSI_PID=$(pgrep -f "Moonlight.app/Contents/MacOS/Moonlight stream")

# fullscreen
osascript -e 'tell application "System Events" to set frontmost of (first process whose unix id is '"$MSI_PID"') to true' -e 'delay 0.3' -e 'tell application "System Events" to keystroke "x" using {control down, option down, shift down}'
```

Pozn.: delší `sleep 15` (oproti 8 s u ostatních skriptů) dává hostu víc času na přepnutí rozlišení, než se pošle zkratka pro fullscreen. Když se fullscreen občas nezapne, hodnotu je potřeba zvednout.

### ~/scripts/moonlight-stop.sh — ukončení streamů

```bash
#!/bin/bash
pkill -f "Contents/MacOS/Moonlight stream"
```

Nezapomenout na spustitelnost:

```bash
chmod +x ~/scripts/*.sh
```

## 3. Užitečné Moonlight CLI příkazy

```bash
# výpis aplikací na hostu
/Applications/Moonlight.app/Contents/MacOS/Moonlight list "MSI"

# všechny přepínače pro stream
/Applications/Moonlight.app/Contents/MacOS/Moonlight stream --help
```

Bez CLI přepínačů se použije nastavení z GUI — pozor, obě kopie appky sdílejí bundle ID a tedy i nastavení, proto je lepší předávat parametry explicitně.

## 4. Zkratky (Shortcuts)

### OpenMoonlight (dva monitory)
1. **Run Shell Script**, Run as Administrator ✅: `bash /Users/JMENO/scripts/awdl-off.sh`
2. **Run Shell Script**, bez administrátora: `bash /Users/JMENO/scripts/moonlight-start.sh`

### OpenMoonlightSolo (jen MacBook, plné rozlišení)
1. Stejná admin akce s `awdl-off.sh`
2. `bash /Users/JMENO/scripts/moonlight-start-solo.sh` (bez admina)

### OpenMoonlightSoloLight (jen MacBook, poloviční rozlišení)
1. Stejná admin akce s `awdl-off.sh`
2. `bash /Users/JMENO/scripts/moonlight-start-solo-light.sh` (bez admina)

### CloseMoonlight
1. **Run Shell Script**, bez administrátora: `bash /Users/JMENO/scripts/moonlight-stop.sh`
2. **Run Shell Script**, Run as Administrator ✅: `bash /Users/JMENO/scripts/awdl-on.sh`

## 5. Dock a oprávnění (nejzáludnější část)

„Přidat do Docku" vyrobí ze zkratky mini-aplikaci v `~/Applications` (ne /Applications!). Ta má **vlastní identitu a vlastní oprávnění** — nezdědí je od Shortcuts.

Potřebná oprávnění v **Nastavení systému → Soukromí a zabezpečení**:

| Oprávnění | Kdo ho potřebuje | Na co |
|---|---|---|
| **Automation → System Events** | každá dock appka (OpenMoonlight.app, OpenMoonlightSolo.app, …) | přesun oken |
| **Device Control and Data Access** (dříve Accessibility) | dock appky, které posílají klávesy | keystroke pro fullscreen |

Symptomy chybějících oprávnění:
- `osascript is not allowed to send keystrokes (1002)` → chybí Device Control and Data Access pro danou dock appku. Přidat přes **+**, cesta `~/Applications` (v dialogu Cmd+Shift+G).
- Okna se nepřesouvají → chybí Automation → System Events.

**Pozor:** po smazání a novém vytvoření dock appky (např. kvůli změně ikony) vzniká nová aplikace s čistými oprávněními — celé se to musí povolit znovu. Totéž platí pro každou nově přidanou variantu zkratky.

## 6. Vlastní ikony

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

## 7. DPI / škálování streamované plochy

Moonlight jen zobrazuje pixely — DPI se řeší na hostu (Windows → Nastavení → Displej → Měřítko, např. 200 % pro 3456x2160 na 16").

U **Apolla s virtual display** stačí nastavit jednou během streamu: Apollo přiřazuje každému klientovi pevnou identitu displeje, takže si Windows škálování pamatuje pro každý klient zvlášť.

Pro automatické přepínání existuje utilita **SetDPI** (Windows CLI), jde napojit na do/undo příkazy v Apollo/Sunshine.

## 8. Řešení problémů

| Problém | Řešení |
|---|---|
| Okna neskáčou na místo | Oprávnění Automation → System Events pro spouštěcí proces |
| Chyba 1002 (keystrokes) | Device Control and Data Access pro dock appku |
| Fullscreen se občas nezapne | Zvýšit `sleep` ve skriptu — host nestihl přepnout rozlišení |
| Po aktualizaci macOS přestaly fungovat přesuny | macOS občas resetuje oprávnění — zkontrolovat a znovu povolit |
| Host nenalezen | Ověřit přesný název: `Moonlight list "NAZEV"` |
| Fungovalo z aplikace Zkratky, ale ne z Docku/menu baru | Každý spouštěcí kontext = jiný proces = jiná oprávnění |
| Staré ikony v Docku | Vyčistit iconservices cache (bod 6) |

## 9. Obnova po reinstalaci Macu — checklist

1. Nainstalovat Moonlight, vytvořit kopii `Moonlight2.app`, spárovat oba hosty.
2. Obnovit `~/scripts` (ze zálohy/gitu), `chmod +x ~/scripts/*.sh`.
3. Znovu vytvořit zkratky (nebo je mít exportované — v aplikaci Zkratky přetažením dlaždice do Finderu, případně přes Sdílet → Kopírovat odkaz na iCloud).
4. Add to Dock, nastavit ikony.
5. Povolit oprávnění (Automation + Device Control and Data Access) pro dock appky.
6. Otestovat všechny režimy + Close.
