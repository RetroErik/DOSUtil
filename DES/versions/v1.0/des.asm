; ============================================================================
; DES.COM  --  Enkel DIR-erstatning for DOS/4DOS med DESCRIPT.ION-stotte
; Versjon: 1.0
; ============================================================================
;
; Hva programmet gjor:
;   - Skriver en kort header som ekte DIR ("Volume in drive X is ..." og
;     "Directory of ..."), men UTEN footer, UTEN dato/klokkeslett og UTEN
;     filstorrelse.
;   - Kolonnen etter filnavnet viser KUN "<DIR>" for kataloger, eller
;     blanke tegn for vanlige filer.
;   - Etter det skrives beskrivelsen som er registrert for filen i en
;     4DOS-kompatibel DESCRIPT.ION-fil i samme katalog som filene som listes.
;   - Listen sorteres slik at kataloger kommer forst, deretter filer, og
;     innenfor hver av de to gruppene alfabetisk (case-insensitivt).
;   - DESCRIPT.ION / DESCRIPT.OLD / DESCRIPT.BAK vises aldri i listen selv.
;   - Svitsjen /P (hvor som helst pa kommandolinjen) gir sidevis utskrift,
;     akkurat som DIR /P: stopper og venter pa tastetrykk hver 23. linje.
;
; Bruk:
;   DES              -> lister *.* i gjeldende katalog
;   DES *.EXE        -> lister kun *.EXE i gjeldende katalog
;   DES C:\SPILL\*.* -> lister *.* i C:\SPILL, og leser C:\SPILL\DESCRIPT.ION
;   DES /P           -> som over, men med sidevis utskrift
;   DES *.EXE /P     -> svitsjen kan sta for eller etter monsteret
;
; Viktig om farger:
;   Uten COLORDIR-miljovariabelen skriver vi KUN via DOS INT 21h (AH=02h/09h),
;   som aldri rorer attributt-byten - da beholdes fargen brukeren har satt
;   med 4DOS' COLOR-kommando uendret. Hvis COLORDIR finnes, fargelegger vi
;   filnavn/kataloger/beskrivelse eksplisitt per filtype (se setup_colors og
;   flush_colored_line) - da skrives det direkte til skjermminnet (B800h/
;   B000h) for hastighet, men ALDRI med ANSI-sekvenser, og med automatisk
;   fallback til ren INT 21h-utskrift ved omdirigering eller ustottet maskinvare.
;
; Kompilering:
;   nasm -f bin des.asm -o DES.COM
;
; Malgruppe for maskinvare:
;   Ren 8086/8088-kompatibel kode. Ingen 186/286/386-instruksjoner brukes
;   (ingen PUSHA, ingen 32-bits registre, ingen IMUL med tre operander osv).
; ============================================================================

                org     100h            ; .COM-filer lastes alltid pa offset 100h i sitt PSP-segment

                jmp     main            ; hopp over datadelen og start selve programmet

; ----------------------------------------------------------------------------
; KONSTANTER
; ----------------------------------------------------------------------------
MAX_ENTRIES     equ     400             ; maks antall filer/kataloger vi kan huske samtidig
ENTRY_SIZE      equ     14              ; hver oppforing: 13 bytes navn (ASCIZ) + 1 byte attributt
NAME_FIELD_LEN  equ     13              ; DOS' DTA-filnavnfelt er alltid 13 bytes (8.3-format + null)
NAME_COL_WIDTH  equ     13              ; bredde pa filnavn-kolonnen i utskriften
DIR_COL_WIDTH   equ     5               ; bredde pa "<DIR>"-kolonnen ("<DIR>" er noyaktig 5 tegn)
SCREEN_WIDTH    equ     80              ; vi skal aldri skrive forbi kolonne 80 (ingen linjebryting)
PAGE_SIZE       equ     23              ; antall filoppforinger per "side" nar /P er i bruk
TOK_BUF_LEN     equ     128             ; storrelse pa buffer for ett enkelt kommandolinje-"ord"
COLORDIR_BUF_LEN equ    300             ; maks lengde pa verdien til miljovariabelen COLORDIR
COLORDIR_PFX_LEN equ    9               ; lengden av teksten COLORDIR=
MAX_EXT_RULES   equ     64              ; maks antall ekstensjon-til-farge-regler vi husker
EXT_NAME_LEN    equ     4               ; 3 tegn ekstensjon + null-terminator
EXT_RULE_SIZE   equ     5               ; EXT_NAME_LEN + 1 fargebyte
COLOR_NAME_COUNT equ    9               ; antall kjente fargenavn i color_names-tabellen

; ----------------------------------------------------------------------------
; DATA / VARIABLER
; ----------------------------------------------------------------------------

; Sok-/stimonsteret hentet fra kommandolinjen, f.eks. "*.EXE" eller
; "C:\SPILL\*.*". Standardverdi er "*.*" hvis brukeren ikke oppgir noe.
search_pattern  resb    128

; Full sti til DESCRIPT.ION-filen (samme katalog som search_pattern peker til).
desc_path       resb    128

; Standardmonster nar ingen argument er gitt pa kommandolinjen.
default_pattern db      '*.*', 0

; Faste filnavn vi aldri skal vise i listen (selve beskrivelsesfilene).
descript_name     db    'DESCRIPT.ION', 0
descript_old_name db    'DESCRIPT.OLD', 0
descript_bak_name db    'DESCRIPT.BAK', 0

; Teksten som vises i DIR-kolonnen for kataloger.
dir_marker      db      '<DIR>', 0

; DOS "Disk Transfer Area" som AH=4Eh/4Fh (Find First/Find Next) skriver
; treffinformasjon til. Standardstorrelse er 43 bytes:
;   offset 00h-14h (21 bytes): reservert/internt bruk av DOS mellom kall
;   offset 15h     (1 byte):   filattributt
;   offset 16h-17h (2 bytes):  filklokkeslett
;   offset 18h-19h (2 bytes):  fildato
;   offset 1Ah-1Dh (4 bytes):  filstorrelse
;   offset 1Eh-2Ah (13 bytes): ASCIZ filnavn i 8.3-format
our_dta         resb    43

; Tabell med alle funne oppforinger (navn + attributt). Fylles av
; collect_entries og sorteres av sort_entries.
entries         resb    MAX_ENTRIES * ENTRY_SIZE
entry_count     dw      0

; Midlertidig peker brukt mens vi bygger en ny oppforing i "entries".
tmp_entry_ptr   dw      0

; Antall gjenstaende "passeringer" i boble-sorteringen.
passes_left     dw      0

; Midlertidig 14-bytes buffer brukt til a bytte om pa to oppforinger ved
; sortering, samt to hjelpepekere som holder styr pa hvilke to oppforinger
; som byttes (unngar rotete bruk av stacken).
swap_buf        resb    ENTRY_SIZE
sort_ptr_a      dw      0
sort_ptr_b      dw      0

; Posisjon (indeks) i search_pattern til siste '\' eller ':' - brukes til a
; finne ut hvilken katalog DESCRIPT.ION skal leses fra.
last_sep_pos    dw      0

; Kolonneposisjon pa skjermen for linjen som skrives ut na (0-basert).
; Brukes til a fylle ut kolonner med riktig antall mellomrom og til a
; kutte beskrivelsen slik at vi aldri skriver forbi kolonne 80.
cur_col         dw      0

; Peker til filnavnet vi na leter etter en beskrivelse for (satt av
; find_description, brukt av den interne sammenligningslogikken).
desc_target_ptr dw      0

; Hele DESCRIPT.ION leses inn i minnet EN gang (load_descript_ion) i stedet
; for a apnes og skannes pa nytt for hver eneste fil i katalogen - det siste
; var hovedarsaken til at programmet var tregt (tusenvis av enkelt-byte
; INT 21h-kall). find_description soker na kun i denne minnebufferen.
DESCRIPT_DATA_LEN equ   16384           ; maks storrelse pa DESCRIPT.ION vi stotter
descript_data   resb    DESCRIPT_DATA_LEN
descript_data_len dw    0               ; faktisk antall bytes lest inn
descript_loaded dw      0               ; 1 hvis DESCRIPT.ION ble funnet og lest inn

; Brukt av find_description mens den leter gjennom descript_data etter en
; linje som matcher gjeldende fil: start og lengde (uten CR/LF) av linja
; den ser pa akkurat na.
line_start_pos  dw      0
next_line_pos   dw      0
line_len        dw      0

; Nar find_description finner en match, peker desc_start pa startindeksen
; (inne i descript_data) til beskrivelsesteksten, og desc_len er lengden av den.
desc_start      dw      0
desc_len        dw      0

; --- Variabler for /P (sidevis utskrift) ---
pause_flag      dw      0               ; 1 hvis /P ble funnet pa kommandolinjen
lines_printed   dw      0               ; antall linjer skrevet siden forrige pause
tok_buf         resb    TOK_BUF_LEN     ; midlertidig buffer for ett "ord" fra kommandolinjen
switch_p        db      '/P', 0         ; svitsjen vi ser etter (sammenlignes case-insensitivt)
press_key_msg   db      'Press any key to continue . . .', 0

; --- Variabler for header ("Volume in drive..." / "Directory of...") ---
vol_dta         resb    43              ; egen DTA for volumetikett-soket, sa vi ikke
                                        ; forstyrrer our_dta som brukes til selve fillisten
truename_input  resb    128             ; katalogdelen (UTEN wildcard) som sendes til Truename
truename_buf    resb    128             ; kanonisert katalogdel fra INT 21h AH=60h
current_dir_alias db    '.', 0          ; DOS-alias for "gjeldende katalog", brukt nar ingen sti er oppgitt
hdr_sep_pos     dw      0FFFFh          ; indeks til siste '\'/':' i search_pattern (for header-linjen)
vol_drive_letter db     0               ; stasjonsbokstaven vi viser i headeren
vol_pattern     resb    8               ; "X:\*.*" - brukt til a finne volumetiketten
vol_in_drive_msg db     ' Volume in drive ', 0
vol_is_msg      db      ' is ', 0
vol_nolabel_msg db      ' has no label', 0
dir_of_msg      db      ' Directory of  ', 0

; --- Variabler for ColorDir-basert filfarging ---
;
; 4DOS setter miljovariabelen COLORDIR til noe sant som:
;   dirs:bri mag; zip arj:bri blu; com exe:bri gre; txt me now:gre
; Vi leser denne selv (krever altsa IKKE at 4DOS kjorer, bare at variabelen
; finnes i miljoet) og fargelegger filnavn/DIR-kolonnen deretter, via BIOS
; INT 10h (som er standardmaten a sette farge pa i tekstmodus - IKKE direkte
; skjermminne, IKKE ANSI). Resten av linjen (beskrivelse, CRLF osv.) forblir
; upaavirket og bruker fortsatt ren INT 21h AH=02h/09h som for.
colordir_active dw      0               ; 1 hvis COLORDIR ble funnet i miljoet
colordir_buf    resb    COLORDIR_BUF_LEN ; ravaerdien av COLORDIR, kopiert ut av miljoblokken
colordir_varname db     'COLORDIR=', 0

dirs_color_found dw     0               ; 1 hvis en dirs-regel ble funnet
dirs_color      db      0               ; fargen kataloger skal fa

ext_color_table resb    MAX_EXT_RULES * EXT_RULE_SIZE ; {ext[4], farge} per oppforing
ext_rule_count  dw      0

; --- Midlertidige variabler brukt under parsing av COLORDIR-verdien ---
rule_start      dw      0               ; start av gjeldende regel (mellom to ;)
rule_end        dw      0               ; slutt av gjeldende regel (peker pa ; eller null)
keys_start      dw      0               ; start av navnedelen (dirs/ekstensjoner) i en regel
keys_end        dw      0               ; slutt av navnedelen (peker pa :)
cs_start        dw      0               ; start av fargespesifikasjonen (etter :)
cs_end          dw      0               ; slutt av fargespesifikasjonen (samme som rule_end)
colon_pos       dw      0FFFFh          ; posisjon til : i gjeldende regel (0FFFFh = ikke funnet)
bri_flag        dw      0               ; 1 hvis BRI ble sett i fargespesifikasjonen
color_name_idx  dw      0FFFFh          ; indeks inn i color_names for gjenkjent fargenavn
parsed_color    db      0               ; resultatet av parse_colorspec
parsed_color_valid dw   0               ; 1 hvis parse_colorspec fant et gyldig fargenavn

tiny_tok        resb    8               ; midlertidig buffer for ett fargespek-token (BRI/fargenavn)
tiny_tok2       resb    8               ; midlertidig buffer for ett navnetoken (ekstensjon/DIRS)
ext_tok         resb    EXT_NAME_LEN    ; ekstensjonen til filen vi na fargelegger

current_color   db      07h             ; fargen som skal brukes for oppforingen vi skriver na
ambient_attr    db      07h             ; skjermens attributt ved oppstart (brukes som noytral/fallback-farge)

; --- Variabler for rask, linjevis fargeutskrift (se flush_colored_line) ---
video_segment   dw      0B800h          ; 0B800h (farge) eller 0B000h (monokrom) - satt av detect_video_segment
video_columns   db      80              ; antall tegnkolonner pa skjermen - satt av detect_video_segment
RENDER_BUF_LEN  equ     90              ; god margin over maks linjebredde (13+5+1+61=80)
render_buf      resb    RENDER_BUF_LEN  ; hele linjen (navn+DIR-kolonne+skille+beskrivelse) bygges her forst
render_len      dw      0               ; antall tegn lagt i render_buf sa langt
fcl_row         db      0               ; rad/kolonne ved linjestart, lagret unna FOR "mul" odelegger DX
fcl_col         db      0

dirs_keyword    db      'DIRS', 0
bri_keyword     db      'BRI', 0

; Fargenavn-tabell (3 bokstaver + null hver, altsaa 4 bytes per oppforing).
; color_val_normal/bright gir EGA/VGA-fargekoden (0-15) for hvert navn, uten
; og med BRI-prefiks. YEL gir alltid farge 14 (gul), uansett BRI.
color_names:
                db      'BLA', 0
                db      'BLU', 0
                db      'GRE', 0
                db      'CYA', 0
                db      'RED', 0
                db      'MAG', 0
                db      'BRO', 0
                db      'WHI', 0
                db      'YEL', 0
color_val_normal db     0, 1, 2, 3, 4, 5, 6, 7, 14
color_val_bright db     8, 9, 10, 11, 12, 13, 14, 15, 14


; ============================================================================
; HOVEDPROGRAM
; ============================================================================
main:
                cld                             ; alle strengoperasjoner (movsb/lodsb/stosb) gar fremover

                call    parse_cmdline           ; hent evt. argument/svitsjer fra kommandolinjen
                call    build_desc_path         ; regn ut hvilken katalog DESCRIPT.ION ligger i -> desc_path
                call    load_descript_ion       ; les HELE DESCRIPT.ION inn i minnet EN gang (fart!)
                call    setup_colors            ; les ambient skjermfarge + evt. COLORDIR-miljovariabel
                call    print_header            ; skriv "Volume in drive..." og "Directory of..."
                call    collect_entries         ; finn alle filer/kataloger som matcher search_pattern
                call    sort_entries            ; sorter: kataloger forst, deretter filer, alfabetisk
                call    print_entries           ; skriv ut listen med beskrivelser (med /P-sidevisning)

                mov     ax, 4C00h               ; avslutt ryddig med exit-kode 0 (suksess)
                int     21h


; ============================================================================
; parse_cmdline
;   Leser DOS-kommandolinjen (PSP:80h = lengde, PSP:81h.. = tekst) og deler
;   den opp i mellomromseparerte "ord" (tokens). Svitsjen /P (uansett hvor
;   den star, og uavhengig av store/sma bokstaver) setter pause_flag=1.
;   Det forste tokenet som IKKE er /P blir brukt som sok-/stimonster.
;   Hvis intet slikt token finnes, brukes standardverdien "*.*".
; ============================================================================
parse_cmdline:
                push    ax
                push    cx
                push    si
                push    di

                mov     word [pause_flag], 0
                mov     byte [search_pattern], 0   ; tom streng = "intet monster funnet ennaa"

                mov     cl, [80h]               ; CL = antall tegn i kommandolinje-halen
                xor     ch, ch                  ; CX = CL utvidet til 16 bit
                mov     si, 81h                 ; SI -> forste tegn etter lengdebyten

.pc_skip_spaces:                                 ; hopp over mellomrom mellom tokens
                cmp     cx, 0
                je      .pc_done
                mov     al, [si]
                cmp     al, ' '
                jne     .pc_copy_token
                inc     si
                dec     cx
                jmp     .pc_skip_spaces

.pc_copy_token:                                  ; kopier ett token til tok_buf
                mov     di, tok_buf
.pc_copy_loop:
                cmp     cx, 0
                je      .pc_token_done
                mov     al, [si]
                cmp     al, ' '
                je      .pc_token_done
                cmp     al, 0Dh                 ; CR markerer alltid slutten av kommandolinjen
                je      .pc_token_done
                mov     [di], al
                inc     di
                inc     si
                dec     cx
                jmp     .pc_copy_loop
.pc_token_done:
                mov     byte [di], 0            ; null-terminer tokenet

                push    si                       ; str_ieq flytter SI/DI, ta vare pa var posisjon
                mov     si, tok_buf
                mov     di, switch_p
                call    str_ieq                  ; er tokenet "/P" (case-insensitivt)?
                pop     si
                jne     .pc_not_switch
                mov     word [pause_flag], 1
                jmp     .pc_skip_spaces
.pc_not_switch:
                cmp     byte [search_pattern], 0 ; er monsteret allerede satt fra et tidligere token?
                jne     .pc_skip_spaces          ; ja - ignorer eventuelle ekstra tokens
                push    si
                mov     si, tok_buf
                mov     di, search_pattern
                call    strcpy_asciz
                pop     si
                jmp     .pc_skip_spaces

.pc_done:
                cmp     byte [search_pattern], 0 ; ble noe monster funnet i det hele tatt?
                jne     .pc_ret
                mov     si, default_pattern
                mov     di, search_pattern
                call    strcpy_asciz
.pc_ret:
                pop     di
                pop     si
                pop     cx
                pop     ax
                ret


; ============================================================================
; build_desc_path
;   Finner katalogdelen av search_pattern (alt til og med siste '\' eller ':')
;   og bygger desc_path = <katalogdel>DESCRIPT.ION
;   Hvis search_pattern ikke inneholder noen '\' eller ':', blir desc_path
;   rett og slett "DESCRIPT.ION" (dvs. gjeldende katalog).
; ============================================================================
build_desc_path:
                push    ax
                push    cx
                push    si
                push    di

                mov     si, search_pattern
                call    find_last_sep           ; AX = indeks til siste '\'/':' i search_pattern, eller 0FFFFh
                mov     [last_sep_pos], ax

                cmp     word [last_sep_pos], 0FFFFh
                je      .no_prefix

                mov     cx, [last_sep_pos]      ; kopier search_pattern[0..last_sep_pos] (inkl. separator)
                inc     cx                      ; ta med selve '\' eller ':' i lengden
                mov     si, search_pattern
                mov     di, desc_path
                rep     movsb                   ; DI peker na rett etter kopiert prefiks

                mov     si, descript_name
                call    strcpy_asciz            ; legg til "DESCRIPT.ION" + null-terminator
                jmp     .done
.no_prefix:
                mov     si, descript_name
                mov     di, desc_path
                call    strcpy_asciz
.done:
                pop     di
                pop     si
                pop     cx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; find_last_sep
;   Input:  SI -> ASCIZ streng.
;   Output: AX = indeks til det SISTE '\' eller ':' i strengen, eller 0FFFFh
;           hvis strengen ikke inneholder noen av delene. SI bevares.
;   Brukt av build_desc_path (for a finne DESCRIPT.ION sin katalog) og
;   print_header (for a skille katalogdelen fra wildcard-delen av stien).
; ----------------------------------------------------------------------------
find_last_sep:
                push    bx
                push    cx
                push    si

                mov     ax, 0FFFFh              ; 0FFFFh = "ingen separator funnet ennaa"
                xor     cx, cx                  ; CX = gjeldende indeks

.fls_loop:
                mov     bl, [si]
                cmp     bl, 0
                je      .fls_done
                cmp     bl, '\'
                je      .fls_mark
                cmp     bl, ':'
                je      .fls_mark
                inc     si
                inc     cx
                jmp     .fls_loop
.fls_mark:
                mov     ax, cx
                inc     si
                inc     cx
                jmp     .fls_loop
.fls_done:
                pop     si
                pop     cx
                pop     bx
                ret


; ============================================================================
; load_descript_ion
;   Leser HELE DESCRIPT.ION inn i minnet (descript_data) med EN stor lesing,
;   i stedet for at find_description apner og skanner filen pa nytt (byte
;   for byte!) for hver eneste fil i katalogen. Dette er den klart storste
;   arsaken til at programmet var tregt - antall DOS-kall gar fra
;   "antall filer * antall bytes i DESCRIPT.ION" ned til noen fa.
;   Hvis filen ikke finnes (eller er tomen), settes descript_loaded=0 og
;   find_description returnerer ganske enkelt "ingen beskrivelse" for alt.
; ============================================================================
load_descript_ion:
                push    ax
                push    bx
                push    cx
                push    dx

                mov     word [descript_loaded], 0
                mov     word [descript_data_len], 0

                mov     dx, desc_path
                mov     ax, 3D00h               ; apne fil, kun lesing
                int     21h
                jc      .ldi_done               ; DESCRIPT.ION finnes ikke - ingen beskrivelser tilgjengelig
                mov     bx, ax                  ; BX = filhandtak

                mov     cx, DESCRIPT_DATA_LEN
                mov     dx, descript_data
                mov     ah, 3Fh
                int     21h                     ; les opptil DESCRIPT_DATA_LEN bytes i EN operasjon
                jc      .ldi_close
                mov     [descript_data_len], ax
                mov     word [descript_loaded], 1

.ldi_close:
                mov     ah, 3Eh
                int     21h

.ldi_done:
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret


; ============================================================================
; setup_colors
;   Forbereder alt som trengs for evt. fargelegging av filnavn/kataloger:
;     1. Leser skjermens gjeldende attributt ved markoren (ambient_attr) -
;        brukes som noytral fallback-farge for filtyper COLORDIR ikke nevner.
;     2. Leter etter miljovariabelen COLORDIR. Hvis den ikke finnes, gjor vi
;        ingenting mer - programmet fargelegger da ingenting (som for), og
;        krever altsa IKKE at 4DOS kjorer.
;     3. Sjekker om standard utdata faktisk er skjermen (CON), eller om den
;        er omdirigert til en fil/rar (">"/"|"). BIOS INT 10h-skriving gar
;        RETT til skjermmaskinvaren og passerer IKKE DOS' vanlige handtak-
;        baserte omdirigering - fargelagt tekst ville derfor rett og slett
;        forsvinne fra en omdirigert fil. Er utdata omdirigert, slar vi
;        derfor av fargelegging automatisk og faller tilbake til ren
;        INT 21h-utskrift (som alltid virker, uansett omdirigering).
;     4. Sjekker aktiv videomodus/side (detect_video_segment), sa vi vet om
;        det er trygt a skrive rett til videominnet, og hvilket segment
;        (B800h/B000h) det er.
;     5. Hvis COLORDIR finnes OG utdata gar til en ekte skjerm, tolkes
;        verdien til en liten oppslagstabell (ext_color_table + dirs_color)
;        som print_entries senere bruker.
; ============================================================================
setup_colors:
                call    read_ambient_attr
                call    find_and_copy_colordir
                cmp     word [colordir_active], 0
                je      .sc_done
                call    check_stdout_is_device  ; nullstiller colordir_active hvis omdirigert
                cmp     word [colordir_active], 0
                je      .sc_done
                call    detect_video_segment    ; nullstiller colordir_active ved ukjent modus/side
                cmp     word [colordir_active], 0
                je      .sc_done
                call    parse_colordir
.sc_done:
                ret


; ----------------------------------------------------------------------------
; check_stdout_is_device
;   Bruker INT 21h AH=44h (IOCTL), AL=00h (Get Device Information) pa handtak
;   1 (standard utdata) for a sjekke om utdata faktisk gar til en tegnenhet
;   (skjermen), eller om den er omdirigert til en fil/rar. Bit 7 i den
;   returnerte enhetsinformasjonen (DL) er satt for ekte enheter. Hvis
;   utdata IKKE er en enhet, nullstiller vi colordir_active - se setup_colors.
; ----------------------------------------------------------------------------
check_stdout_is_device:
                push    ax
                push    bx
                push    dx

                mov     bx, 1                   ; handtak 1 = standard utdata (stdout)
                mov     ax, 4400h
                int     21h
                jc      .csd_not_device          ; feil - anta ikke-enhet, for sikkerhets skyld

                test    dl, 80h                  ; bit 7 = 1 betyr ekte tegnenhet (skjerm)
                jnz     .csd_is_device

.csd_not_device:
                mov     word [colordir_active], 0

.csd_is_device:
                pop     dx
                pop     bx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; read_ambient_attr  -  Leser tegn+attributt ved gjeldende markorposisjon via
;                       BIOS INT 10h (AH=03h henter posisjon, AH=08h leser
;                       tegn+attributt der). Dette er IKKE direkte skjermminne-
;                       tilgang og IKKE en hardkodet farge - vi leser rett og
;                       slett hvilken farge som allerede er aktiv (typisk satt
;                       av 4DOS' COLOR-kommando), og bruker den som noytral
;                       fallback for filtyper COLORDIR ikke sier noe om.
; ----------------------------------------------------------------------------
read_ambient_attr:
                push    ax
                push    bx
                push    dx

                xor     bh, bh                  ; BIOS-videoside 0
                mov     ah, 03h
                int     10h                     ; -> DH=rad, DL=kolonne (ubrukt her)

                xor     bh, bh
                mov     ah, 08h
                int     10h                     ; -> AH=attributt, AL=tegn ved markoren
                mov     [ambient_attr], ah

                pop     dx
                pop     bx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; env_starts_with  -  Sjekker om ES:DI starter med (case-insensitivt) ASCIZ-
;                     prefikset DS:SI peker pa. Verken SI eller DI endres.
;                     CF=1 hvis match, CF=0 hvis ikke.
; ----------------------------------------------------------------------------
env_starts_with:
                push    ax
                push    bx
                push    si
                push    di
.esw_loop:
                mov     al, [si]
                cmp     al, 0
                je      .esw_match              ; naadd slutten av prefikset uten mismatch -> match!
                call    to_upper
                mov     bl, al
                mov     al, [es:di]
                call    to_upper
                cmp     al, bl
                jne     .esw_nomatch
                inc     si
                inc     di
                jmp     .esw_loop
.esw_match:
                pop     di
                pop     si
                pop     bx
                pop     ax
                stc
                ret
.esw_nomatch:
                pop     di
                pop     si
                pop     bx
                pop     ax
                clc
                ret


; ----------------------------------------------------------------------------
; find_and_copy_colordir
;   Skanner DOS-miljoblokken (peker lagret i PSP:2Ch) etter en oppforing som
;   starter med "COLORDIR=" (case-insensitivt). Hvis funnet, kopieres verdien
;   (alt etter '=') inn i colordir_buf og colordir_active settes til 1.
;   Miljoblokken er en serie ASCIZ-strenger "NAVN=VERDI", avsluttet med to
;   null-bytes pa rad.
; ----------------------------------------------------------------------------
find_and_copy_colordir:
                push    ax
                push    cx
                push    si
                push    di
                push    es

                mov     word [colordir_active], 0

                mov     ax, [2Ch]               ; miljosegmentet er lagret i PSP ved offset 2Ch
                mov     es, ax
                xor     di, di

.fc_entry_loop:
                cmp     byte [es:di], 0
                je      .fc_done                ; nullbyte som forste tegn = slutt pa miljoblokken

                mov     si, colordir_varname
                call    env_starts_with
                jc      .fc_match

.fc_skip_entry:                                  ; ikke match - hopp til neste NAVN=VERDI-oppforing
                cmp     byte [es:di], 0
                je      .fc_next_entry
                inc     di
                jmp     .fc_skip_entry
.fc_next_entry:
                inc     di                      ; hopp over null-terminatoren til denne oppforingen
                jmp     .fc_entry_loop

.fc_match:
                add     di, COLORDIR_PFX_LEN    ; hopp forbi selve "COLORDIR=" i miljoblokken
                mov     si, colordir_buf
.fc_copy:
                mov     al, [es:di]
                mov     [si], al
                cmp     al, 0
                je      .fc_copied
                inc     di
                inc     si
                cmp     si, colordir_buf + COLORDIR_BUF_LEN - 1
                jae     .fc_copied              ; sikkerhet: ikke skriv utenfor colordir_buf
                jmp     .fc_copy
.fc_copied:
                mov     byte [si], 0
                mov     word [colordir_active], 1

.fc_done:
                pop     es
                pop     di
                pop     si
                pop     cx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; parse_colordir  -  Deler colordir_buf opp i regler adskilt med ';' og lar
;                    process_one_rule tolke hver av dem.
; ----------------------------------------------------------------------------
parse_colordir:
                push    ax
                push    si

                mov     word [ext_rule_count], 0
                mov     word [dirs_color_found], 0

                mov     si, colordir_buf
.pcd_rule_loop:
                cmp     byte [si], 0
                je      .pcd_done
                mov     [rule_start], si
.pcd_find_semi:
                mov     al, [si]
                cmp     al, 0
                je      .pcd_found_end
                cmp     al, ';'
                je      .pcd_found_end
                inc     si
                jmp     .pcd_find_semi
.pcd_found_end:
                mov     [rule_end], si          ; SI peker na pa ';' eller null

                call    process_one_rule

                cmp     byte [si], ';'
                jne     .pcd_done               ; var null -> siste regel er ferdig behandlet
                inc     si                      ; hopp over ';' og fortsett med neste regel
                jmp     .pcd_rule_loop

.pcd_done:
                pop     si
                pop     ax
                ret


; ----------------------------------------------------------------------------
; process_one_rule  -  Tolker EN regel (mellom [rule_start] og [rule_end)):
;                      finner ':', tolker fargedelen (parse_colorspec), og
;                      hvis den var gyldig - registrerer navnedelen
;                      (parse_keys) i ext_color_table / dirs_color.
; ----------------------------------------------------------------------------
process_one_rule:
                push    ax
                push    si

                mov     word [colon_pos], 0FFFFh
                mov     si, [rule_start]
.por_find_colon:
                cmp     si, [rule_end]
                jae     .por_colon_done
                cmp     byte [si], ':'
                je      .por_colon_found
                inc     si
                jmp     .por_find_colon
.por_colon_found:
                mov     [colon_pos], si
.por_colon_done:
                cmp     word [colon_pos], 0FFFFh
                je      .por_ret                ; ingen ':' i denne regelen - ugyldig, hopp over

                mov     ax, [rule_start]
                mov     [keys_start], ax
                mov     ax, [colon_pos]
                mov     [keys_end], ax

                mov     ax, [colon_pos]
                inc     ax
                mov     [cs_start], ax
                mov     ax, [rule_end]
                mov     [cs_end], ax

                call    parse_colorspec
                cmp     word [parsed_color_valid], 0
                je      .por_ret                ; ingen gjenkjent farge - ignorer hele regelen

                call    parse_keys

.por_ret:
                pop     si
                pop     ax
                ret


; ----------------------------------------------------------------------------
; parse_colorspec
;   Leser mellomromseparerte tokens fra [cs_start .. cs_end): "BRI" og/eller
;   ett fargenavn (BLA/BLU/GRE/CYA/RED/MAG/BRO/WHI/YEL). Ukjente tokens
;   ignoreres stille. Resultat: parsed_color (farge 0-15) og
;   parsed_color_valid (1 hvis et gjenkjent fargenavn ble funnet).
; ----------------------------------------------------------------------------
parse_colorspec:
                push    ax
                push    bx
                push    cx
                push    si
                push    di

                mov     word [bri_flag], 0
                mov     word [color_name_idx], 0FFFFh
                mov     si, [cs_start]

.pcs_skip_spaces:
                cmp     si, [cs_end]
                jae     .pcs_done
                cmp     byte [si], ' '
                jne     .pcs_read_token
                inc     si
                jmp     .pcs_skip_spaces

.pcs_read_token:
                mov     di, tiny_tok            ; nullstill tiny_tok forst
                mov     cx, 8
                mov     al, 0
                rep     stosb

                mov     di, tiny_tok
                xor     cx, cx
.pcs_copy_tok:
                cmp     si, [cs_end]
                jae     .pcs_tok_done
                mov     al, [si]
                cmp     al, ' '
                je      .pcs_tok_done
                call    to_upper
                cmp     cx, 3
                jae     .pcs_tok_overflow
                mov     [di], al
                inc     di
.pcs_tok_overflow:
                inc     cx
                inc     si
                jmp     .pcs_copy_tok
.pcs_tok_done:

                push    si                      ; ta vare pa lesecursoren - matchingen under bruker SI
                mov     si, tiny_tok
                mov     di, bri_keyword
                call    str_ieq
                pop     si
                jne     .pcs_check_color
                mov     word [bri_flag], 1
                jmp     .pcs_skip_spaces

.pcs_check_color:
                mov     bx, 0
.pcs_color_loop:
                cmp     bx, COLOR_NAME_COUNT
                jae     .pcs_skip_spaces        ; ukjent token - bare ignorer og fortsett
                push    si
                push    ax
                push    dx
                push    di
                mov     ax, bx
                mov     cx, 4
                mul     cx                      ; ax = bx*4 (indeks inn i color_names)
                mov     di, color_names
                add     di, ax
                mov     si, tiny_tok
                call    str_ieq
                pop     di
                pop     dx
                pop     ax
                pop     si
                jne     .pcs_color_next
                mov     [color_name_idx], bx
                jmp     .pcs_skip_spaces
.pcs_color_next:
                inc     bx
                jmp     .pcs_color_loop

.pcs_done:
                mov     word [parsed_color_valid], 0
                cmp     word [color_name_idx], 0FFFFh
                je      .pcs_ret

                mov     bx, [color_name_idx]
                cmp     word [bri_flag], 0
                jne     .pcs_use_bright
                mov     al, [color_val_normal + bx]
                jmp     .pcs_have_color
.pcs_use_bright:
                mov     al, [color_val_bright + bx]
.pcs_have_color:
                mov     [parsed_color], al
                mov     word [parsed_color_valid], 1

.pcs_ret:
                pop     di
                pop     si
                pop     cx
                pop     bx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; parse_keys
;   Leser mellomromseparerte tokens fra [keys_start .. keys_end): enten
;   notnokkelordet DIRS, eller en filextension (opptil 3 tegn). Bruker
;   parsed_color (satt av parse_colorspec like for) som fargen for alle
;   tokens i denne regelen.
; ----------------------------------------------------------------------------
parse_keys:
                push    ax
                push    bx
                push    cx
                push    si
                push    di

                mov     si, [keys_start]
.pk_skip_spaces:
                cmp     si, [keys_end]
                jae     .pk_done
                cmp     byte [si], ' '
                jne     .pk_read_token
                inc     si
                jmp     .pk_skip_spaces

.pk_read_token:
                mov     di, tiny_tok2           ; nullstill tiny_tok2 forst (rommer ogsaa "DIRS")
                mov     cx, 8
                mov     al, 0
                rep     stosb

                mov     di, tiny_tok2
                xor     cx, cx
.pk_copy_tok:
                cmp     si, [keys_end]
                jae     .pk_tok_done
                mov     al, [si]
                cmp     al, ' '
                je      .pk_tok_done
                call    to_upper
                cmp     cx, 7
                jae     .pk_tok_overflow
                mov     [di], al
                inc     di
.pk_tok_overflow:
                inc     cx
                inc     si
                jmp     .pk_copy_tok
.pk_tok_done:

                push    si
                mov     si, tiny_tok2
                mov     di, dirs_keyword
                call    str_ieq
                pop     si
                jne     .pk_is_extension
                mov     al, [parsed_color]
                mov     [dirs_color], al
                mov     word [dirs_color_found], 1
                jmp     .pk_skip_spaces

.pk_is_extension:
                cmp     word [ext_rule_count], MAX_EXT_RULES
                jae     .pk_skip_spaces         ; tabellen full - ignorer flere ekstensjoner stille

                push    si                      ; SI er navnelinje-cursoren var - IKKE mist den her,
                                                ; ellers hopper vi over resten av tokens i denne regelen
                mov     ax, [ext_rule_count]
                mov     cx, EXT_RULE_SIZE
                mul     cx
                mov     di, ext_color_table
                add     di, ax
                mov     [tmp_entry_ptr], di     ; husk starten pa denne tabelloppforingen

                mov     cx, EXT_NAME_LEN        ; nullstill navnefeltet forst
                mov     al, 0
                rep     stosb

                mov     di, [tmp_entry_ptr]
                mov     si, tiny_tok2
                xor     cx, cx
.pk_copy_ext:
                mov     al, [si]
                cmp     al, 0
                je      .pk_ext_name_done
                cmp     cx, 3
                jae     .pk_ext_name_done       ; kutt av ved 3 tegn (DOS-ekstensjoner er aldri lengre)
                mov     [di], al
                inc     di
                inc     si
                inc     cx
                jmp     .pk_copy_ext
.pk_ext_name_done:

                mov     di, [tmp_entry_ptr]
                mov     al, [parsed_color]
                mov     [di + EXT_NAME_LEN], al

                inc     word [ext_rule_count]
                pop     si                      ; gjenopprett navnelinje-cursoren for neste token
                jmp     .pk_skip_spaces

.pk_done:
                pop     di
                pop     si
                pop     cx
                pop     bx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; extract_extension
;   Input:  SI -> ASCIZ filnavn.
;   Output: ext_tok fylt med filextensionen (ASCIZ, opptil 3 tegn), eller
;           tom streng hvis navnet ikke inneholder noe punktum. SI bevares.
; ----------------------------------------------------------------------------
extract_extension:
                push    ax
                push    cx
                push    si
                push    di

                mov     di, ext_tok             ; nullstill ext_tok forst
                mov     cx, EXT_NAME_LEN
                mov     al, 0
                rep     stosb

.ee_find_dot:
                mov     al, [si]
                cmp     al, 0
                je      .ee_done                ; ingen '.' funnet -> tom ekstensjon
                cmp     al, '.'
                je      .ee_found_dot
                inc     si
                jmp     .ee_find_dot
.ee_found_dot:
                inc     si                      ; hopp over selve punktumet
                mov     di, ext_tok
                xor     cx, cx
.ee_copy:
                mov     al, [si]
                cmp     al, 0
                je      .ee_done
                cmp     cx, 3
                jae     .ee_done
                mov     [di], al
                inc     di
                inc     si
                inc     cx
                jmp     .ee_copy
.ee_done:
                pop     di
                pop     si
                pop     cx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; get_entry_color
;   Input:  SI -> ASCIZ filnavn for oppforingen, AL = attributtbyte.
;   Output: AL = fargeattributt og CF=0 hvis en COLORDIR-regel matchet;
;           CF=1 hvis ingen regel matchet (kalleren bor da bruke ambient_attr).
;   Forutsetter at colordir_active=1 og at parse_colordir er kjort.
; ----------------------------------------------------------------------------
get_entry_color:
                push    bx
                push    cx
                push    dx
                push    si
                push    di

                test    al, 10h                 ; er dette en katalog?
                jz      .gec_check_ext

                cmp     word [dirs_color_found], 0
                je      .gec_no_match
                mov     al, [dirs_color]
                clc
                jmp     .gec_ret

.gec_check_ext:
                call    extract_extension       ; fyller ext_tok basert pa filnavnet i SI

                mov     cx, [ext_rule_count]
                mov     di, ext_color_table
.gec_loop:
                cmp     cx, 0
                je      .gec_no_match
                mov     si, ext_tok
                call    str_ieq
                je      .gec_found
                add     di, EXT_RULE_SIZE
                dec     cx
                jmp     .gec_loop
.gec_found:
                mov     al, [di + EXT_NAME_LEN]
                clc
                jmp     .gec_ret

.gec_no_match:
                stc

.gec_ret:
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                ret


; ----------------------------------------------------------------------------
; detect_video_segment
;   Sjekker aktiv videomodus/side/bredde via BIOS INT 10h AH=0Fh, og
;   bestemmer hvilket minnesegment skjermteksten ligger i:
;     - Monokrom tekstmodus (mode 7)         -> 0B000h
;     - Fargetekstmodus (mode 0/1/2/3)       -> 0B800h
;   Dette er standard IBM PC-kompatibelt minnekart som CGA/EGA/VGA (og alt
;   senere maskinvare) alle folger for tekstmodus, sa det er trygt pa tvers
;   av alle disse - i motsetning til a anta et fast segment uten a sjekke.
;   Stotter kun 80-kolonners skjermbredde (mode 0/1 pa CGA er 40 kolonner -
;   feil bredde ville gitt helt feil minneadresser og odelagt skjermbildet)
;   og videoside 0 (den vanlige/eneste i praksis for et DOS-prompt). For
;   ukjent modus, feil bredde eller en annen aktiv side, slar vi av
;   fargelegging helt (colordir_active=0) i stedet for a gjette feil.
; ----------------------------------------------------------------------------
detect_video_segment:
                push    ax
                push    bx

                mov     ah, 0Fh
                int     10h                     ; AL=videomodus, AH=antall kolonner, BH=aktiv side
                mov     [video_columns], ah

                cmp     al, 7
                je      .dvs_mono
                cmp     al, 0
                je      .dvs_color
                cmp     al, 1
                je      .dvs_color
                cmp     al, 2
                je      .dvs_color
                cmp     al, 3
                je      .dvs_color
                mov     word [colordir_active], 0  ; ukjent/ustottet modus - trygg fallback
                jmp     .dvs_done

.dvs_mono:
                mov     word [video_segment], 0B000h
                jmp     .dvs_check_width
.dvs_color:
                mov     word [video_segment], 0B800h
.dvs_check_width:
                cmp     byte [video_columns], 80
                jne     .dvs_unsupported        ; f.eks. CGA 40-kolonners modus - stottes ikke
                cmp     bh, 0
                je      .dvs_done
.dvs_unsupported:
                mov     word [colordir_active], 0  ; bredde != 80 eller side != 0 - trygg fallback

.dvs_done:
                pop     bx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; append_render_char / append_render_string
;   Bygger opp EN hel skjermlinje i render_buf for print_entries, i stedet
;   for a skrive tegn for tegn mens vi gar. Dette lar oss skrive ut hele
;   linjen i ETT samlet steg (flush_colored_line) istedenfor mange sma
;   BIOS-kall - se forklaringen der. Oppdaterer ogsa cur_col fortlopende,
;   slik at kolonnebredde-beregningene i print_entries fungerer som for.
; ----------------------------------------------------------------------------
append_render_char:
                push    bx
                mov     bx, [render_len]
                mov     [render_buf + bx], al
                inc     word [render_len]
                inc     word [cur_col]
                pop     bx
                ret

append_render_string:
                push    ax
                push    si
.ars_loop:
                mov     al, [si]
                cmp     al, 0
                je      .ars_done
                call    append_render_char
                inc     si
                jmp     .ars_loop
.ars_done:
                pop     si
                pop     ax
                ret


; ----------------------------------------------------------------------------
; flush_colored_line
;   Skriver ut hele render_buf (render_len tegn) i current_color, og
;   nullstiller ingenting selv - kalleren (print_entries) styrer det.
;
;   En linje har alltid EN farge fra start til slutt (aldri fargebytte
;   midt i linjen), sa vi trenger ikke lese/sette markorposisjon for
;   HVERT tegn slik en naiv INT 10h-tilnaerming ville gjort. I stedet:
;     1. Ett BIOS-kall (AH=03h) henter start-markorposisjonen.
;     2. Hele linjen skrives direkte til videominnet (B800h/B000h - funnet
;        av detect_video_segment) med vanlige minneskrivinger (STOSW),
;        som er MYE raskere enn et BIOS/DOS-kall per tegn.
;     3. Ett siste BIOS-kall (AH=02h) flytter den virkelige skjermmarkoren
;        til slutten av linjen, slik at etterfolgende INT 21h-utskrift
;        (CRLF, "Press any key...", osv.) fortsetter riktig sted.
;   Hvis ColorDir ikke er aktivt (eller utdata er omdirigert), faller vi
;   tilbake til ren INT 21h-utskrift av bufferet, tegn for tegn - present
;   ferdig ubetinget uten farge, akkurat som for.
; ----------------------------------------------------------------------------
flush_colored_line:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    es

                cmp     word [colordir_active], 0
                je      .fcl_plain

                xor     bh, bh
                mov     ah, 03h
                int     10h                     ; -> DH=rad, DL=kolonne (start av linjen)
                mov     [fcl_row], dh           ; MA lagres unna FOR mul under - mul odelegger HELE DX
                mov     [fcl_col], dl

                mov     es, [video_segment]
                mov     al, dh                  ; AX = rad (0-24)
                mov     ah, 0
                mov     cl, [video_columns]      ; garantert 80 her (se detect_video_segment)
                mov     ch, 0
                mul     cx                      ; DX:AX = rad*antall_kolonner (DX blir 0 - IKKE bruk DH/DL etter dette)
                mov     cl, [fcl_col]           ; kolonne hentes fra lagret variabel, ikke fra DL
                mov     ch, 0
                add     ax, cx                  ; AX = rad*antall_kolonner + kolonne
                shl     ax, 1                    ; *2 (hvert skjermtegn er 2 bytes: tegn+attributt)
                mov     di, ax

                mov     si, render_buf
                mov     cx, [render_len]
                cmp     cx, 0
                je      .fcl_move_cursor
.fcl_write_loop:
                lodsb                           ; AL = neste tegn fra render_buf, SI++
                mov     ah, [current_color]
                stosw                           ; skriv tegn+attributt til [ES:DI], DI += 2
                loop    .fcl_write_loop

.fcl_move_cursor:
                mov     ax, [cur_col]           ; cur_col peker na pa kolonnen ETTER siste tegn
                mov     dl, al
                mov     dh, [fcl_row]           ; raden hentes fra lagret variabel, ikke fra DH direkte
                xor     bh, bh
                mov     ah, 02h
                int     10h
                jmp     .fcl_done

.fcl_plain:
                mov     si, render_buf
                mov     cx, [render_len]
                cmp     cx, 0
                je      .fcl_done
.fcl_plain_loop:
                lodsb
                mov     dl, al
                call    print_char
                loop    .fcl_plain_loop

.fcl_done:
                pop     es
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret


; ============================================================================
; print_header
;   Skriver de to klassiske DIR-headerlinjene:
;     " Volume in drive X is <ETIKETT>"   (eller "has no label" om ingen finnes)
;     " Directory of  <katalog>\<wildcard>"
;   etterfulgt av en blank linje.
;
;   VIKTIG: INT 21h AH=60h (Truename) kanoniserer en sti, men hvis vi gir den
;   HELE search_pattern (inkl. selve wildcard-monsteret, f.eks. "*.*"), vil
;   ekte MS-DOS FCB-ekspandere jokertegnene til "?"-tegn (f.eks.
;   "??????????.???"), akkurat slik brukeren observerte pa ekte maskinvare.
;   Derfor sender vi KUN katalogdelen (uten wildcard) til Truename, og
;   skriver den opprinnelige wildcard-teksten uendret etterpa - akkurat slik
;   ekte DOS/4DOS sin DIR gjor ("Directory of C:\*.*").
;
;   Volumetiketten hentes med et eget, frittstaende Find First-kall (AH=4Eh,
;   sokeattributt 08h) mot rotkatalogen pa den aktuelle stasjonen, med sin
;   egen DTA (vol_dta) sa vi ikke forstyrrer our_dta som brukes til fillisten.
; ============================================================================
print_header:
                push    ax
                push    cx
                push    dx
                push    si
                push    di

                ; --- Skill katalogdelen fra wildcard-delen av search_pattern ---
                mov     si, search_pattern
                call    find_last_sep
                mov     [hdr_sep_pos], ax

                cmp     ax, 0FFFFh
                jne     .ph_have_dir_prefix

                mov     si, current_dir_alias  ; ingen sti oppgitt - "." betyr gjeldende katalog
                mov     di, truename_input
                call    strcpy_asciz
                jmp     .ph_call_truename

.ph_have_dir_prefix:
                mov     cx, ax                  ; kopier search_pattern[0..hdr_sep_pos] (inkl. separator)
                inc     cx
                mov     si, search_pattern
                mov     di, truename_input
                rep     movsb
                mov     byte [di], 0

.ph_call_truename:
                ; --- Kanoniser KUN katalogdelen (uten wildcard - se forklaring over) ---
                mov     si, truename_input
                mov     di, truename_buf
                mov     ah, 60h
                int     21h
                jnc     .ph_have_path
                mov     si, truename_input      ; Truename feilet (svaert gammel DOS) - fall
                mov     di, truename_buf        ; tilbake til a vise katalogdelen uendret
                call    strcpy_asciz
.ph_have_path:

                ; --- Sorg for noyaktig en '\' mellom katalogdelen og wildcard-delen ---
                mov     si, truename_buf
                call    strlen                  ; AX = lengden av truename_buf
                mov     di, truename_buf
                add     di, ax
                cmp     ax, 0
                je      .ph_add_sep             ; (bor ikke skje) tom streng - trygt a legge til separator
                dec     di
                mov     al, [di]
                inc     di
                cmp     al, '\'
                je      .ph_sep_ok
                cmp     al, ':'
                je      .ph_sep_ok
.ph_add_sep:
                mov     byte [di], '\'
                inc     di
                mov     byte [di], 0
.ph_sep_ok:

                mov     al, [truename_buf]      ; forste tegn i kanonisert sti = stasjonsbokstaven
                mov     [vol_drive_letter], al

                ; --- Bygg "X:\*.*" - brukes til a lete opp volumetiketten ---
                mov     di, vol_pattern
                mov     al, [vol_drive_letter]
                stosb
                mov     al, ':'
                stosb
                mov     al, '\'
                stosb
                mov     al, '*'
                stosb
                mov     al, '.'
                stosb
                mov     al, '*'
                stosb
                mov     byte [di], 0

                mov     dx, vol_dta             ; egen DTA - ma ikke kollidere med our_dta
                mov     ah, 1Ah
                int     21h
                mov     cx, 08h                 ; sokeattributt 08h = kun volumetiketter
                mov     dx, vol_pattern
                mov     ah, 4Eh
                int     21h
                jc      .ph_no_label

                mov     si, vol_in_drive_msg    ; " Volume in drive X is <ETIKETT>"
                call    print_string_asciz
                mov     dl, [vol_drive_letter]
                call    print_char
                mov     si, vol_is_msg
                call    print_string_asciz
                mov     si, vol_dta + 1Eh       ; ASCIZ volumetikett fra DTA-en
                call    print_string_asciz
                call    print_crlf
                jmp     .ph_dir_line

.ph_no_label:
                mov     si, vol_in_drive_msg    ; " Volume in drive X has no label"
                call    print_string_asciz
                mov     dl, [vol_drive_letter]
                call    print_char
                mov     si, vol_nolabel_msg
                call    print_string_asciz
                call    print_crlf

.ph_dir_line:
                mov     si, dir_of_msg          ; " Directory of  <katalog>\<wildcard>"
                call    print_string_asciz
                mov     si, truename_buf
                call    print_string_asciz

                mov     si, search_pattern      ; skriv wildcard-delen HELT UENDRET (ingen Truename)
                cmp     word [hdr_sep_pos], 0FFFFh
                je      .ph_print_wildcard
                mov     ax, [hdr_sep_pos]
                inc     ax
                add     si, ax
.ph_print_wildcard:
                call    print_string_asciz
                call    print_crlf
                call    print_crlf              ; blank linje mellom header og fillisten

                mov     word [lines_printed], 3  ; header+blank teller med i /P-sidevisningen


                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     ax
                ret


; ============================================================================
; collect_entries
;   Bruker INT 21h AH=4Eh (Find First) / AH=4Fh (Find Next) til a finne alle
;   filer og kataloger som matcher search_pattern. Volumetiketter (attributt
;   08h) og selve DESCRIPT.ION/.OLD/.BAK-filene hoppes over. Resten lagres i
;   "entries"-tabellen for senere sortering og utskrift.
; ============================================================================
collect_entries:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di

                mov     word [entry_count], 0

                ; Sett DTA til vart eget buffer (kommandolinjeargumentet er
                ; allerede kopiert ut, sa PSP:80h trengs ikke lenger).
                mov     dx, our_dta
                mov     ah, 1Ah
                int     21h

                ; Sok-attributt 10h = ta ogsa med kataloger (vanlige filer
                ; tas alltid med av DOS uansett attributtmaske). Vi filtrerer
                ; bort volumetiketter manuelt uansett, som ekstra sikkerhet.
                mov     cx, 10h
                mov     dx, search_pattern
                mov     ah, 4Eh
                int     21h
                jc      .ce_done                ; ingen treff i det hele tatt

.ce_process:
                mov     al, [our_dta + 15h]     ; attributtbyte for gjeldende treff
                test    al, 08h                 ; bit 3 = volumetikett
                jnz     .ce_next

                mov     si, our_dta + 1Eh
                mov     di, descript_name
                call    str_ieq
                je      .ce_next
                mov     si, our_dta + 1Eh
                mov     di, descript_old_name
                call    str_ieq
                je      .ce_next
                mov     si, our_dta + 1Eh
                mov     di, descript_bak_name
                call    str_ieq
                je      .ce_next

                mov     bx, [entry_count]       ; er tabellen full? da hopper vi bare over resten
                cmp     bx, MAX_ENTRIES
                jae     .ce_next

                mov     ax, bx                  ; regn ut destinasjonspeker: entries + entry_count*ENTRY_SIZE
                mov     cx, ENTRY_SIZE
                mul     cx                      ; DX:AX = ax*cx (DX blir 0, tabellen er liten nok)
                mov     di, entries
                add     di, ax
                mov     [tmp_entry_ptr], di

                mov     cx, NAME_FIELD_LEN      ; nullstill navnefeltet forst, sa vi alltid
                mov     al, 0                   ; far en korrekt null-terminert streng
                rep     stosb

                mov     di, [tmp_entry_ptr]     ; kopier selve filnavnet over nullene
                mov     si, our_dta + 1Eh
.ce_copyname:
                lodsb
                stosb
                cmp     al, 0
                jne     .ce_copyname

                mov     di, [tmp_entry_ptr]     ; lagre attributtbyten rett etter navnefeltet
                mov     al, [our_dta + 15h]
                mov     [di + NAME_FIELD_LEN], al

                inc     word [entry_count]

.ce_next:
                mov     ah, 4Fh
                int     21h
                jnc     .ce_process
.ce_done:
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret


; ============================================================================
; sort_entries
;   Enkel boble-sortering av "entries"-tabellen basert pa filnavnet, uten
;   hensyn til store/sma bokstaver. Ikke den raskeste metoden, men lett a
;   lese og vedlikeholde - antall filer i en katalog er uansett lite nok
;   til at dette ikke merkes pa gammel maskinvare.
; ============================================================================
sort_entries:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di

                mov     ax, [entry_count]
                cmp     ax, 2
                jl      .se_ret                 ; 0 eller 1 oppforinger - ingenting a sortere

                mov     ax, [entry_count]       ; antall passeringer = entry_count - 1
                dec     ax
                mov     [passes_left], ax

.se_pass_loop:
                mov     bx, 0                   ; BX = indeks til forste av de to vi sammenligner

.se_inner_loop:
                mov     ax, [entry_count]
                dec     ax
                cmp     bx, ax
                jae     .se_pass_done

                ; SI = &entries[bx], DI = &entries[bx+1]
                mov     ax, bx
                mov     cx, ENTRY_SIZE
                mul     cx
                mov     si, entries
                add     si, ax
                mov     di, si
                add     di, ENTRY_SIZE

                call    entry_cmp               ; sammenligner hele oppforinger: kataloger forst, sa navn
                                                ; returnerer AX>0 hvis [SI]-oppforingen kommer ETTER [DI]-oppforingen
                cmp     ax, 0
                jle     .se_no_swap

                ; Bytt om de to hele oppforingene (ENTRY_SIZE bytes hver).
                ; Bruker minnevariabler (ikke stacken) for a holde adressene,
                ; slik at swap-koden er enkel a lese og feilsokke.
                mov     [sort_ptr_a], si
                mov     [sort_ptr_b], di

                mov     si, [sort_ptr_a]        ; swap_buf = entries[bx]
                mov     di, swap_buf
                mov     cx, ENTRY_SIZE
                rep     movsb

                mov     si, [sort_ptr_b]        ; entries[bx] = entries[bx+1]
                mov     di, [sort_ptr_a]
                mov     cx, ENTRY_SIZE
                rep     movsb

                mov     si, swap_buf            ; entries[bx+1] = swap_buf (opprinnelige entries[bx])
                mov     di, [sort_ptr_b]
                mov     cx, ENTRY_SIZE
                rep     movsb

.se_no_swap:
                inc     bx
                jmp     .se_inner_loop

.se_pass_done:
                dec     word [passes_left]
                jnz     .se_pass_loop

.se_ret:
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret


; ============================================================================
; print_entries
;   Gar gjennom den sorterte "entries"-tabellen og skriver ut hver oppforing:
;     <filnavn venstrejustert, NAME_COL_WIDTH kolonner>
;     <"<DIR>" eller DIR_COL_WIDTH mellomrom>
;     <ett mellomrom> <beskrivelse (kuttet ved kolonne SCREEN_WIDTH)> <CRLF>
; ============================================================================
print_entries:
                push    ax
                push    bx
                push    cx
                push    si
                push    di

                mov     bx, 0                   ; BX = indeks i entries
                                                ; (lines_printed nullstilles IKKE her - print_header
                                                ; har allerede satt den til 3, slik at headeren telles
                                                ; med i /P-sidevisningen og ikke ruller ut av syne)

.pe_loop:
                cmp     bx, [entry_count]
                jae     .pe_done

                mov     word [cur_col], 0
                mov     word [render_len], 0    ; hele linjen bygges her, skrives ut samlet til slutt

                mov     ax, bx                  ; SI -> navnefelt for oppforing nr. BX
                mov     cx, ENTRY_SIZE
                mul     cx
                mov     si, entries
                add     si, ax

                ; --- Bestem farge for denne oppforingen (kun brukt hvis ColorDir er aktiv) ---
                mov     al, [si + NAME_FIELD_LEN]
                cmp     word [colordir_active], 0
                je      .pe_no_colorlookup
                call    get_entry_color         ; Input: SI=navn, AL=attributt -> AL=farge, CF=0 hvis match
                jnc     .pe_color_set
                mov     al, [ambient_attr]      ; ingen regel matchet - bruk skjermens omgivelsesfarge
.pe_color_set:
                mov     [current_color], al
.pe_no_colorlookup:

                call    append_render_string    ; legg filnavnet i render_buf
.pe_pad_name:                                    ; fyll ut med mellomrom til kolonne NAME_COL_WIDTH
                mov     ax, [cur_col]
                cmp     ax, NAME_COL_WIDTH
                jae     .pe_name_padded
                mov     al, ' '
                call    append_render_char
                jmp     .pe_pad_name
.pe_name_padded:

                mov     al, [si + NAME_FIELD_LEN]   ; attributtbyte for denne oppforingen
                test    al, 10h                     ; bit 4 = katalog
                jz      .pe_not_dir
                push    si
                mov     si, dir_marker
                call    append_render_string
                pop     si
                jmp     .pe_dircol_done
.pe_not_dir:
                mov     cx, DIR_COL_WIDTH
.pe_space_loop:
                cmp     cx, 0
                je      .pe_dircol_done
                mov     al, ' '
                call    append_render_char
                dec     cx
                jmp     .pe_space_loop
.pe_dircol_done:

                mov     al, ' '                 ; ett mellomrom mellom DIR-kolonnen og beskrivelsen
                call    append_render_char

                ; SI peker fortsatt pa filnavnet for oppforing BX (er ikke endret over)
                call    find_description        ; CF=0 og desc_start/desc_len satt hvis funnet
                jc      .pe_no_desc

                mov     di, descript_data       ; legg til min(desc_len, SCREEN_WIDTH-cur_col) tegn
                add     di, [desc_start]
                mov     cx, [desc_len]
.pe_desc_loop:
                cmp     cx, 0
                je      .pe_no_desc
                mov     ax, [cur_col]
                cmp     ax, SCREEN_WIDTH
                jae     .pe_no_desc             ; na er vi pa kolonne 80 - ikke legg til mer (ingen wrap)
                mov     al, [di]
                call    append_render_char
                inc     di
                dec     cx
                jmp     .pe_desc_loop
.pe_no_desc:

                call    flush_colored_line      ; skriv HELE linjen i ett steg (se der for hvorfor)
                call    print_crlf

                cmp     word [pause_flag], 0    ; er /P i bruk?
                je      .pe_no_pause
                inc     word [lines_printed]
                mov     ax, [lines_printed]
                cmp     ax, PAGE_SIZE
                jb      .pe_no_pause
                call    do_pause                ; "Press any key to continue . . ." + vent pa tast
                mov     word [lines_printed], 0
.pe_no_pause:

                inc     bx
                jmp     .pe_loop

.pe_done:
                pop     di
                pop     si
                pop     cx
                pop     bx
                pop     ax
                ret


; ============================================================================
; find_description
;   Input:  SI -> ASCIZ filnavn (fra entries-tabellen) det skal soekes
;           beskrivelse for.
;   Output: CF=0 og desc_start/desc_len satt til posisjon/lengde av
;           beskrivelsesteksten inne i descript_data, hvis en match ble funnet.
;           CF=1 hvis filen ikke har noen beskrivelse (eller DESCRIPT.ION
;           ikke fantes / var tom - se load_descript_ion).
;
;   Soker i den ALLEREDE innleste descript_data-bufferen (fylt EN gang av
;   load_descript_ion for hele katalogen listes) - ingen filoperasjoner her
;   i det hele tatt. Hver linje har formatet "FILNAVN beskrivelse..." (ETT
;   mellomrom skiller filnavn fra beskrivelse). Sammenligningen er ikke
;   sensitiv for store/sma bokstaver.
; ============================================================================
find_description:
                push    bx
                push    cx
                push    dx
                push    si
                push    di

                cmp     word [descript_loaded], 0
                je      .fd_notfound

                mov     [desc_target_ptr], si   ; husk hvilket filnavn vi leter etter
                mov     di, 0                    ; DI = gjeldende leseposisjon i descript_data

.fd_line_loop:
                cmp     di, [descript_data_len]
                jae     .fd_notfound            ; naadd slutten av dataene - ingen match funnet

                mov     [line_start_pos], di

                ; --- finn slutten av denne linja (LF), eller slutten av dataene ---
.fd_find_eol:
                cmp     di, [descript_data_len]
                jae     .fd_eol_is_end
                mov     al, [descript_data + di]
                cmp     al, 0Ah
                je      .fd_eol_is_lf
                inc     di
                jmp     .fd_find_eol
.fd_eol_is_lf:
                mov     ax, di
                sub     ax, [line_start_pos]
                mov     [line_len], ax          ; linjelengde uten selve LF-en (evt. med en CR)
                mov     [next_line_pos], di
                inc     word [next_line_pos]    ; neste linje starter rett etter LF-en
                jmp     .fd_trim_cr
.fd_eol_is_end:
                mov     ax, di                  ; DI == descript_data_len her (ingen avsluttende LF)
                sub     ax, [line_start_pos]
                mov     [line_len], ax
                mov     ax, [descript_data_len]
                mov     [next_line_pos], ax     ; neste runde av lopen vil avslutte umiddelbart

.fd_trim_cr:
                cmp     word [line_len], 0
                je      .fd_no_match            ; tom linje - hopp videre
                mov     bx, [line_start_pos]
                add     bx, [line_len]
                dec     bx                      ; BX = indeks til siste tegn i linja
                cmp     byte [descript_data + bx], 0Dh
                jne     .fd_find_space
                dec     word [line_len]         ; fjern den avsluttende vognreturen

                ; --- finn forste mellomrom i linja -> skiller filnavn fra beskrivelse ---
.fd_find_space:
                mov     bx, 0                   ; BX = indeks INNENFOR linja (0-basert)
                mov     cx, [line_len]
.fd_find_space_loop:
                cmp     bx, cx
                jae     .fd_no_match            ; ingen mellomrom - ugyldig linje, ga videre
                mov     di, [line_start_pos]
                add     di, bx
                mov     al, [descript_data + di]
                cmp     al, ' '
                je      .fd_found_space
                inc     bx
                jmp     .fd_find_space_loop
.fd_found_space:
                ; BX = lengden pa filnavn-tokenet i linja

                mov     si, [desc_target_ptr]
                call    strlen                  ; AX = strlen(malfilnavn)
                cmp     ax, bx
                jne     .fd_no_match            ; ulik lengde -> helt sikkert ikke samme fil

                ; --- sammenlign tegn for tegn, case-insensitivt ---
                mov     cx, bx                  ; antall tegn a sammenligne
                mov     dx, 0                   ; DX = indeks i sammenligningen
.fd_cmp_loop:
                cmp     dx, cx
                jae     .fd_match               ; alle tegn var like -> match!
                mov     si, [line_start_pos]
                add     si, dx
                mov     al, [descript_data + si]
                call    to_upper
                mov     ah, al
                mov     si, [desc_target_ptr]
                add     si, dx
                mov     al, [si]
                call    to_upper
                cmp     al, ah
                jne     .fd_no_match
                inc     dx
                jmp     .fd_cmp_loop

.fd_match:
                ; Beskrivelsen starter rett etter mellomrommet og varer til slutten av linja.
                mov     ax, [line_start_pos]
                add     ax, bx
                inc     ax
                mov     [desc_start], ax
                mov     ax, [line_len]
                sub     ax, bx
                dec     ax
                mov     [desc_len], ax
                clc
                jmp     .fd_ret

.fd_no_match:
                mov     di, [next_line_pos]     ; prov neste linje
                jmp     .fd_line_loop

.fd_notfound:
                stc

.fd_ret:
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                ret


; ============================================================================
; HJELPEFUNKSJONER (strenger, tegn, utskrift)
; ============================================================================

; ----------------------------------------------------------------------------
; strcpy_asciz  -  Kopierer en null-terminert streng fra SI til DI (inkl. null)
;                  SI og DI justeres til a peke rett etter kopiert data.
; ----------------------------------------------------------------------------
strcpy_asciz:
                push    ax
.scz_loop:
                lodsb
                stosb
                cmp     al, 0
                jne     .scz_loop
                pop     ax
                ret


; ----------------------------------------------------------------------------
; strlen  -  Input: SI -> ASCIZ streng. Output: AX = lengde (uten null-byte).
;            SI blir ikke endret (vi bruker en kopi internt).
; ----------------------------------------------------------------------------
strlen:
                push    si
                push    bx
                mov     bx, si
                xor     ax, ax
.sl_loop:
                cmp     byte [bx], 0
                je      .sl_done
                inc     bx
                inc     ax
                jmp     .sl_loop
.sl_done:
                pop     bx
                pop     si
                ret


; ----------------------------------------------------------------------------
; to_upper  -  Input: AL = tegn. Output: AL = tegn gjort om til stor bokstav
;              hvis det var en liten bokstav (a-z), ellers uendret.
; ----------------------------------------------------------------------------
to_upper:
                cmp     al, 'a'
                jb      .tu_done
                cmp     al, 'z'
                ja      .tu_done
                sub     al, 20h
.tu_done:
                ret


; ----------------------------------------------------------------------------
; str_ieq  -  Sammenligner to ASCIZ-strenger (SI, DI) uten hensyn til store/
;             sma bokstaver. ZF=1 hvis strengene er like (bruk je/jz etterpa).
; ----------------------------------------------------------------------------
str_ieq:
                push    ax
                push    bx
                push    si
                push    di
.ie_loop:
                mov     al, [si]
                call    to_upper
                mov     bl, al
                mov     al, [di]
                call    to_upper
                cmp     al, bl
                jne     .ie_notequal
                cmp     byte [si], 0            ; begge like og vi er pa null-terminatoren -> like strenger
                je      .ie_equal
                inc     si
                inc     di
                jmp     .ie_loop
.ie_equal:
                pop     di
                pop     si
                pop     bx
                pop     ax
                xor     ax, ax
                or      ax, ax                  ; ZF = 1 (strengene er like)
                ret
.ie_notequal:
                pop     di
                pop     si
                pop     bx
                pop     ax
                mov     ax, 1
                or      ax, ax                  ; ZF = 0 (strengene er ulike)
                ret


; ----------------------------------------------------------------------------
; name_cmp_ci  -  Sammenligner de to ASCIZ-navnene som SI og DI peker pa
;                 (case-insensitivt, "leksikografisk" som strcmp).
;                 Output: AX = 0 hvis like, AX = 1 hvis [SI] > [DI],
;                         AX = -1 hvis [SI] < [DI].
;                 Brukes kun til a avgjore SORTERINGSREKKEFOLGE (sort_entries).
; ----------------------------------------------------------------------------
name_cmp_ci:
                push    bx
                push    si
                push    di
.nc_loop:
                mov     al, [si]
                call    to_upper
                mov     bl, al
                mov     al, [di]
                call    to_upper
                cmp     bl, al
                jne     .nc_diff
                cmp     byte [si], 0
                je      .nc_equal
                inc     si
                inc     di
                jmp     .nc_loop
.nc_diff:
                jb      .nc_less                ; bl < al (usignert) -> [SI]-navnet kommer FOR [DI]-navnet
                pop     di
                pop     si
                pop     bx
                mov     ax, 1
                ret
.nc_less:
                pop     di
                pop     si
                pop     bx
                mov     ax, -1
                ret
.nc_equal:
                pop     di
                pop     si
                pop     bx
                mov     ax, 0
                ret


; ----------------------------------------------------------------------------
; entry_cmp  -  Sammenligner to hele oppforinger (ikke bare navnet) slik at
;               kataloger alltid rangeres FOR vanlige filer. Innenfor samme
;               gruppe (to kataloger, eller to filer) avgjores rekkefolgen av
;               name_cmp_ci, akkurat som for.
;               Input:  SI, DI -> start av hver sin oppforing (navnefeltet;
;                       attributtbyten ligger pa SI+NAME_FIELD_LEN/DI+NAME_FIELD_LEN).
;               Output: AX = 1 hvis [SI]-oppforingen skal komme ETTER [DI],
;                       AX = -1 hvis den skal komme FOR, AX = 0 hvis lik.
; ----------------------------------------------------------------------------
entry_cmp:
                push    bx
                mov     al, [si + NAME_FIELD_LEN]
                and     al, 10h                 ; al = 10h hvis [SI] er en katalog, ellers 0
                mov     bl, [di + NAME_FIELD_LEN]
                and     bl, 10h                 ; bl = 10h hvis [DI] er en katalog, ellers 0
                cmp     al, bl
                je      .ec_same_kind           ; begge kataloger eller begge filer -> sammenlign navn
                cmp     al, 0
                jne     .ec_a_is_dir            ; al<>0 betyr [SI] er katalog, [DI] er fil
                pop     bx                      ; [SI] er fil, [DI] er katalog -> [SI] skal etter [DI]
                mov     ax, 1
                ret
.ec_a_is_dir:
                pop     bx                      ; [SI] er katalog, [DI] er fil -> [SI] skal for [DI]
                mov     ax, -1
                ret
.ec_same_kind:
                pop     bx
                call    name_cmp_ci
                ret


; ----------------------------------------------------------------------------
; print_char  -  Skriver ETT tegn til skjermen via DOS INT 21h, AH=02h.
;                Input: DL = tegnet som skal skrives.
;                Denne DOS-funksjonen endrer KUN tegn-byten pa skjermen, ikke
;                fargeattributten, sa 4DOS' COLOR-innstilling forblir uendret.
;                Oppdaterer ogsa cur_col (kolonneteller for gjeldende linje).
; ----------------------------------------------------------------------------
print_char:
                push    ax
                mov     ah, 02h
                int     21h
                inc     word [cur_col]
                pop     ax
                ret


; ----------------------------------------------------------------------------
; print_string_asciz  -  Skriver en null-terminert streng via print_char.
;                        Input: SI -> ASCIZ-streng. SI bevares (endres ikke).
; ----------------------------------------------------------------------------
print_string_asciz:
                push    ax
                push    dx
                push    si
.psa_loop:
                mov     al, [si]
                cmp     al, 0
                je      .psa_done
                mov     dl, al
                call    print_char
                inc     si
                jmp     .psa_loop
.psa_done:
                pop     si
                pop     dx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; print_crlf  -  Skriver vognretur + linjeskift (CR, LF) og nullstiller
;                kolonnetelleren for neste linje.
; ----------------------------------------------------------------------------
print_crlf:
                push    dx
                mov     dl, 0Dh
                call    print_char
                mov     dl, 0Ah
                call    print_char
                mov     word [cur_col], 0
                pop     dx
                ret


; ----------------------------------------------------------------------------
; do_pause  -  Brukt av /P: skriver "Press any key to continue . . ." og
;              venter pa et tastetrykk (uten ekko) via INT 21h AH=08h, som
;              er en ren DOS-funksjon (ikke BIOS/video) akkurat som resten
;              av programmets utskrift/inndata.
; ----------------------------------------------------------------------------
do_pause:
                push    ax
                push    si
                mov     si, press_key_msg
                call    print_string_asciz
                mov     ah, 08h                 ; les ett tegn fra tastaturet, uten ekko
                int     21h
                call    print_crlf
                pop     si
                pop     ax
                ret
