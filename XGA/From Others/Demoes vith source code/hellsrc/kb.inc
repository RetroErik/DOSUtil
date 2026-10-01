; Special KB codez:           KB bits:
;  1-12 - F1-F12 - 1-0ch       0 - shift
;  13   - Enter  - 0dh         1 - alt
;  14   - Esc    - 0eh         2 - ctrl
;  15   - Tab    - 0fh
;  16   - BS     - 10h
;  17   - Ins    - 11h
;  18   - Del    - 12h
;  19   - Home   - 13h
;  20   - End    - 14h
;  21   - PgUp   - 15h
;  22   - PgDn   - 16h
;  23   - Left   - 17h
;  24   - Right  - 18h
;  25   - Up     - 19h
;  26   - Down   - 1ah

extrn   _kbtbl0:byte, _kbtbl1:byte, _kbchar:byte, _kbshift:byte, _kbhit:byte

extrn   _initkb:near, _resetkb:near, _getch:near, _clearkb:near

