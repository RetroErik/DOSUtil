# Codex Prompt: XGA 640x480x256 BitBLT Panorama Demo

> **Archived prompt:** This prompt records an earlier project setup. Its workspace
> and emulator paths are stale; it is not a current implementation checklist.
> See [xga-demo/README.md](xga-demo/README.md) for the maintained demo documentation.

Du er Codex og skal gjennomføre dette prosjektet ende til ende i workspace:

`C:\Users\hages\OneDrive\VS Code\Olivetto Prodest PC1`

## Mål

Lag en fungerende DOS COM-demo for IBM PS/2 Model 55SX med IBM XGA-1/XGA-2 i
640x480x256-fargemodus.

Demoen skal vise et stort pixel-art-bilde som kan panoreres både horisontalt og
vertikalt. Bildet skal ligge i off-screen XGA VRAM, og skjermvinduet skal flyttes
ved hjelp av XGA coprocessor BitBLT, ikke ved å kopiere hele bildet pixel for pixel
med CPU-en.

Arbeidstittel: `XGA Panorama Flight`.

## Viktig arbeidsregel

Ikke stopp etter research eller en plan. Skriv koden, bygg den, test den og start
86Box når programmet er klart.

Ikke påstå at programmet virker bare fordi NASM bygger uten feil. Det må faktisk
kjøres i 86Box, og brukeren skal kunne se resultatet.

## Teknisk mål

Prioriter først en minimal, robust test som beviser:

1. XGA-kortet kan detekteres.
2. 640x480x256 kan settes.
3. XGA-pixel maps kan konfigureres.
4. Et bilde kan lastes til off-screen VRAM.
5. En VRAM-til-VRAM SRC_COPY BitBLT kan kopiere et utsnitt til skjermen.
6. Utsnittet kan flyttes i både X- og Y-retning.
7. Programmet avslutter med ESC og gjenoppretter VGA text mode.

Når BitBLT-testen virker, bygg den ut til en synlig panoramademo med et tydelig
testmønster eller pixel-art-bilde.

## Kildemateriale som skal undersøkes først

Les og bruk eksisterende materiale i workspace før du lager nye antakelser:

- `XGA/XGA Toolkit/XGAKIT.ASM`
- `XGA/XGA Toolkit/XGAKIT.DOC`
- `XGA/XGA Toolkit/XGADEMO.C`
- `XGA/xga-win9x-main/MINI/XGA.INC`
- `XGA/xga-win9x-main/MINI/XGABLT.ASM`
- `XGA/xga-win9x-main/MINI/VGA.ASM`
- `XGA/XGA.NT40-main/xgadll/xgaregs.h`
- `XGA/XGA.NT40-main/xgadll/bitblt.c`
- `XGA/XGA.NT40-main/xgadll/screen.c`
- 86Box XGA-kilden hvis den er tilgjengelig lokalt eller via repository-kilden

86Box-emulatoren ligger her:

`D:\86Box-Windows-64-b8200\86Box.exe`

86Box-kilden viser at XGA-coprocessor-registerne ligger i MMIO-blokken, med
BitBLT-registrene rundt offset `0x60` til `0x7F`, og at en BitBLT utføres når
`PixelOperation` på offset `0x7C` skrives.

Bruk faktiske registerdefinisjoner fra kildene. Ikke finn opp registeroffsets.

## Viktige hardwarekrav

- Målmaskinen er IBM PS/2 Model 55SX, 386SX-16, MCA.
- Første mål er XGA-1-kompatibilitet.
- XGA-2-spesifikke funksjoner skal være valgfrie.
- XGA-1 skal bruke vanlig coprocessor busy-bit.
- XGA-2 kan bruke AuxStatus busy-bit dersom maskintypen identifiseres som XGA-2.
- 8-bit pixel format skal brukes i 640x480x256.
- Husk at dimensjonsregistrene bruker `width - 1` og `height - 1` dersom kildene bekrefter dette.
- Bruk source map B og destination map A dersom dette er nødvendig for å ha et
  bredere off-screen bilde enn skjermens 640 pixels.
- Ikke bruk VGA Mode 13h som XGA-accelerator-test. XGA-coprocessoren er ikke
  aktivert på vanlig 320x200x256 VGA-modus.
- Ikke bland XGA-adressering med Olivetti PC1/V6355D-adressering. Dette prosjektet
  gjelder IBM PS/2 XGA, ikke Olivetti V6355D.

## Implementasjonsstrategi

Bruk NASM og DOS COM-format dersom eksisterende workspace-oppsett tillater det.
Hold programmet lite og enkelt å feilsøke.

Foreslått rekkefølge:

### Fase 1: Minimal modus-test

Lag en separat testfil, for eksempel `XGA/xga-demo/test_xga_mode.asm`.
Den skal lagre opprinnelig videomodus, detektere XGA, sette 640x480x256, tegne
et enkelt mønster, vente på ESC og gjenopprette opprinnelig modus.

### Fase 2: Minimal BitBLT-test

Lag for eksempel `XGA/xga-demo/test_xga_blit.asm`.
Den skal sette opp destination pixel map A og source pixel map B, fylle source-
området med et tydelig testmønster, vente på coprocessor busy-bit, sette source-
og destination-koordinater og dimensjoner, sette `XGA_S` foreground/background
mix, utføre normal source-copy BitBLT, vise resultatet og avslutte rent med ESC.

Start med en liten kopi, for eksempel 128x128, før du prøver 640x480.

### Fase 3: Panorama-demo

Når liten BitBLT fungerer, bruk et større kildebilde som passer i VRAM, panorer
automatisk eller med tastatur i X og Y, og hold scroll-koordinatene innenfor
kildebildet. Vis gjerne `XGA BLIT`, aktuell X/Y-posisjon og en enkel frame counter.
Start med et generert rutenett med koordinater. Bytt først til et ordentlig
pixel-art-bilde når register- og adressefeil er utelukket.

## Bygg og testing

Bruk eksisterende VS Code-task eller tilsvarende NASM-kommando:

```cmd
nasm -f bin "source.asm" -o "bin\source.COM" -l "bin\source.lst"
```

Kontroller etter hver substansiell endring at NASM bygger uten errors eller
warnings, COM-filen opprettes, programmet gjenoppretter text mode ved ESC, ingen
adresser overskrider tilgjengelig VRAM, og BitBLT-resultatet er visuelt kontrollert.

## 86Box-test

Når programmet bygger:

1. Finn eller lag en 86Box-konfigurasjon for en MCA PS/2-maskin tilsvarende Model 55SX.
2. Velg `XGA Graphics`.
3. Velg XGA-1 dersom det er mulig og dette er første test.
4. Bruk XGA-ROM-filene som finnes i 86Box-installasjonen.
5. Start 86Box fra `D:\86Box-Windows-64-b8200\86Box.exe`.
6. Start DOS og kjør COM-programmet.
7. Kontroller at riktig 640x480x256-bilde vises.
8. Kontroller at BitBLT faktisk endrer utsnittet når X/Y endres.
9. Kontroller ESC, modusgjenoppretting og retur til DOS.
10. Ta skjermbilde eller noter tydelig hva som ble observert dersom verktøyene tillater det.

Hvis 86Box-konfigurasjonen ikke er klar, gjør så mye automatisering som mulig:
bygg programmet, finn eksisterende `.cfg`/disk-image, start emulatoren og rapporter
nøyaktig hvilket manuelt steg som blokkerer videre testing. Ikke late som testen er utført.

## Feilsøking

Ved feil skal du først kontrollere XGA-type, POS-registerverdier,
coprocessor-registerbase, 64K kontra 1MB/4MB aperture, pixel map base pointer,
pixel map width/height, `PEL_MAP_FORMAT_8`, source/destination map bits i
PixelOperation, ROP/mix-verdi, busy-bit, overlappende kilde/destinasjon og om
koordinatene bruker inclusive `dimension - 1`-konvensjonen.

Lag små testprogrammer fremfor å skjule flere feil i hoveddemoen.

## Endelig stoppunkt

Når du mener programmet er ferdig nok til visning:

1. bygg siste versjon
2. start 86Box med riktig maskin og program
3. la demoen stå synlig på skjermen
4. ikke avslutt emulatoren automatisk
5. ikke gjør flere kodeendringer
6. send brukeren en kort melding om at 86Box kjører og hva brukeren skal se etter
7. vent på brukerens eksplisitte tilbakemelding på om det virker

Du skal ikke erklære prosjektet ferdig før brukeren har fått anledning til å se
programmet i 86Box og svare. Hvis brukeren svarer at noe ikke virker, fortsett med
målrettet feilsøking, bygging og ny 86Box-test.

## Rapportering

Ved hver milepæl rapporter kort hvilke filer som ble endret, hvilken kommando som
ble kjørt, om NASM bygget uten feil, om programmet faktisk ble startet i 86Box,
hva som var synlig og eventuelle manuelle begrensninger.

Ikke commit endringer med mindre brukeren ber om det. Ikke overskriv eller revert
brukerens eksisterende endringer.
