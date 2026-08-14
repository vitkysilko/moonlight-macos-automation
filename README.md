# mac-setup

Automatizace Moonlight streamování na macOS — skripty, zkratky a návody pro rychlou obnovu po reinstalaci Macu.

## Co to dělá

Jedno kliknutí v Docku místo pěti ručních kroků:

- 🟢 **OpenMoonlight** — vypne AWDL (fix microstutteringu na Wi-Fi), spustí dva Moonlight streamy s přesnými parametry, rozmístí okna na monitory a přepne je do fullscreenu
- 🔵 **OpenMoonlightSolo** — jeden stream na vestavěném displeji (režim bez externího monitoru)
- 🔴 **CloseMoonlight** — ukončí streamy a vrátí AWDL (AirDrop, Handoff) do normálu

## Struktura repa

```
mac-setup/
├── README.md            ← tento soubor
├── docs/
│   └── moonlight-macos-setup.md   ← kompletní návod krok za krokem
├── scripts/
│   ├── awdl-off.sh      ← hlídací smyčka držící awdl0 vypnuté
│   ├── awdl-on.sh       ← ukončení smyčky, návrat AWDL
│   ├── moonlight-start.sh       ← oba streamy (dva monitory)
│   ├── moonlight-start-solo.sh  ← sólo režim (jen MacBook)
│   └── moonlight-stop.sh        ← ukončení streamů
└── shortcuts/
    └── odkazy.md / *.shortcut   ← exportované zkratky nebo iCloud odkazy
```

## ⚠️ Než to použiješ: uprav si cesty

Zkratky i návod počítají se skripty v domovské složce konkrétního uživatele:

```
/Users/vitkysilko/scripts/...
```

Po importu zkratek si v každé akci **Run Shell Script** přepiš cestu na svoje uživatelské jméno (zjistíš ho příkazem `whoami`), např.:

```
bash /Users/TVOJE_JMENO/scripts/moonlight-start.sh
```

Stejně tak si ve skriptech uprav:

- **názvy hostů** („MSI", „Apollo2") podle toho, jak se jmenují tvoje počítače v Moonlightu (ověříš: `/Applications/Moonlight.app/Contents/MacOS/Moonlight list "NAZEV"`),
- **rozlišení, fps a bitrate** podle svých monitorů a sítě,
- **souřadnice oken** v `moonlight-start.sh` podle uspořádání svých displejů (monitor nad hlavním má záporné Y).

## Instalace ve zkratce

1. Naklonuj repo a nasaď skripty:
   ```bash
   git clone https://github.com/vitkysilko/moonlight-macos-automation.git
   mkdir -p ~/scripts
   cp mac-setup/scripts/*.sh ~/scripts/
   chmod +x ~/scripts/*.sh
   ```
2. Naimportuj zkratky ze `shortcuts/` a uprav v nich cesty (viz výše).
3. Přidej zkratky do Docku a **povol oprávnění** — bez toho nebude fungovat přesun oken ani fullscreen:
   - Nastavení systému → Soukromí a zabezpečení → **Automation** → System Events
   - Nastavení systému → Soukromí a zabezpečení → **Device Control and Data Access** (dříve Accessibility) — přidat dock appky z `~/Applications`

Detailní postup včetně řešení problémů: [docs/moonlight-macos-setup.md](docs/moonlight-macos-setup.md)

## Požadavky

- macOS (testováno na MacBook Pro 16" M1)
- [Moonlight](https://moonlight-stream.org/) — pro dva současné streamy dvě kopie: `Moonlight.app` a `Moonlight2.app`
- Na hostech Sunshine nebo [Apollo](https://github.com/ClassicOldSong/Apollo) (virtual display)
