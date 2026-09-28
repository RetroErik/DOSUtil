# Dreams XGA-demo — versjon 2 under utvikling

En oppstartbar DOS-demo for IBM PS/2 Model 55 SX med MCA XGA-1. Demoen viser
bildet `assets/Dreams.bmp` i 640 × 480 med 256 farger og sammenligner tre måter
å flytte et utsnitt av bildet på.

**By Dag Erik Hagesæter / Retro Erik using Codex in VS Code** ·
[Retro Erik på YouTube](https://www.youtube.com/@RetroErik)

![Platform](https://img.shields.io/badge/Platform-MS--DOS-blue)
![CPU](https://img.shields.io/badge/CPU-80386-green)
![Language](https://img.shields.io/badge/Language-NASM%20assembly-orange)
![License](https://img.shields.io/badge/License-not%20specified-lightgrey)

## Oversikt

## Versjoner

**Versjon 1** er den fungerende og testede utgaven av alle tre programmene.
Den er bevart i [`versions/v1/`](versions/v1/), med kildetekst, bilde, COM-filer,
`DREAMS.DAT`, byggeskript og diskettbildene fra kl. 20:00:09 og 20:35:22 den
26.09.2026. Bildet `versions/v1/bin/dreams_xga_20260926_203522.img` ble testet
i 86Box av brukeren. Det starter `DBLIT` automatisk. V1 skal ikke endres når
v2 utvikles.

**Versjon 2** utvikles i denne mappen. `xga_dreams.asm` er foreløpig en kopi av
v1-kilden uten funksjonelle endringer. Nye COM-filer og diskettbilder bygges i
`bin/v2/`; diskettbildene får `dreams_xga_v2_` i navnet og `BUILD.TXT` merkes
«version: 2 (development)». Første v2-bilde er
`bin/v2/dreams_xga_v2_20260928_142112.img`. Brukeren har bekreftet at denne
disketten starter DOS og kjører `DBLIT` i 86Box.

Beskrivelsen nedenfor gjelder v1 og dagens uendrede v2-utgangspunkt.

| Program | Oppdatering per løkke | Hensikt |
| --- | --- | --- |
| `DREAMS.COM` | Endrer XGAs skjermstartadresse | Viser panorering uten å kopiere hele skjermbildet hver gang |
| `DBLIT.COM` | XGA BitBLT kopierer 640 × 480 piksler internt i VRAM | Måler maskinvareblitterens emulerte kopihastighet |
| `DCPU.COM` | CPU leser fra banket VRAM via RAM og skriver til synlig VRAM | Sammenligning uten BitBLT |
| `XBALLS.COM` | XGA-fyll og 7–2048 bitmap-kopier | Kuleeffekter og belastningstest |

Bevegelsen er enkel fram-og-tilbake-panorering, beregnet per programløkke. Den
verifiserte versjonen bruker ikke sinusbevegelse.

## Funksjoner

- Tre metoder som bruker samme bilde og viser en FPS-verdi.
- Oppstartsindikator ved første lasting og VRAM-cache ved gjentatt kjøring.
- Valgfri venting på vertikal synkronisering i `DBLIT`.

## Krav og kjøring i 86Box

Maskinen må være konfigurert som PS/2 Model 55 SX med innebygd VGA
(`gfxcard = internal` i 86Box), XGA-kort og en fungerende MCA-konfigurasjon
fra IBM Reference Disk. Med `gfxcard = none` var skjermen svart helt fra POST.
Feil 162/163 ble borte etter kjøring av Reference Disk. XGA-kortet må ha 1 MB
VRAM og en aktiv 1 MB eller 4 MB minneåpning i POS. Monter v1-disketten fra
kl. 20:35:22 eller v2-bildet over som stasjon A: og start maskinen. MS-DOS
6.22 starter, og `DBLIT` kjøres fra `AUTOEXEC.BAT`.

- `S` i `DBLIT` slår venting på vertikal synkronisering av eller på. Den er av
  ved start. En `S` rett etter FPS-tallet markerer at ventingen er på.
- `Esc` går tilbake til DOS. Skriv `DREAMS`, `DBLIT` eller `DCPU` ved `A:\>` for
  å sammenligne på samme oppstartede maskin.
- Første lasting av `DREAMS.DAT` viser en fremdriftsindikator. Et merke i ledig
  VRAM lar senere kjøringer hoppe over diskettlesingen når bildet fortsatt
  finnes der. En omstart eller endring av videomodus kan gjøre ny lasting
  nødvendig.

Programmene skriver små statusfiler som `XGABOOT.TXT`, `XGADET.TXT`,
`XGAMODE.TXT` og `XGAOK.TXT` til disketten under oppstart. De er nyttige når
skjermen er svart; `XGAOK.TXT` betyr at den første BitBLT-kommandoen ble
fullført, ikke at visningen er kontrollert visuelt.

## Bygg v2

Kjør kommandoene fra denne mappen. Du trenger Python og NASM. Den genererte
filen `bin/DREAMS.DAT` og `dreams_asset.inc` ligger i prosjektet. Første gang
kopieres `DREAMS.DAT` til v2-mappen:

```text
New-Item -ItemType Directory -Force bin/v2 | Out-Null
Copy-Item bin/DREAMS.DAT bin/v2/DREAMS.DAT
nasm -f bin xga_dreams.asm -o bin/v2/DREAMS.COM -l bin/v2/DREAMS.lst
nasm -f bin -DPAN_STYLE=0 xga_dreams.asm -o bin/v2/DBLIT.COM -l bin/v2/DBLIT.lst
nasm -f bin -DPAN_STYLE=2 xga_dreams.asm -o bin/v2/DCPU.COM -l bin/v2/DCPU.lst
python make_dreams_floppy.py --program DBLIT
```

Skriptet lager en ny, tidsstemplet `.img` i `bin/v2/` og endrer ikke
kildedisketten. Det bruker den arkiverte v1-disketten som standardkilde for
DOS 6.22; `--source <sti>` velger eventuelt en annen oppstartbar 1,44 MB
DOS-diskett. `--program DREAMS` eller `--program DCPU` velger et annet program
i `AUTOEXEC.BAT`. `BUILD.TXT` inne i disketten viser versjon, byggtid og valgt
oppstartsprogram. FAT-filene får dato og klokkeslett fra byggingen.

Hvis originalbildet skal konverteres på nytt, kjør `python prepare_dreams.py`
før NASM-kommandoene. Det krever Pillow og ImageMagick. Skriptet bruker
`D:\ImageMagick-7.1.2-13-portable-Q16-x64\magick.exe` når den finnes, ellers
`magick` fra `PATH`. En ny konvertering kan gi andre bildebytes og dermed
andre COM-filer enn v1.

## XGA Balls: kuler og belastningstest

`XBALLS.COM` er en separat v2-demo. Trykk `1` for én kule i midten og seks
satellitter som roterer langs en ellipse. Trykk `2` for tretten kuler som følger
en sinuskurve. `3` starter en belastningstest med 16 kopier per ramme;
`+` dobler og `-` halverer antallet mellom 16 og 2048. De første 256 kopiene
fyller en 16 × 16-rute; ved høyere antall tegnes ruten flere ganger.
`Mellomrom` går gjennom alle tre modusene.
`T` slår maskering av eller på. `G` slår en mørk fargegradient av eller på,
slik at virkningen av `T` blir synlig. `V` slår venting på vertikal
synkronisering av eller på; den er på ved start. `Esc` avslutter.

Maskinvarespriten øverst til venstre viser `FPS` og `B` (antall kulekopier per
ramme). En
`V` etter antallet betyr at synkronisering er på. FPS beregnes fra fullførte
rammer over minst 36 BIOS-klokketikker. Tallet omfatter CPU-arbeid,
skjermfylling, BitBLT og eventuell venting på vertikal synkronisering. Det
er ikke en direkte måling av hvor stor del av tiden blitteren er opptatt, og
skjermens 60 Hz alene sier ikke hvor mange rammer demoen fullfører.

For å finne praktisk kapasitet: bruk `3`, trykk `V` slik at `V` forsvinner fra
HUD-en, og øk `B` til FPS begynner å falle. Med `V` på kan du se hvor mange
kuler som fortsatt holder skjermens oppdateringstakt. Gjenta på en fysisk
55sx; 86Box-resultatet er en måling av emulatoren. Koden bruker en
256-trinns heltallstabell uten flyttallsregning i animasjonsløkken.

Hver kule er et 48 × 48 bitmap med 16 palettfarger. Når `T` aktiveres, bruker
XGA et 1-bits mønsterkart: bit 1 kopierer kulen og bit 0 beholder bakgrunnen.
Kulen (2304 byte) og mønsteret (288 byte) lastes én gang
til VRAM rett etter skjermbufferen. XGA fyller skjermen med svart eller
tegner 16 fargestriper, og kopierer så kulene fra VRAM for hvert bilde.
Med 640 × 480 × 8 bit opptar alt dette under
310 KB av kortets 1 MB VRAM. Demoen bruker samme XGA-deteksjon, 640 × 480-modus
og timeout-håndtering som `xga_dreams.asm`.

En svart ramme behandler 307 200 piksler i skjermfyllingen og 2 304 per
kulekopi. Det gir 323 328 piksler med sju kuler, 337 152 med tretten og
897 024 med 256 og 5 025 792 med 2048. Disse tallene beskriver arbeidet,
ikke målt hastighet.

Bygg og lag en egen oppstartbar diskett fra denne mappen:

```text
python make_balls_assets.py
nasm -f bin xga_balls.asm -o bin/v2/XBALLS.COM -l bin/v2/XBALLS.lst
python make_dreams_floppy.py --program XBALLS
```

Den siste kommandoen lager `bin/v2/xga_balls_v2_<dato>.img` og setter
`XBALLS` i `AUTOEXEC.BAT`. Binærfilen kan også kopieres til en DOS-diskett og
kjøres med `XBALLS` på en PS/2 med MCA XGA-1 eller XGA-2 og 1 MB VRAM.
Bygget med utvidet belastningstest, FPS og gradient heter
`bin/v2/xga_balls_v2_20260928_151114.img`. Det tidligere bildet
`xga_balls_v2_20260928_150627.img` stopper på 256 kopier. Bildet
`xga_balls_v2_20260928_145845.img` retter `T`-feilen, men har ikke
belastningstesten. De første `xga_balls_v2_`-bildene inneholder den
feilaktige maskekartvarianten.

Brukeren har bekreftet med skjermbilde at effekten med sju roterende kuler
vises riktig i 86Box 6.0 build 9001. Brukeren har også bekreftet at
`Mellomrom` bytter effekt. I første utgave gjorde `T` skjermen svart;
maskeringen ble derfor byttet til et mønsterkart. Brukeren har deretter
bekreftet at gradienten (`G`) og maskeringen (`T`) virker. Med 256 kuler
viser HUD-en 60 FPS i 86Box. I den utvidede testen gir seks trykk på `+`
fra 16 kopier 1024 kopier og omtrent 30 FPS; sju trykk gir maksimalt 2048
kopier og omtrent 20 FPS. Flere trykk øker ikke antallet. Om `V` var på
under målingen er ikke oppgitt; 60/30/20 kan være påvirket av vertikal
synkronisering. Utseendet til sinusmodusen og ytelsen på en fysisk 55sx
er ennå ikke bekreftet.

En senere roterende zoom av et stort bilde krever en annen tilnærming. XGAs
BitBLT kopierer rektangler uten vilkårlig rotasjon eller skalering. Mange
smale striper, forhåndsberegnede bilder eller CPU-beregning kan etterligne
effekten, men hastigheten på en 386SX-16 må måles før vi velger løsning.

## Slik virker Dreams-demoen

`DREAMS.DAT` inneholder 768 byte RGB-palett fulgt av 614 400 indeksfarger
for et bilde på 960 × 640. Det synlige feltet på 640 × 480 bruker 307 200
byte i XGAs kart A, og kildebildet bruker 614 400 byte i kart B. Totalt er det
921 600 av kortets 1 048 576 byte. Bildet lastes fra diskett til VRAM én
gang; animasjonen leser deretter fra VRAM. Systemets 4 MB RAM brukes ikke
som lager for hele bildet.

Alle tre programmene viser `FPS:000.0` via XGAs 64 × 64 maskinvaresprite.
Tallet beregnes fra fullførte programløkker og BIOS-klokketikker over omtrent
to sekunder. Visningen stopper på **999,9** selv om løkken går raskere. Det er
ikke antall forskjellige bilder som skjermen faktisk har vist, og en måling i
86Box dokumenterer ikke hastigheten til et fysisk XGA-1-kort. Med `S` på
venter `DBLIT` på vertikal retrace før hver kopiering, men én synlig buffer
kan fortsatt gi tearing.

`DREAMS` endrer XGAs skjermstartadresse i stedet for å kopiere 307 200 piksler
per løkke. For at 86Box skal tegne om etter denne endringen, skriver
programmet én uendret byte per 4 KB side i kildebildet. `DBLIT` bruker XGAs
koprosessor til VRAM-til-VRAM-kopiering. `DCPU` gjør samme bildefelt via CPU
og et 640-byte radbuffer i RAM.

`xga_panorama.asm` og `make_test_floppy.py` er eldre utviklingstester. V1 kan
bygges fra `versions/v1/`; nye eksperimenter skal skje i v2-arbeidsfilene.

## Prosjektfiler og testing

| Sti | Innhold |
| --- | --- |
| `versions/v1/` | Låst v1 med `SHA256SUMS.txt` for kilde, data og disketter |
| `xga_dreams.asm` | Felles v2-kilde for de tre programmene |
| `xga_balls.asm`, `xga_balls_runtime.inc`, `xga_balls_hud.inc` | Kuleanimasjon, XGA-oppsett og FPS-sprite |
| `make_balls_assets.py`, `xga_balls_sine.inc`, `assets/xga_ball48*.bin` | Genererte bitmap, mask og sinustabell |
| `bin/v2/` | V2-programmer, byggelister, data og diskettbilder |
| `make_dreams_floppy.py` | Bygger en oppstartbar v2-diskett |

V2-byggingen er kontrollert ved at alle tre COM-filer og `DREAMS.DAT` er byte
for byte like v1 ved oppstart av v2-arbeidet. Det nye diskettbildet ble
kontrollert av byggeskriptets FAT-lesing. Brukeren har deretter startet det
i 86Box og bekreftet at `DBLIT` kjører. `DREAMS` og `DCPU` er ikke testet på
nytt fra v2-bildet.

## Skjermbilde

![Forhåndsvisning av Dreams-bildet](assets/Dreams-XGA-preview.png)

## Kreditering og lisens

**By Dag Erik Hagesæter / Retro Erik using Codex in VS Code** ·
[Retro Erik på YouTube](https://www.youtube.com/@RetroErik). Ingen lisens er
angitt for denne demoen.
