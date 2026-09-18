; Test fixture only - simulates an old game with no quit option.
; Reads a key via INT 16h and prints it, forever. Never exits on its own.
                org     100h
start:
                mov     ah, 0
                int     16h
                mov     dl, al
                mov     ah, 2
                int     21h
                jmp     start
