;this module was originally from Patch of Avalanche's PCXTOOLS package
;this version has been modified to work in normal unchained mode 13h

TransparentText = 1     ;set to 0 to draw backgrounds of letters
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
; void far Draw_String(byte far *fontdata, byte far *string,
;                  word xcoord, word ycoord, byte far *videoseg);
;
PROC            _Draw_String far
                push bp
                mov bp,sp
                push si ds es fs gs

                lds si,[dword bp + 6]       ; DS:SI -> fontdata
                add si,3                    ; point to offset table

                les di,[dword bp + 18]
                add di,[bp + 14]            ; X coord
                mov dx,[bp + 16]            ; Y coord
                shl dx,4                    ; *16
                mov bx,dx                   ; save
                shl dx,2                    ; *64
                add dx,bx                   ; *64 + *16 = *80
                shl dx,2                    ; *80 *4 = *320
                add di,dx                   ; ES:DI -> video offset to start

                lfs bp,[dword bp + 10]      ; FS:BP -> string

@@setupletter:  xor bh,bh
                mov bl,[byte fs:bp]                 ; load letter from message
                shl bx,1                            ; *2 = word sized

                mov cx,[word si + bx]
                mov gs,si                           ; save font pointer
                sub si,3                            ; back to start
                add si,cx                           ; point to proper spot in font file

                mov dh,[byte si + 1]                ; get X size
                mov dl,[byte si + 2]                ; get Y size
                or dx,dx
                jz @@nextcharacter
                add si,03h                          ; point to start of data

@@drawcol:      mov bx,di                           ; save video pointer
                mov cl,dl                           ; CL = height in pixels
@@PixelLoop:    lodsb
                if TransparentText eq 1
                    or al,al
                    jz @@NextPixel
                endif
                shl al,5            ;*** this was moved out of the rotating
                                    ;*** procedure so that the text buffer
                                    ;*** is all ready to be made transparent
                mov [byte es:di],al
@@NextPixel:    add di,320
                dec cl
                jnz @@PixelLoop
                mov di,bx                           ; restore video pointer
                inc di                              ; go to next column
                dec dh                              ;\ loop until all rows
                jnz @@drawcol                       ;/ are done

@@nextcharacter:mov si,gs
                inc bp                              ; next letter in message
                cmp [byte fs:bp],00h
                jne @@setupletter

                pop gs fs es ds si
                pop bp
                ret
ENDP            _Draw_String
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같�
