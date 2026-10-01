;fade_out

PALETTE_NUMBER = 256       ;normally 256
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
macro       Decrease source
            local @@Done
            cmp source,0
            jz @@Done
            dec source
@@Done:     exitm
endm        Decrease
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
macro       WaitForRetrace
            local @@WaitHi, @@WaitLo
            mov dx,3DAh
@@WaitHi:   in al,dx
            test al,8
            jnz @@WaitHi
@@WaitLo:   in al,dx
            test al,8
            jz @@WaitLo
endm        WaitForRetrace
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
PROC        fade_out
            mov cx,64
@@NextLoop: push cx
            WaitForRetrace                ;wait for a vertical retrace
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
            pop cx
            dec cx                        ;\ loop until all cycles are done
            jnz @@NextLoop                ;/
            ret                           ;return
ENDP        fade_out
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° 
