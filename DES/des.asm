; ============================================================================
; DES.COM  --  Enkel DIR-erstatning for DOS/4DOS med DESCRIPT.ION-stotte
; Versjon: 1.1
; ============================================================================
;
; Hva programmet gjor:
;   - Skriver en kort header som ekte DIR ("Volume in drive X is ..." og
;     "Directory of ..."), men UTEN footer og dato/klokkeslett.
;   - Kolonnen etter filnavnet viser "<DIR>" for kataloger, eller filstorrelse
;     i KB (avrundet opp) for vanlige filer.
;   - Etter det skrives beskrivelsen som er registrert for filen i en
;     4DOS-kompatibel DESCRIPT.ION-fil i samme katalog som filene som listes.
;   - Listen sorteres slik at kataloger kommer forst, deretter filer, og
;     innenfor hver av de to gruppene alfabetisk (case-insensitivt).
;   - DESCRIPT.ION / DESCRIPT.OLD / DESCRIPT.BAK vises aldri i listen selv.
;   - Svitsjen /P (hvor som helst pa kommandolinjen) gir sidevis utskrift,
;     akkurat som DIR /P: stopper og venter pa tastetrykk hver 23. linje. Lange
;     beskrivelser ruller samtidig pa sine egne linjer etter ett sekunds pause.
;
; Bruk:
;   DES              -> lister *.* i gjeldende katalog
;   DES *.EXE        -> lister kun *.EXE i gjeldende katalog
;   DES C:\SPILL\*.* -> lister *.* i C:\SPILL, og leser C:\SPILL\DESCRIPT.ION
;   DES /P           -> som over, men med sidevis utskrift
;   DES *.EXE /P     -> svitsjen kan sta for eller etter monsteret
;   DES /? eller /H  -> viser hjelpetekst
;
; Viktig om farger:
;   Ved en stottet lokal tekstskjerm skrives fillinjene direkte til skjermminnet
;   (B800h/B000h), slik at farge og horisontal rulling fungerer raskt. COLORDIR
;   velger farge per filtype; uten COLORDIR brukes den opprinnelige skjermfargen.
;   Ved omdirigering eller ustottet maskinvare faller programmet tilbake til
;   ren DOS-utskrift via INT 21h, slik at tekstutdata fortsatt blir korrekt.
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
ENTRY_SIZE      equ     18              ; 13 bytes navn (ASCIZ) + 1 byte attributt + 4 bytes filstorrelse
NAME_FIELD_LEN  equ     13              ; DOS' DTA-filnavnfelt er alltid 13 bytes (8.3-format + null)
SIZE_FIELD_OFS  equ     NAME_FIELD_LEN + 1 ; filstorrelsen (dword) ligger rett etter attributtbyten
NAME_COL_WIDTH  equ     13              ; bredde pa filnavn-kolonnen i utskriften
DIR_COL_WIDTH   equ     5               ; lengden av selve teksten "<DIR>"
INFO_COL_WIDTH  equ     9               ; bredde pa kolonnen som viser "<DIR>" eller storrelse i "NN KB"
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

; Sok-/stimonsteret hentet fra kommandolinjen (f.eks. "*.EXE") og full sti
; til DESCRIPT.ION - definert som EQU-adresser helt nederst i filen (se
; "RUNTID-BUFFERE") for a holde selve .COM-filen liten pa disk.

; Standardmonster nar ingen argument er gitt pa kommandolinjen.
default_pattern db      '*.*', 0

; Faste filnavn vi aldri skal vise i listen (selve beskrivelsesfilene).
descript_name     db    'DESCRIPT.ION', 0
descript_old_name db    'DESCRIPT.OLD', 0
descript_bak_name db    'DESCRIPT.BAK', 0

; Teksten som vises i DIR-kolonnen for kataloger.
dir_marker      db      '<DIR>', 0

; DOS "Disk Transfer Area" (our_dta) og filtabellen (entries) er begge
; definert nederst i filen (se "RUNTID-BUFFERE") for a spare plass pa disk.
; our_dta er 43 bytes: attributt/tid/dato/storrelse/ASCIZ-navn i 8.3-format.
entry_count     dw      0

; Midlertidig peker brukt mens vi bygger en ny oppforing i "entries".
tmp_entry_ptr   dw      0

; Antall gjenstaende "passeringer" i boble-sorteringen.
passes_left     dw      0

; Midlertidig 14-bytes buffer (swap_buf, definert nederst i filen) brukt til
; a bytte om pa to oppforinger ved sortering, samt to hjelpepekere som
; holder styr pa hvilke to oppforinger som byttes (unngar rotete stackbruk).
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
; Selve bufferet (descript_data, 16 KB) er definert nederst i filen - ellers
; ville .COM-filen blitt 16 KB storre pa disk helt uten grunn.
DESCRIPT_DATA_LEN equ   16384           ; maks storrelse pa DESCRIPT.ION vi stotter
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
help_flag       dw      0               ; 1 hvis /? eller /H ble funnet pa kommandolinjen
lines_printed   dw      0               ; antall linjer skrevet siden forrige pause
                                        ; (tok_buf - ett "ord" fra kommandolinjen - er definert nederst i filen)
switch_p        db      '/P', 0         ; svitsjen vi ser etter (sammenlignes case-insensitivt)
switch_h        db      '/H', 0
switch_question db      '/?', 0
press_key_msg   db      'Press any key to continue . . .', 0

help_brand_msg  db      'DES 1.1 - Description Enhanced System', 0
help_copyright_msg db   'Copyright (C) 2026 Dag Erik Hages', 091h, 'ter / Retro Erik', 0
help_summary_msg db     'Lists files and directories with descriptions from DESCRIPT.ION.', 0
help_color_msg  db      'Uses ColorDir colors when COLORDIR is set in AUTOEXEC.BAT.', 0
help_desc_msg   db      'DESCRIPT.ION has one description per file, for example:', 0
help_example_msg db     '  MONKEY.EXE Monkey Island  1990 EGA/VGA/ADLIB', 0
help_colordir_msg db    '4DOS ColorDir uses COLORDIR to select colors by directory or extension.', 0
help_colordir_example_msg db '  SET ColorDir=dirs:bri mag; zip arj:bri blu; com exe:bri gre; bat: bri red; gif  jpg png:yel; txt me now:gre', 0
help_standalone_msg db  'DES reads DESCRIPT.ION and COLORDIR itself; 4DOS is not required.', 0
help_paging_msg db      'To list one screen at a time use /P (just like DIR).', 0
help_scroll_msg db      'In this mode, DES scrolls descriptions longer than 57 characters.', 0
help_pause_msg db       'To pause horizontal scrolling, use the PAUSE key on the keyboard.', 0
help_usage_msg  db      'Usage: DES [path\pattern] [/P]', 0
help_switches_msg db    '       DES /? or DES /H   Show this help', 0

; --- Variabler for header ("Volume in drive..." / "Directory of...") ---
; (vol_dta, truename_input, truename_buf og vol_pattern er alle definert
; nederst i filen, se "RUNTID-BUFFERE")
current_dir_alias db    '.', 0          ; DOS-alias for "gjeldende katalog", brukt nar ingen sti er oppgitt
hdr_sep_pos     dw      0FFFFh          ; indeks til siste '\'/':' i search_pattern (for header-linjen)
vol_drive_letter db     0               ; stasjonsbokstaven vi viser i headeren
vol_in_drive_msg db     ' Volume in drive ', 0
vol_is_msg      db      ' is ', 0
vol_nolabel_msg db      ' has no label', 0
dir_of_msg      db      ' Directory of  ', 0

; Kreditering: "By Retro Erik" host-justert pa Volume-linja (der "Retro Erik"
; far et bokstav-for-bokstav regnbue-fargeskjema, akkurat som i AUTOEXEC.BAT),
; og en rod, hoyrejustert youtube-URL rett under (se print_header).
credit_msg      db      'By Retro Erik', 0   ; kun brukt til a beregne bredden for host-justering
by_prefix       db      'By ', 0
retro_erik_msg  db      'Retro Erik', 0      ; skrives bokstav for bokstav med rainbow_colors under
; Farge for hver bokstav i "Retro Erik" (R e t r o <mellomrom> E r i k),
; samme fargerekkefolge som ANSI-sekvensen i AUTOEXEC.BAT.
rainbow_colors  db      0Ch, 0Eh, 0Ah, 0Bh, 0Dh, 0Dh, 09h, 0Ch, 0Eh, 0Ah
youtube_msg     db      'www.youtube.com/c/RetroErik', 0
CREDIT_COLOR    equ     0Ch             ; lys rod (bit 3 = bright + rod=4)
RIGHT_MARGIN    equ     SCREEN_WIDTH - 1 ; host-justerte headerlinjer slutter HER, ikke pa
                                        ; selve siste kolonne - a fylle kolonne 80 helt ut kan fa
                                        ; skjermen til a linjeskifte pa egen hand FOR var egen CRLF,
                                        ; som ga en "spok-tom" linje (sett pa ekte maskinvare)

; --- Variabler for ColorDir-basert filfarging ---
;
; 4DOS setter miljovariabelen COLORDIR til noe sant som:
;   dirs:bri mag; zip arj:bri blu; com exe:bri gre; txt me now:gre
; Vi leser denne selv (krever altsa IKKE at 4DOS kjorer, bare at variabelen
; finnes i miljoet) og fargelegger filnavn/DIR-kolonnen deretter, via BIOS
; INT 10h (som er standardmaten a sette farge pa i tekstmodus - IKKE direkte
; skjermminne, IKKE ANSI). Resten av linjen (beskrivelse, CRLF osv.) forblir
; upaavirket og bruker fortsatt ren INT 21h AH=02h/09h som for.
colordir_active dw      0               ; 1 hvis COLORDIR ble funnet i miljoet OG trygt a fargelegge
                                        ; (colordir_buf - ravaerdien av variabelen - er definert nederst i filen)
colordir_varname db     'COLORDIR=', 0

; 1 hvis det er trygt a skrive rett til skjermminnet (ekte skjerm, kjent
; 80-kolonners tekstmodus, side 0) - satt av setup_colors. Brukes bade for
; ColorDir-fargelegging OG for den faste krediteringsfargen i print_header,
; uavhengig av om COLORDIR i det hele tatt er satt.
video_write_safe dw     0

dirs_color_found dw     0               ; 1 hvis en dirs-regel ble funnet
dirs_color      db      0               ; fargen kataloger skal fa

; ext_color_table ({ext[4], farge} per oppforing) er definert nederst i filen.
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

; tiny_tok, tiny_tok2 og ext_tok (sma midlertidige token-buffere) er
; definert nederst i filen sammen med de andre runtid-bufferne.

current_color   db      07h             ; fargen som skal brukes for oppforingen vi skriver na
ambient_attr    db      07h             ; skjermens attributt ved oppstart (brukes som noytral/fallback-farge)

; --- Variabler for rask, linjevis fargeutskrift (se flush_colored_line) ---
video_segment   dw      0B800h          ; 0B800h (farge) eller 0B000h (monokrom) - satt av detect_video_segment
video_columns   db      80              ; antall tegnkolonner pa skjermen - satt av detect_video_segment
RENDER_BUF_LEN  equ     90              ; god margin over maks linjebredde (13+9+1+57=80)
                                        ; (render_buf selv er definert nederst i filen)
render_len      dw      0               ; antall tegn lagt i render_buf sa langt
SIZE_DIGIT_BUF_LEN equ  16              ; god margin for "NNNNNNNNNN KB"+null (32-bits tall)
                                        ; (size_digit_buf selv er definert nederst i filen)
size_digit_len  dw      0               ; lengden av den ferdigbygde "NNNN KB"-strengen
fcl_row         db      0               ; rad/kolonne ved linjestart, lagret unna FOR "mul" odelegger DX
fcl_col         db      0

; --- Variabler for /P-rulling av beskrivelser som ikke far plass ---
; Alle linjer med for lange beskrivelser pa gjeldende side registreres i
; scroll_slots (i stedet for a stoppe opplistingen der og da), slik at HELE
; siden blir tegnet ferdig forst - og etterpa animeres ALLE de lange linjene
; SAMTIDIG, helt til brukeren trykker en tast (se do_pause_with_scrolling).
SCROLL_DELAY_TICKS equ  2               ; ~2 klokketikk (BIOS-tikk er ca. 18.2/sek) mellom hvert animasjonssteg
SCROLL_START_DELAY_TICKS equ 18         ; ~1 sekund pause for rullingen begynner, sa brukeren far lest starten
MAX_SCROLL_SLOTS equ    PAGE_SIZE       ; kan aldri vaere flere lange linjer enn linjer pa en side
SCROLL_SLOT_SIZE equ    11             ; rad(1)+kolonne(1)+desc_start(2)+desc_len(2)+bredde(2)+offset(2)+farge(1)
scroll_slot_count dw    0               ; antall registrerte rulle-linjer pa gjeldende side
                                        ; (scroll_slots selv er definert nederst i filen)
scroll_wait_ticks dw    0               ; onsket ventetid, lagret unna FOR INT 1Ah overskriver CX
dpws_msg_row    db      0               ; markorposisjon rett etter "Press any key..."-meldingen,
dpws_msg_col    db      0               ; sa vi kan flytte markoren dit igjen etter animasjonen
dpws_slot_idx   dw      0               ; lopeindeks lagret i minne - BX kan bli overskrevet av INT 10h internt

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
                cmp     word [help_flag], 0
                je      .main_run
                call    print_help
                jmp     .main_exit

.main_run:
                call    build_desc_path         ; regn ut hvilken katalog DESCRIPT.ION ligger i -> desc_path
                call    load_descript_ion       ; les HELE DESCRIPT.ION inn i minnet EN gang (fart!)
                call    setup_colors            ; les ambient skjermfarge + evt. COLORDIR-miljovariabel
                call    print_header            ; skriv "Volume in drive..." og "Directory of..."
                call    collect_entries         ; finn alle filer/kataloger som matcher search_pattern
                call    sort_entries            ; sorter: kataloger forst, deretter filer, alfabetisk
                call    print_entries           ; skriv ut listen med beskrivelser (med /P-sidevisning)

.main_exit:
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
                mov     word [help_flag], 0
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
                jne     .pc_not_pause
                mov     word [pause_flag], 1
                jmp     .pc_skip_spaces
.pc_not_pause:
                push    si
                mov     si, tok_buf
                mov     di, switch_h
                call    str_ieq
                pop     si
                je      .pc_set_help
                push    si
                mov     si, tok_buf
                mov     di, switch_question
                call    str_ieq
                pop     si
                jne     .pc_not_switch
.pc_set_help:
                mov     word [help_flag], 1
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
;        (B800h/B000h) det er. Dette avgjores UAVHENGIG av om COLORDIR er
;        satt, siden f.eks. "By Retro Erik"-krediteringen skal fargelegges
;        selv om ingen ColorDir-variabel finnes.
;     5. Hvis COLORDIR finnes OG det er trygt a skrive rett til skjermen,
;        tolkes verdien til en liten oppslagstabell (ext_color_table +
;        dirs_color) som print_entries senere bruker.
; ============================================================================
setup_colors:
                call    read_ambient_attr

                mov     word [video_write_safe], 1
                call    check_stdout_is_device  ; nullstiller video_write_safe hvis omdirigert
                cmp     word [video_write_safe], 0
                je      .sc_no_video
                call    detect_video_segment    ; nullstiller video_write_safe ved ukjent modus/side
.sc_no_video:

                call    find_and_copy_colordir
                cmp     word [colordir_active], 0
                je      .sc_done
                cmp     word [video_write_safe], 0
                je      .sc_disable_colordir    ; COLORDIR funnet, men usikkert a skrive fargelagt
                call    parse_colordir
                jmp     .sc_done
.sc_disable_colordir:
                mov     word [colordir_active], 0
.sc_done:
                ret


; ----------------------------------------------------------------------------
; check_stdout_is_device
;   Bruker INT 21h AH=44h (IOCTL), AL=00h (Get Device Information) pa handtak
;   1 (standard utdata) for a sjekke om utdata faktisk gar til en tegnenhet
;   (skjermen), eller om den er omdirigert til en fil/rar. Bit 7 i den
;   returnerte enhetsinformasjonen (DL) er satt for ekte enheter. Hvis
;   utdata IKKE er en enhet, nullstiller vi video_write_safe - se setup_colors.
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
                mov     word [video_write_safe], 0

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
;   direkte skjermskriving helt (video_write_safe=0) i stedet for a gjette feil.
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
                mov     word [video_write_safe], 0  ; ukjent/ustottet modus - trygg fallback
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
                mov     word [video_write_safe], 0  ; bredde != 80 eller side != 0 - trygg fallback

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
; append_size_or_dir
;   Legger til info-kolonnen (INFO_COL_WIDTH bred, host-justert) i render_buf:
;   "<DIR>" for kataloger, ellers filstorrelsen opprundet til naermeste KB
;   (f.eks. "1024K"), akkurat slik Windows/moderne verktoy runder opp sma
;   filer til minst 1K i stedet for a vise "0K" for alt under 1024 bytes.
;   Input:  SI -> oppforingen (navn+attributt+storrelse). SI bevares.
;   Bruker 32-bits aritmetikk (to 16-bits ord) siden 8086 ikke har 32-bits
;   registre - se kommentarene inne i rutinen for hvordan hver del virker.
; ----------------------------------------------------------------------------
append_size_or_dir:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di

                mov     al, [si + NAME_FIELD_LEN]
                test    al, 10h                 ; bit 4 = katalog
                jz      .asd_file

                ; --- katalog: mellomrom-fyll, sa "<DIR>" (alltid DIR_COL_WIDTH tegn) ---
                mov     cx, INFO_COL_WIDTH - DIR_COL_WIDTH
.asd_dir_pad:
                cmp     cx, 0
                je      .asd_dir_pad_done
                mov     al, ' '
                call    append_render_char
                dec     cx
                jmp     .asd_dir_pad
.asd_dir_pad_done:
                push    si
                mov     si, dir_marker
                call    append_render_string
                pop     si
                jmp     .asd_done

.asd_file:
                ; --- fil: hent 32-bits storrelse (lav-ord i AX, hoy-ord i DX) ---
                mov     ax, [si + SIZE_FIELD_OFS]
                mov     dx, [si + SIZE_FIELD_OFS + 2]

                ; rund opp til naermeste 1024 (men la 0 bytes forbli 0 KB)
                cmp     ax, 0
                jne     .asd_round
                cmp     dx, 0
                je      .asd_no_round
.asd_round:
                add     ax, 1023
                adc     dx, 0
.asd_no_round:
                ; del pa 1024 = skift DX:AX 10 bit til hoyre (32-bits skift via to 16-bits ord)
                mov     cx, 10
.asd_shift:
                shr     dx, 1
                rcr     ax, 1
                loop    .asd_shift
                ; DX:AX = storrelsen i KB na

                mov     di, size_digit_buf + 15
                mov     byte [di], 0            ; null-terminator
                dec     di
                mov     byte [di], 'B'
                dec     di
                mov     byte [di], 'K'
                dec     di
                mov     byte [di], ' '
                dec     di
                mov     word [size_digit_len], 3 ; teller " KB" allerede

.asd_digit_loop:
                ; Del 32-bits DX:AX pa 10 uten a risikere overflow: del hoy-ordet
                ; forst, for resten av den divisjonen kombineres med lav-ordet i
                ; en ny divisjon (standardteknikk for 32-bits/16-bits-divisjon pa 8086).
                mov     bx, ax                  ; ta vare pa lav-ordet
                mov     ax, dx                  ; AX = hoy-ordet
                xor     dx, dx
                mov     cx, 10
                div     cx                      ; AX = ny hoy-kvotient, DX = rest (0-9) til lav-ordet
                xchg    ax, bx                  ; AX = opprinnelig lav-ord, BX = ny hoy-kvotient
                div     cx                      ; AX = ny lav-kvotient, DX = neste siffer (0-9)

                push    ax                      ; AX brukes na midlertidig til a bygge tegnet
                mov     al, dl
                add     al, '0'
                mov     [di], al
                dec     di
                inc     word [size_digit_len]
                pop     ax

                mov     dx, bx                  ; DX:AX = ny (mindre) kvotient til neste runde
                cmp     dx, 0
                jne     .asd_digit_loop
                cmp     ax, 0
                jne     .asd_digit_loop
                inc     di                      ; DI -> forste tegn i den ferdige "NNNN KB"-strengen

                ; --- mellomrom-fyll foran tallet, sa hele feltet blir INFO_COL_WIDTH bredt ---
                mov     cx, INFO_COL_WIDTH
                sub     cx, [size_digit_len]
                jle     .asd_no_pad
.asd_file_pad:
                cmp     cx, 0
                je      .asd_no_pad
                push    ax
                mov     al, ' '
                call    append_render_char
                pop     ax
                dec     cx
                jmp     .asd_file_pad
.asd_no_pad:
                push    si
                mov     si, di
                call    append_render_string
                pop     si

.asd_done:
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
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
;   Hvis det ikke er trygt a skrive rett til skjermen (omdirigert utdata,
;   ukjent videomodus osv.), faller vi tilbake til ren INT 21h-utskrift av
;   bufferet, tegn for tegn - ferdig ubetinget uten farge, akkurat som for.
;   Brukes bade for ColorDir-fargelagte fillinjer og for faste, hardkodede
;   fargelinjer som krediteringen i print_header (uavhengig av ColorDir).
; ----------------------------------------------------------------------------
flush_colored_line:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    es

                cmp     word [video_write_safe], 0
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
                xor     ax, ax
                mov     al, [fcl_col]
                add     ax, [render_len]
                cmp     ax, SCREEN_WIDTH - 1
                jbe     .fcl_cursor_in_range
                mov     ax, SCREEN_WIDTH - 1    ; en CRLF fra kalleren flytter videre til neste rad
.fcl_cursor_in_range:
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


; ----------------------------------------------------------------------------
; print_one_colored_char
;   Skriver ETT enkelt tegn i en gitt fargeattributt, ved a gjenbruke
;   render_buf/flush_colored_line-mekanismen for en "linje" pa bare ett tegn.
;   Brukt til bokstav-for-bokstav regnbuefarging (se print_credit_and_crlf) -
;   ikke ment for lange strenger, siden hvert tegn her koster et fullt
;   BIOS-kursoroppslag (helt greit for noen fa tegn, men ikke for en fillinje).
;   Input: AL = tegn, DL = fargeattributt.
; ----------------------------------------------------------------------------
print_one_colored_char:
                push    ax
                push    bx

                mov     bl, al                  ; ta vare pa tegnet mens render_len nullstilles
                mov     word [render_len], 0
                mov     al, bl
                call    append_render_char
                mov     [current_color], dl
                call    flush_colored_line

                pop     bx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; wait_ticks_or_key
;   Venter i CX BIOS-klokketikk (INT 1Ah, ca. 18.2 tikk/sekund - uavhengig av
;   CPU-hastighet, sa dette virker likt pa en 8088 og en 386), mens den hele
;   tiden sjekker om et tastetrykk venter (INT 21h AH=0Bh).
;   Input:  CX = antall tikk a vente.
;   Output: CF=1 hvis en tast ble trykket (den er da allerede lest/kastet).
;           CF=0 hvis hele ventetiden gikk uten noe tastetrykk.
; ----------------------------------------------------------------------------
wait_ticks_or_key:
                push    ax
                push    bx
                push    dx

                mov     [scroll_wait_ticks], cx ; ta vare pa onsket ventetid FOR INT 1Ah bruker CX selv

                mov     ah, 0
                int     1Ah                     ; -> CX:DX = klokketikk siden midnatt
                mov     bx, dx                  ; BX = starttidspunkt (lavordet holder for en kort vent)

.wtk_poll:
                mov     ah, 0Bh
                int     21h                     ; AL = 0FFh hvis et tastetrykk venter, 00h ellers
                cmp     al, 0
                je      .wtk_check_time
                mov     ah, 08h                 ; les (og kast) tasten, uten ekko
                int     21h
                stc
                jmp     .wtk_ret

.wtk_check_time:
                mov     ah, 0
                int     1Ah                     ; -> CX:DX pa nytt (CX odelegges - derfor lagret unna over)
                sub     dx, bx
                cmp     dx, [scroll_wait_ticks]
                jb      .wtk_poll
                clc

.wtk_ret:
                pop     dx
                pop     bx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; register_scroll_slot
;   Kalles i stedet for a rulle med en gang: tegner det forste (statiske)
;   vinduet av en for-lang beskrivelse akkurat der den skal sta, og husker
;   posisjon/tekst/farge i scroll_slots slik at HELE siden kan tegnes ferdig
;   forst - selve rullingen skjer samlet for alle slike linjer i
;   do_pause_with_scrolling, nar siden er komplett.
;   Input: AX = tilgjengelig bredde (antall tegn som skal vises om gangen).
;   Bruker ogsa de globale desc_start/desc_len (satt av find_description) og
;   current_color (satt av print_entries for denne oppforingen).
;   Hvis scroll_slots skulle vaere full (bor aldri skje - MAX_SCROLL_SLOTS
;   er like stor som en hel side), faller vi tilbake til vanlig avkutting.
; ----------------------------------------------------------------------------
register_scroll_slot:
                push    bx
                push    cx
                push    dx
                push    si
                push    di

                cmp     word [scroll_slot_count], MAX_SCROLL_SLOTS
                jae     .rss_fallback_truncate

                push    ax                      ; ta vare pa tilgjengelig bredde under adresseberegningen
                mov     bx, [scroll_slot_count]
                mov     ax, bx
                mov     cx, SCROLL_SLOT_SIZE
                mul     cx
                mov     di, scroll_slots
                add     di, ax
                pop     ax                      ; AX = tilgjengelig bredde igjen

                mov     bx, [lines_printed]
                mov     [di + 0], bl            ; raden er kjent fra side-telleren, uten BIOS-markoravhengighet
                mov     bx, [cur_col]
                mov     [di + 1], bl

                mov     [di + 6], ax            ; tilgjengelig bredde
                mov     bx, [desc_start]
                mov     [di + 2], bx
                mov     bx, [desc_len]
                mov     [di + 4], bx
                mov     word [di + 8], 0        ; rulleposisjon starter pa 0
                mov     bl, [current_color]
                mov     [di + 10], bl

                mov     word [render_len], 0    ; tegn det forste vinduet med en gang
                mov     si, descript_data
                add     si, [di + 2]
                mov     cx, [di + 4]
                cmp     cx, [di + 6]
                jbe     .rss_have_len
                mov     cx, [di + 6]
.rss_have_len:
.rss_copy:
                cmp     cx, 0
                je      .rss_copy_done
                mov     al, [si]
                call    append_render_char
                inc     si
                dec     cx
                jmp     .rss_copy
.rss_copy_done:
                mov     ax, [di + 6]
                sub     ax, [render_len]
                jle     .rss_no_fill
                mov     cx, ax
.rss_fill:
                cmp     cx, 0
                je      .rss_no_fill
                mov     al, ' '
                call    append_render_char
                dec     cx
                jmp     .rss_fill
.rss_no_fill:
                call    flush_colored_line

                inc     word [scroll_slot_count]
                jmp     .rss_done

.rss_fallback_truncate:
                mov     word [render_len], 0
                mov     di, descript_data
                add     di, [desc_start]
                mov     cx, ax
.rss_trunc_copy:
                cmp     cx, 0
                je      .rss_trunc_done
                mov     al, [di]
                call    append_render_char
                inc     di
                dec     cx
                jmp     .rss_trunc_copy
.rss_trunc_done:
                call    flush_colored_line

.rss_done:
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                ret


; ----------------------------------------------------------------------------
; redraw_and_advance_slot
;   Tegner ETT animasjonssteg for en registrert rulle-linje (se
;   register_scroll_slot), og flytter dens rulleposisjon ett tegn videre
;   (tilbake til 0 nar den nar slutten av beskrivelsen - kontinuerlig rulling).
;   Input: BX = indeks inn i scroll_slots.
; ----------------------------------------------------------------------------
redraw_and_advance_slot:
                push    ax
                push    cx
                push    dx
                push    si
                push    di

                mov     ax, bx
                mov     cx, SCROLL_SLOT_SIZE
                mul     cx
                mov     di, scroll_slots
                add     di, ax                  ; DI -> denne slottens data

                mov     word [render_len], 0
                mov     si, descript_data
                add     si, [di + 2]            ; + desc_start
                add     si, [di + 8]            ; + gjeldende rulleposisjon
                mov     cx, [di + 4]            ; full lengde
                sub     cx, [di + 8]            ; - det vi allerede har rullet forbi
                cmp     cx, [di + 6]            ; vs. tilgjengelig bredde
                jbe     .rdas_have_len
                mov     cx, [di + 6]
.rdas_have_len:
.rdas_copy:
                cmp     cx, 0
                je      .rdas_copy_done
                mov     al, [si]
                call    append_render_char
                inc     si
                dec     cx
                jmp     .rdas_copy
.rdas_copy_done:
                mov     ax, [di + 6]
                sub     ax, [render_len]
                jle     .rdas_no_fill
                mov     cx, ax
.rdas_fill:
                cmp     cx, 0
                je      .rdas_no_fill
                mov     al, ' '
                call    append_render_char
                dec     cx
                jmp     .rdas_fill
.rdas_no_fill:
                mov     al, [di + 10]           ; hver linje beholder SIN EGEN farge under animasjonen
                mov     [current_color], al

                push    es
                push    di
                mov     es, [video_segment]
                mov     al, [di + 0]
                mov     ah, 0
                mov     cl, [video_columns]
                mov     ch, 0
                mul     cx
                mov     cl, [di + 1]
                mov     ch, 0
                add     ax, cx
                shl     ax, 1
                mov     di, ax
                mov     si, render_buf
                mov     cx, [render_len]
.rdas_write:
                cmp     cx, 0
                je      .rdas_write_done
                lodsb
                mov     ah, [current_color]
                stosw
                loop    .rdas_write
.rdas_write_done:
                pop     di
                pop     es

                mov     ax, [di + 8]            ; flytt rulleposisjonen ett tegn videre
                inc     ax
                cmp     ax, [di + 4]
                jb      .rdas_store
                xor     ax, ax                  ; naadd slutten - start forfra (kontinuerlig rulling)
.rdas_store:
                mov     [di + 8], ax

                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; do_pause_with_scrolling
;   Brukes i stedet for do_pause ved hver /P-sidegrense. Hvis ingen linjer pa
;   siden trengte rulling, oppforer den seg akkurat som do_pause. Ellers:
;   skriver "Press any key..." EN gang, og animerer SAMTIDIG alle registrerte
;   rulle-linjer (scroll_slots) til brukeren trykker en tast.
; ----------------------------------------------------------------------------
do_pause_with_scrolling:
                cmp     word [scroll_slot_count], 0
                jne     .dpws_animate
                call    do_pause
                ret

.dpws_animate:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si

                mov     si, press_key_msg
                call    print_string_asciz      ; vises en gang, under siste linje pa siden

                xor     bh, bh                  ; husk hvor markoren star etter meldingen, sa vi kan
                mov     ah, 03h                 ; flytte den dit igjen nar animasjonen er ferdig
                int     10h
                mov     [dpws_msg_row], dh
                mov     [dpws_msg_col], dl

                mov     cx, SCROLL_START_DELAY_TICKS
                call    wait_ticks_or_key       ; la brukeren lese begynnelsen for rullingen starter
                jc      .dpws_key_pressed

.dpws_anim_loop:
                mov     word [dpws_slot_idx], 0
.dpws_slot_loop:
                mov     bx, [dpws_slot_idx]
                cmp     bx, [scroll_slot_count]
                jae     .dpws_slots_done
                call    redraw_and_advance_slot
                inc     word [dpws_slot_idx]
                jmp     .dpws_slot_loop
.dpws_slots_done:

                mov     cx, SCROLL_DELAY_TICKS
                call    wait_ticks_or_key
                jnc     .dpws_anim_loop         ; ingen tast enna - fortsett a animere

.dpws_key_pressed:
                mov     dh, [dpws_msg_row]      ; tast trykket - flytt markoren tilbake under meldingen
                mov     dl, [dpws_msg_col]
                xor     bh, bh
                mov     ah, 02h
                int     10h
                call    print_crlf

                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret


; ----------------------------------------------------------------------------
; print_credit_and_crlf
;   Hoyrejusterer "By Retro Erik" til RIGHT_MARGIN pa slutten av gjeldende
;   linje (Volume-linja), og avslutter linja med CRLF. "By " skrives i
;   vanlig (noytral) farge, mens "Retro Erik" far et bokstav-for-bokstav
;   regnbue-fargeskjema (rainbow_colors) - akkurat som i AUTOEXEC.BAT.
; ----------------------------------------------------------------------------
print_credit_and_crlf:
                push    ax
                push    bx
                push    cx
                push    si

                mov     si, credit_msg
                call    strlen                  ; AX = lengden av "By Retro Erik" (kun for a plassere den)
                mov     cx, RIGHT_MARGIN
                sub     cx, ax
                sub     cx, [cur_col]
                cmp     cx, 0
                jle     .pcc_no_pad
.pcc_pad_loop:
                cmp     cx, 0
                je      .pcc_no_pad
                mov     dl, ' '
                call    print_char
                dec     cx
                jmp     .pcc_pad_loop
.pcc_no_pad:
                mov     si, by_prefix           ; "By " skrives i vanlig, noytral farge
                call    print_string_asciz

                mov     si, retro_erik_msg      ; "Retro Erik", en bokstav om gangen i regnbuefarger
                mov     bx, 0                   ; BX = indeks inn i rainbow_colors
.pcc_rainbow_loop:
                mov     al, [si]
                cmp     al, 0
                je      .pcc_rainbow_done
                mov     dl, [rainbow_colors + bx]
                call    print_one_colored_char  ; Input: AL=tegn, DL=fargeattributt
                inc     si
                inc     bx
                jmp     .pcc_rainbow_loop
.pcc_rainbow_done:

                call    print_crlf

                pop     si
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
;
;   Volume-linja far "By Retro Erik" host-justert pa samme linje, og
;   "Directory of..."-linja far "www.youtube.com/c/RetroErik" i rod skrift
;   host-justert pa SIN linje - se print_credit_and_crlf og CREDIT_COLOR.
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
                call    print_credit_and_crlf   ; host-justerer "By Retro Erik" og avslutter linja
                jmp     .ph_dir_line

.ph_no_label:
                mov     si, vol_in_drive_msg    ; " Volume in drive X has no label"
                call    print_string_asciz
                mov     dl, [vol_drive_letter]
                call    print_char
                mov     si, vol_nolabel_msg
                call    print_string_asciz
                call    print_credit_and_crlf   ; host-justerer "By Retro Erik" og avslutter linja

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

                ; --- youtube-URL i rod skrift, hoyrejustert pa SAMME linje ---
                mov     si, youtube_msg
                call    strlen                  ; AX = lengden av URL-en
                mov     cx, RIGHT_MARGIN
                sub     cx, ax
                sub     cx, [cur_col]
                cmp     cx, 0
                jle     .ph_yt_no_pad
.ph_yt_pad_loop:
                cmp     cx, 0
                je      .ph_yt_no_pad
                mov     dl, ' '
                call    print_char
                dec     cx
                jmp     .ph_yt_pad_loop
.ph_yt_no_pad:
                mov     word [render_len], 0
                mov     si, youtube_msg
                call    append_render_string
                mov     byte [current_color], CREDIT_COLOR
                call    flush_colored_line      ; (faller tilbake til vanlig tekst hvis usikkert a fargelegge)
                call    print_crlf
                call    print_crlf              ; blank linje mellom header og fillisten

                mov     word [lines_printed], 3  ; header(2)+blank teller med i /P-sidevisningen


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

                mov     ax, [our_dta + 1Ah]    ; filstorrelse (dword, lav-ord) fra DTA-en
                mov     [di + SIZE_FIELD_OFS], ax
                mov     ax, [our_dta + 1Ch]    ; filstorrelse (dword, hoy-ord)
                mov     [di + SIZE_FIELD_OFS + 2], ax

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
;     <"<DIR>" eller filstorrelse i KB (opprundet), host-justert i INFO_COL_WIDTH>
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

                ; --- Bestem farge for denne oppforingen (current_color settes ALLTID her, ---
                ; --- selv nar ColorDir ikke er i bruk - ellers kunne en tidligere satt   ---
                ; --- farge, f.eks. fra krediteringslinja, "lekke" inn i fillisten)       ---
                mov     al, [si + NAME_FIELD_LEN]
                cmp     word [colordir_active], 0
                je      .pe_ambient_only
                call    get_entry_color         ; Input: SI=navn, AL=attributt -> AL=farge, CF=0 hvis match
                jnc     .pe_color_set
                mov     al, [ambient_attr]      ; ingen regel matchet - bruk skjermens omgivelsesfarge
.pe_color_set:
                mov     [current_color], al
                jmp     .pe_no_colorlookup
.pe_ambient_only:
                mov     al, [ambient_attr]
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

                call    append_size_or_dir      ; "<DIR>" eller filstorrelse i KB, host-justert (SI bevares)

                mov     al, ' '                 ; ett mellomrom mellom info-kolonnen og beskrivelsen
                call    append_render_char

                call    flush_colored_line      ; skriv navn+info-kolonne NA (beskrivelsen haandteres
                                                ; separat under, sa den evt. kan rulles pa fast posisjon)

                ; SI peker fortsatt pa filnavnet for oppforing BX (er ikke endret over)
                call    find_description        ; CF=0 og desc_start/desc_len satt hvis funnet
                jc      .pe_no_desc

                mov     ax, SCREEN_WIDTH        ; AX = tilgjengelig bredde til resten av linja
                sub     ax, [cur_col]
                cmp     [desc_len], ax
                jbe     .pe_desc_fits

                ; --- Beskrivelsen er for lang til a fa plass i ett steg ---
                cmp     word [pause_flag], 0    ; kun rull hvis /P er i bruk (noen star klar til a
                je      .pe_desc_truncate       ; trykke en tast) OG trygt a skrive rett til skjermen
                cmp     word [video_write_safe], 0
                je      .pe_desc_truncate

                call    register_scroll_slot    ; tegner et forste, statisk vindu NA og husker linja
                jmp     .pe_no_desc             ; til felles rulling nar hele siden er ferdig tegnet

.pe_desc_truncate:
                mov     word [render_len], 0    ; ingen /P (eller usikkert a fargelegge) - avkutt som for
                mov     cx, ax
                jmp     .pe_desc_copy_setup

.pe_desc_fits:
                mov     word [render_len], 0
                mov     cx, [desc_len]
.pe_desc_copy_setup:
                mov     di, descript_data
                add     di, [desc_start]
.pe_desc_copy:
                cmp     cx, 0
                je      .pe_desc_flush
                mov     al, [di]
                call    append_render_char
                inc     di
                dec     cx
                jmp     .pe_desc_copy
.pe_desc_flush:
                call    flush_colored_line
.pe_no_desc:

                call    print_crlf

                cmp     word [pause_flag], 0    ; er /P i bruk?
                je      .pe_no_pause
                inc     word [lines_printed]
                mov     ax, [lines_printed]
                cmp     ax, PAGE_SIZE
                jb      .pe_no_pause
                call    do_pause_with_scrolling ; "Press any key..." + evt. samtidig rulling av lange linjer
                mov     word [lines_printed], 0
                mov     word [scroll_slot_count], 0  ; klar for a registrere lange linjer pa neste side
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


; ----------------------------------------------------------------------------
; print_help  -  Skriver hjelpeskjermen for /? og /H.
; ----------------------------------------------------------------------------
print_help:
                push    si

                mov     si, help_brand_msg
                call    print_string_asciz
                call    print_crlf
                mov     si, help_copyright_msg
                call    print_string_asciz
                call    print_crlf
                call    print_crlf

                mov     si, help_summary_msg
                call    print_string_asciz
                call    print_crlf
                mov     si, help_color_msg
                call    print_string_asciz
                call    print_crlf
                call    print_crlf

                mov     si, help_desc_msg
                call    print_string_asciz
                call    print_crlf
                mov     si, help_example_msg
                call    print_string_asciz
                call    print_crlf
                call    print_crlf

                mov     si, help_colordir_msg
                call    print_string_asciz
                call    print_crlf
                mov     si, help_colordir_example_msg
                call    print_string_asciz
                call    print_crlf
                call    print_crlf
                mov     si, help_standalone_msg
                call    print_string_asciz
                call    print_crlf
                call    print_crlf
                mov     si, help_paging_msg
                call    print_string_asciz
                call    print_crlf
                mov     si, help_scroll_msg
                call    print_string_asciz
                call    print_crlf
                mov     si, help_pause_msg
                call    print_string_asciz
                call    print_crlf
                call    print_crlf

                mov     si, help_usage_msg
                call    print_string_asciz
                call    print_crlf
                mov     si, help_switches_msg
                call    print_string_asciz
                call    print_crlf

                pop     si
                ret


; ============================================================================
; RUNTID-BUFFERE (finnes IKKE i selve .COM-filen pa disk)
; ============================================================================
; En .COM-fil far ALL ledig hukommelse i sitt eget segment av DOS ved
; oppstart - adresser bortenfor filens faktiske innhold er derfor gyldig,
; brukbart RAM helt gratis. NASM skriver alltid ekte nullbyte til disk for
; RESB, uansett hvor i filen de star (det finnes intet BSS-konsept for rene
; .COM-filer) - de store bufferne under stod tidligere for over 23 KB av
; .COM-filens storrelse pa disk uten a bidra med noe faktisk innhold.
; Ved a definere dem med EQU (ren adresseberegning, "$" = "her") i stedet
; for RESB, forsvinner de nullbytene fra selve filen - programmets faktiske
; minnebruk og virkemate er 100 % uendret. Alle feltene under blir alltid
; fylt av programmet selv (eller av DOS) FOR de noen gang leses, sa det
; spiller ingen rolle at de ikke lenger er forhandsnullstilt fra disk.
; ============================================================================
runtime_buffers equ     $

search_pattern  equ     runtime_buffers                      ; sok-/stimonster fra kommandolinjen
desc_path       equ     search_pattern + 128                 ; full sti til DESCRIPT.ION
our_dta         equ     desc_path + 128                      ; DTA for Find First/Next (fillisten)
entries         equ     our_dta + 43                         ; tabell over alle funne filer/kataloger
swap_buf        equ     entries + (MAX_ENTRIES * ENTRY_SIZE) ; midlertidig ved sortering
tok_buf         equ     swap_buf + ENTRY_SIZE                ; ett "ord" fra kommandolinjen
vol_dta         equ     tok_buf + TOK_BUF_LEN                ; egen DTA for volumetikett-soket
truename_input  equ     vol_dta + 43                         ; katalogdel som sendes til Truename
truename_buf    equ     truename_input + 128                 ; kanonisert katalogdel fra Truename
vol_pattern     equ     truename_buf + 128                   ; "X:\*.*" for volumetikett-soket
colordir_buf    equ     vol_pattern + 8                      ; ravaerdien av miljovariabelen COLORDIR
ext_color_table equ     colordir_buf + COLORDIR_BUF_LEN      ; {ext[4], farge}-tabell fra ColorDir
tiny_tok        equ     ext_color_table + (MAX_EXT_RULES * EXT_RULE_SIZE) ; fargespek-token
tiny_tok2       equ     tiny_tok + 8                         ; navnetoken (ekstensjon/DIRS)
ext_tok         equ     tiny_tok2 + 8                        ; ekstensjonen til fila vi fargelegger na
render_buf      equ     ext_tok + EXT_NAME_LEN               ; hele skjermlinja bygges her forst
size_digit_buf  equ     render_buf + RENDER_BUF_LEN          ; "NNNN KB"-strengen bygges bakfra her
scroll_slots    equ     size_digit_buf + SIZE_DIGIT_BUF_LEN  ; registrerte /P-rulle-linjer for gjeldende side
descript_data   equ     scroll_slots + (MAX_SCROLL_SLOTS * SCROLL_SLOT_SIZE) ; hele DESCRIPT.ION i minnet
