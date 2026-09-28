# Dreams XGA-demo — versjon 1

Dette er den låste, brukerprøvde utgaven av `DREAMS.COM`, `DBLIT.COM` og
`DCPU.COM`. Filene i denne mappen ble kopiert før arbeidet med versjon 2.
Fortsett utviklingen i `../../`, ikke her. `bin/dreams_xga_20260926_203522.img`
er diskettbildet som ble bekreftet fungerende i 86Box.

En oppstartbar DOS-demo for IBM PS/2 Model 55 SX med MCA XGA-1. Demoen viser
bildet `assets/Dreams.bmp` i 640 × 480 med 256 farger og sammenligner tre måter
å flytte et utsnitt av bildet på.

**By Dag Erik Hagesæter / Retro Erik using Codex in VS Code** ·
[Retro Erik på YouTube](https://www.youtube.com/@RetroErik)

![Platform](https://img.shields.io/badge/Platform-MS--DOS-blue)
![CPU](https://img.shields.io/badge/CPU-80386-green)
![Language](https://img.shields.io/badge/Language-NASM%20assembly-orange)

`SHA256SUMS.txt` inneholder SHA-256 for v1-kilde, bilde, COM-filer og begge
diskettbilder. Det tidligere DOS 6.22-kildebildet på `D:` trengs hvis den
opprinnelige v1-byggeren skal kjøres uten endring.

## Verifisert versjon

`bin/dreams_xga_20260926_200009.img` er referansedisketten som fungerte i
86Box. Kilden `xga_dreams.asm` er tilbakeført slik at nybygg av `DREAMS.COM`,
`DBLIT.COM` og `DCPU.COM` er byte for byte identiske med filene på den disketten.
`bin/dreams_xga_20260926_203522.img` er bygget fra denne kilden og er testet
i 86Box av brukeren. Den starter `DBLIT` automatisk.

| Program | Oppdatering per løkke | Hensikt |
| --- | --- | --- |
| `DREAMS.COM` | Endrer XGAs skjermstartadresse | Viser panorering uten å kopiere hele skjermbildet hver gang |
| `DBLIT.COM` | XGA BitBLT kopierer 640 × 480 piksler internt i VRAM | Måler maskinvareblitterens emulerte kopihastighet |
| `DCPU.COM` | CPU leser fra banket VRAM via RAM og skriver til synlig VRAM | Sammenligning uten BitBLT |

Bevegelsen er enkel fram-og-tilbake-panorering, beregnet per programløkke. Den
verifiserte versjonen bruker ikke sinusbevegelse.

## Kjøring i 86Box

Maskinen må være konfigurert som PS/2 Model 55 SX med XGA og en fungerende
MCA-konfigurasjon fra IBM Reference Disk. XGA-kortet må ha 1 MB VRAM og en
aktiv 1 MB eller 4 MB minneåpning i POS. Monter en av diskettfilene over som
stasjon A: og start maskinen. MS-DOS 6.22 starter, og `DBLIT` kjøres fra
`AUTOEXEC.BAT`.

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

## Bygg en ny diskett

Kjør kommandoene fra `XGA/xga-demo`. Du trenger Python og NASM. De allerede
genererte filene `bin/DREAMS.DAT` og `dreams_asset.inc` ligger i prosjektet.

```powershell
nasm -f bin xga_dreams.asm -o bin/DREAMS.COM -l bin/DREAMS.lst
nasm -f bin -DPAN_STYLE=0 xga_dreams.asm -o bin/DBLIT.COM -l bin/DBLIT.lst
nasm -f bin -DPAN_STYLE=2 xga_dreams.asm -o bin/DCPU.COM -l bin/DCPU.lst
python make_dreams_floppy.py --program DBLIT
```

Skriptet lager en ny, tidsstemplet `.img` i `bin/` og endrer ikke
kildedisketten. Det leser en lokal DOS 6.22-diskett fra
`D:\86Box-Windows-64-b8200\Dos622-1.img`; juster `source` i skriptet hvis
den ligger et annet sted. `--program DREAMS` eller `--program DCPU` velger et
annet program i `AUTOEXEC.BAT`. `BUILD.TXT` inne i disketten viser byggtid og
valgt oppstartsprogram. FAT-filene får også dato og klokkeslett fra byggingen.

Hvis originalbildet skal konverteres på nytt, kjør `python prepare_dreams.py`
før NASM-kommandoene. Det krever Pillow og ImageMagick. Skriptet bruker
`D:\ImageMagick-7.1.2-13-portable-Q16-x64\magick.exe` når den finnes, ellers
`magick` fra `PATH`. En ny konvertering kan gi andre bildebytes og dermed
andre COM-filer enn referansedisketten.

## Slik virker det

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

`xga_panorama.asm` og `make_test_floppy.py` er eldre utviklingstester. Den
verifiserte Dreams-disketten bygges med `xga_dreams.asm` og
`make_dreams_floppy.py`.
