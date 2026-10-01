EXTRN _ExitDemo : WORD
EXTRN _CPUtime  : WORD
EXTRN _SpaceBar : WORD
EXTRN _WaitVBL: FAR


;---- MACROs ----

;=========================================================

VSYNC MACRO          ; Om de VBL te wachten...
      call _WaitVBL
      ENDM

STARTUP MACRO        ; MicroSoft Syntax.....
        mov ax,DGROUP
        mov ds,ax
        ENDM

;=========================================================

LOOP_UNTIL_KEY MACRO label         ; attend <> touches et boucle sur Main
       LOCAL   lbl1,lbl2,GoOut,GoOut2

       in      al,60h              ; EXIT ?
       cmp     al,78               ; '+'
       jne     lbl1
       mov     _CPUtime,1          ; set CPUtime Flag to ON ....
       jmp     label
lbl1:  cmp     al,74               ; '-'
       jne     lbl2
       mov     _CPUtime,0          ; set CPUtime Flag to OFF ....
       jmp     label
lbl2:  cmp     al,39h              ; Space Bar ...
       je      GoOut
       cmp     al,1                ; Escapff...
       jne     label
       mov     _ExitDemo,1         ; exit the whole demo !!!!
       jmp     GoOut2
GoOut: mov     _SpaceBar,1         ; set space bar
GoOut2:       

       ENDM

;============================================================

FLUSH_KEYBUF MACRO
        MPUSH   ax,es

        mov     ax,40h                ; Flush keyboard buffer !!! ;-)
        mov     es,ax
        mov     ax,es:[001ah]
        mov     es:[001ch],ax  

        MPOP    ax,es
        ENDM

;============================================================

COLOR MACRO lum:REQ                 ; to see the CPU time used...
       MPUSH ax,dx
       mov   dx,3c8h
       xor   al,al
       out   dx,al
       inc   dl
       mov   al,lum
       out   dx,al
       out   dx,al
       out   dx,al
       MPOP  ax,dx
      ENDM

SHOWTIME MACRO lum:REQ               ; set CPU time 
      LOCAL lbl1

      test   _CPUtime,1
      jz     lbl1
      COLOR  lum
lbl1:
      ENDM

;=============================================================

MPUSH   MACRO reg1:REQ,reg2:VARARG   ; Vive Y.Roggeman/Greg & ses Macros
        push reg1                    ; recursives !!!!!!! yahouuuuu !!!
        IFNB <reg2>
        MPUSH reg2
        ENDIF
        ENDM

MPOP    MACRO reg1:REQ,reg2:VARARG   ; bis bis !!!
        IFNB <reg2>                  ; type brol = record....
        MPOP reg2                    ; donc ‡a fait 20 bytes !!!
        ENDIF                        ; donc 1 word ....
        pop reg1                     ; brol je dis struct !!!
        ENDM

;=============================================================
