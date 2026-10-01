;fade_out
;fade_to

PALETTE_NUMBER = 256       ;normally 256
;FadeHandler = offset to procedure to call during fading
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
macro       Decrease source
            local @@Done
            cmp source,0
            jz @@Done
            dec source
@@Done:     exitm
endm        Decrease
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;si = offset to palette
;cx = number of colors to write
;al = starting palette register
;
;DESTROYS: dx,si,cx
;
MACRO       SetPalette
            mov     dx,cx
            add     cx,cx
            add     cx,dx
            mov     dx,03c8h
            out     dx,al
            inc     dx
            cld
            rep outsb
ENDM        SetPalette
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;fades out the palette currently loaded to black
PROC        fade_out
            mov cx,64
@@NextLoop: push cx
            mov cx,PALETTE_NUMBER
@@NextColor:      mov dx,3C7h                   ;\
                  mov al,cl                     ; \ send out the color number
                  dec al                        ; /
                  out dx,al                     ;/
                  mov dx,3C9h                   ;DX = DAC_DATA
                  in al,dx                      ;\
                  Decrease al                   ; > BL = red
                  mov bl,al                     ;/
                  in al,dx                      ;\
                  Decrease al                   ; > BH = green
                  mov bh,al                     ;/
                  in al,dx                      ;\
                  Decrease al                   ; > AH = blue
                  mov ah,al                     ;/
                  mov dx,3C8h                   ;\
                  mov al,cl                     ; \ send out the color number
                  dec al                        ; /
                  out dx,al                     ;/
                  mov dx,3C9h                   ;DX = DAC_DATA
                  mov al,bl                     ;\ send out new red
                  out dx,al                     ;/
                  mov al,bh                     ;\ send out new green
                  out dx,al                     ;/
                  mov al,ah                     ;\ send out new blue
                  out dx,al                     ;/

                  dec cx                        ;\ loop until all colors
                  jnz @@NextColor               ;/ are done
call FadeHandler
            pop cx
            dec cx                        ;\ loop until all cycles are done
            jnz @@NextLoop                ;/
            ret                           ;return
ENDP        fade_out
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;fades from palette1 to palette2
;
;           DS:SI ==> palette1 (starting palette) [this is modified]
;           DS:DI ==> palette2 (desired palette)
proc        fade_to
            ;**** converge the current palette to the desired one ****
@@FadeLoop: push si di
            mov cx,PALETTE_NUMBER*3
            xor bx,bx
            cld
@@NextColor:mov al,[byte ds:di]
            cmp [byte ds:si],al
            jz @@ColorDone
            jb @@Increment
@@Decrement:dec [byte ds:si]
            or bx,1             ;set a flag that we're not perfect yet
            jmp @@ColorDone
@@Increment:inc [byte ds:si]
            or bx,1             ;set a flag that we're not perfect yet
@@ColorDone:inc si
            inc di
            dec cx
            jnz @@NextColor
            pop di si
            cmp bx,0            ;if we're perfect, then quit
            jz @@Done

            ;**** load in the new palette ****
            push ds si di
            mov cx,PALETTE_NUMBER
            xor al,al
            SetPalette
call FadeHandler
            pop di si ds
            jmp @@FadeLoop
@@Done:     ret
endp        fade_to
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
