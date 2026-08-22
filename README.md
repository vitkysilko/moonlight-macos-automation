# moonlight-macos-automation

Automatizace Moonlight streamování na macOS — skripty, zkratky a návody pro rychlou obnovu po reinstalaci Macu.

## Co to dělá

Jedno kliknutí v Docku místo pěti ručních kroků:

- 🟢 **OpenMoonlight** — vypne AWDL (fix microstutteringu na Wi-Fi), spustí dva Moonlight streamy s přesnými parametry, rozmístí okna na monitory a přepne je do fullscreenu
- 🔵 **OpenMoonlightSolo** — jeden stream v plném rozlišení na vestavěném displeji (režim bez externího monitoru)
- 🟡 **OpenMoonlightSoloLight** — totéž v polovičním rozlišení (1728x1080) pro slabší síť nebo úsporu výkonu; na Retině zůstává obraz ostrý, protože jde přesně o polovinu nativního rozlišení
- 🔴 **CloseMoonlight** — ukončí streamy a vrátí AWDL (AirDrop, Handoff) do normálu

Skripty **nečekají pevný počet sekund** — sledují Moonlight log a fullscreen přepnou přesně ve chvíli, kdy dorazí první video paket. Doba připojení se totiž liší podle sítě (9 s lokálně vs. 24 s přes VPN) a pevná prodleva to nikdy netrefí spolehlivě.

## Jak je to zapojené

Zkratky volají skripty **přímo z tohoto repa** (žádná kopie jinde na disku — jediné místo pravdy):

```
zkratka v Docku → bash ~/moonlight-macos-automation/scripts/<skript>.sh
```

Workflow pro úpravy: **uprav skript v repu → otestuj z Docku → `git commit` + `git push`.** Commituje se až ověřený stav; rozbitou úpravu vrátí `git checkout -- <soubor>`.

## Struktura repa

```
moonlight-macos-automation/
├── README.md            ← tento soubor
├── LICENSE
├── docs/
│   └── moonlight-macos-setup.md   ← kompletní návod krok za krokem
├── scripts/
│   ├── awdl-off.sh      ← hlídací smyčka držící awdl0 vypnuté
│   ├── awdl-on.sh       ← ukončení smyčky, návrat AWDL
│   ├── moonlight-start.sh            ← oba streamy (dva monitory)
│   ├── moonlight-start-solo.sh       ← sólo režim, plné rozlišení
│   ├── moonlight-start-solo-light.sh ← sólo režim, poloviční rozlišení
│   └── moonlight-stop.sh             ← ukončení streamů
└── shortcuts/
    └── odkazy.md / *.shortcut   ← exportované zkratky nebo iCloud odkazy
```

## ⚠️ Než to použiješ: uprav si cesty

Zkratky volají skripty na absolutní cestě konkrétního uživatele:

```
/Users/vitkysilko/moonlight-macos-automation/scripts/...
```

Po importu zkratek si v každé akci **Run Shell Script** přepiš cestu na svoje uživatelské jméno (zjistíš ho příkazem `whoami`), např.:

```
bash /Users/TVOJE_JMENO/moonlight-macos-automation/scripts/moonlight-start.sh
```

Stejně tak si ve skriptech uprav:

- **názvy hostů** („MSI", „Apollo2") podle toho, jak se jmenují tvoje počítače v Moonlightu (ověříš: `/Applications/Moonlight.app/Contents/MacOS/Moonlight list "NAZEV"`),
- **rozlišení, fps a bitrate** podle svých monitorů a sítě,
- **souřadnice oken** v `moonlight-start.sh` podle uspořádání svých displejů (monitor nad hlavním má záporné Y).

## Instalace ve zkratce

1. Naklonuj repo do domovské složky a udělej skripty spustitelnými:
   ```bash
   git clone https://github.com/vitkysilko/moonlight-macos-automation.git ~/moonlight-macos-automation
   chmod +x ~/moonlight-macos-automation/scripts/*.sh
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
