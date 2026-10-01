;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
;           DS:SI ==> ASCIIZ extension to add to filename (with period)
;           DS:DI ==> location to place resulting filename
;
proc        CreateFilename
            mov ax,6200h                ;\
            int 21h                     ; \
            mov es,bx                   ;  > ES:BX ==> environment segment
            mov es,[word es:2Ch]        ; /
            xor bx,bx                   ;/
@@FindStart:cmp [word es:bx],0000h      ;\
            jz @@GotStart               ; \
            inc bx                      ;  > ES:BX ==> filename of program
            jmp @@FindStart             ; /
@@GotStart: add bx,4                    ;/
@@CopyName: mov al,[byte es:bx]         ;\
            inc bx                      ; \
            mov [byte ds:di],al         ;  \ copy the full pathname
            inc di                      ;  /
            or al,al                    ; /
            jnz @@CopyName              ;/
@@GoBack:   cmp [byte ds:di],'.'        ;\
            jz @@GotDot                 ; \ search back for the extension
            dec di                      ; /
            jmp @@GoBack                ;/
@@GotDot:   mov al,[byte ds:si]         ;\
            inc si                      ; \
            mov [byte ds:di],al         ;  \ add on the given extension
            inc di                      ;  /
            or al,al                    ; /
            jnz @@GotDot                ;/
            ret                         ;return
endp        CreateFilename
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
