TransparentText = 1     ;set to 0 to draw backgrounds of letters
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
; void far Draw_String(byte far *fontdata, byte far *string,
;                  word xcoord, word ycoord, word pageoffs);
;
PROC            _Draw_String far
                push bp
                mov bp,sp
                push ds

                mov ax,0A000h
                mov es,ax

                lds si,[dword bp + 6]               ; DS:SI -> fontdata
                add si,3                            ; point to offset table
                mov dx,[bp + 14]                    ; X coord

                mov di,[bp + 16]                    ; Y coord
                shl di,4                            ; *16
                mov bx,di                           ; save
                shl di,2                            ; *64
                add di,bx                           ; *64 + *16 = *80
                shl di,2

                mov cl,dl                   ; get plane bits from X pos
                and cl,00000011b            ; keep in 0-3 range
                mov ah,00010001b            ; start at plane 0
                rol ah,cl                   ; shift to proper plane

                shr dx,2                    ; divide X coord by 4
                add di,dx                   ; video offset to start at
                add di,[bp + 18]            ; final video offset

                lfs bx,[dword bp + 10]      ; FS:BP -> string
                mov bp,bx
                mov al,02h                          ; 02h = map mask index

@@setupletter:  xor bh,bh
                mov bl,[byte fs:bp]                 ; load letter from message
                shl bx,1                            ; *2 = word sized

                mov cx,[word si + bx]
                mov gs,si                           ; save font pointer
                sub si,3                            ; back to start
                add si,cx                           ; point to proper spot in font file

                mov ch,[byte si + 1]                ; get X size
                mov cl,[byte si + 2]                ; get Y size
                jcxz @@nextcharacter
                add si,03h                          ; point to start of data

@@newplane:     mov dx,03c4h                        ; sequencer reg
                out dx,ax
                mov dl,cl                           ; loop Y count

                mov bx,di                           ; save video pointer
@@drawcolumn:   mov dh,[byte si]                    ; draw a column
                if TransparentText ne 0
                    or dh,dh
                    jz @@dontplot
                endif
                mov [es:di],dh
@@dontplot:     inc si                              ; next byte in column
                add di,80*4                         ; next video line
                dec dl                              ; decrement height
                jnz @@drawcolumn
                mov di,bx                           ; restore video pointer

                rol ah,1
                adc di,0
                dec ch
                jnz @@newplane

@@nextcharacter:mov si,gs
                inc bp                              ; next letter in message
                cmp [byte fs:bp],00h
                jne @@setupletter

                pop ds
                pop bp
                ret
ENDP            _Draw_String
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
