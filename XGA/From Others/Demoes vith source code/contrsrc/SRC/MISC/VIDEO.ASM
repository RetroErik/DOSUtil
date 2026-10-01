;*********************
;* FLamoot VGA SetUp *
;*********************
;(C) Type One 1994 - TFL/TDV Prod.
; email: llardin@is2.vub.ac.Be

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
DGROUP GROUP _DATA,_BSS
_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
       ASSUME CS:_TEXT,DS:DGROUP
_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------


_DATA  SEGMENT

;*** GFX-mode structure *** 
mode RECORD hgh:5, ver:3, hor:3, col:2, adr:2
;
; rem:   hgh = line doubling factor
;        ver = 0 --> 350 lines display     hor = 0 --> 128 horiz width
;              1     400 big                     1     160 (7-mode)
;              2     400                         2     180 (7-mode like)
;              3     400 60hz                    3     256
;              4     448                         4     320
;              5     480                         5     360
;              6     512                         
;              7     540
;        col = 0 --> 256 colors display    adr = 0 --> planar scheme (X-mode)
;              1     16                          1 --> chained
;              2     4                           2 --> cga
;              3     text 16                     3 --> mono
;
; PS: if you choose a 16 colors display, the horiz width is doubled !!!!!

;****** VGA vertical timings ******

;--- settings for 350 lines ---
vert350 LABEL BYTE
 DB 0a0h   ; vertical clock (3c2h)
 DW 0bf06h ; vertical total
 DW 01f07h ; overflow reg.
 DW 08310h ; vertical retrace start
 DW 08511h ; vertical retrace end
 DW 05d12h ; vert. disp. enable end
 DW 06315h ; vertical blank start
 DW 0ba16h ; vertical blank end

;--- settings for 400 lines / full scan ---
vert400b LABEL BYTE
 DB 0a0h   ; vertical clock (3c2h)
 DW 0bf06h ; vertical total
 DW 01f07h ; overflow reg.
 DW 09c10h ; vertical retrace start
 DW 08e11h ; vertical retrace end
 DW 08f12h ; vert. disp. enable end
 DW 09615h ; vertical blank start
 DW 0b916h ; vertical blank end

;--- settings for 400 lines ---
vert400 LABEL BYTE
 DB 060h   ; vertical clock (3c2h)
 DW 0bf06h ; vertical total
 DW 01f07h ; overflow reg.
 DW 09c10h ; vertical retrace start
 DW 08e11h ; vertical retrace end
 DW 08f12h ; vert. disp. enable end
 DW 09615h ; vertical blank start
 DW 0b916h ; vertical blank end

;--- settings for 400 lines / 60hz ---
vert400h LABEL BYTE
 DB 0e0h   ; vertical clock (3c2h)
 DW 0bf06h ; vertical total
 DW 01f07h ; overflow reg.
 DW 09c10h ; vertical retrace start
 DW 08e11h ; vertical retrace end
 DW 08f12h ; vert. disp. enable end
 DW 09615h ; vertical blank start
 DW 0b916h ; vertical blank end

;--- settings for 448 lines ---
vert448 LABEL BYTE
 DB 0e0h   ; vertical clock (3c2h)
 DW 00b06h ; vertical total
 DW 03e07h ; overflow reg.
 DW 0da10h ; vertical retrace start
 DW 09c11h ; vertical retrace end
 DW 0bf12h ; vert. disp. enable end
 DW 0c715h ; vertical blank start
 DW 00416h ; vertical blank end

;--- settings for 480 lines ---
vert480 LABEL BYTE
 DB 0e0h   ; vertical clock (3c2h)
 DW 00b06h ; vertical total
 DW 03e07h ; overflow reg.
 DW 0ea10h ; vertical retrace start
 DW 08c11h ; vertical retrace end
 DW 0df12h ; vert. disp. enable end
 DW 0e715h ; vertical blank start
 DW 00416h ; vertical blank end

;--- settings for 512 lines ---
vert512 LABEL BYTE
 DB 0e0h   ; vertical clock (3c2h)
 DW 02306h ; vertical total
 DW 0b207h ; overflow reg.
 DW 00a10h ; vertical retrace start
 DW 0ac11h ; vertical retrace end
 DW 0ff12h ; vert. disp. enable end
 DW 00715h ; vertical blank start
 DW 01a16h ; vertical blank end

;--- settings for 540 lines ---
vert540 LABEL BYTE
 DB 0e0h   ; vertical clock (3c2h)
 DW 03006h ; vertical total
 DW 0f007h ; overflow reg.
 DW 02010h ; vertical retrace start
 DW 0a911h ; vertical retrace end
 DW 01b12h ; vert. disp. enable end
 DW 01f15h ; vertical blank start
 DW 02f16h ; vertical blank end

;****** VGA horizontal timings ******

;--- settings for 128 pixels ---
horiz128 LABEL BYTE
 DB 03h    ; horizontal clock
 DW 02d00h ; horiz. total
 DW 01f01h ; horiz. disp. enable end
 DW 02002h ; horiz. blank start
 DW 09003h ; horiz. blank end
 DW 02504h ; horiz. retrace start
 DW 08d05h ; horiz. retrace end
 DW 01013h ; offset/logical width
 DW 00801h ; clock mode register (3c4h) (00901h)

;--- settings for 160 pixels ---
horiz160 LABEL BYTE
 DB 03h    ; horizontal clock
 DW 02d00h ; horiz. total
 DW 02701h ; horiz. disp. enable end
 DW 02802h ; horiz. blank start
 DW 09003h ; horiz. blank end
 DW 02b04h ; horiz. retrace start
 DW 08005h ; horiz. retrace start
 DW 01413h ; offset/logical width
 DW 00801h ; clock mode register (3c4h) (00901h)

;--- settings for 180 pixels ---
horiz180 LABEL BYTE
 DB 07h    ; horiz. clock (3c2h)
 DW 03200h ; horiz. total
 DW 02c01h ; horiz. disp. enable end
 DW 02d02h ; horiz. blank start
 DW 0b003h ; horiz. blank end
 DW 02f04h ; horiz. retrace start
 DW 0b405h ; horiz. retrace end
 DW 01713h ; offset/logical width
 DW 00801h ; clock mode register (3c4h) (00901h) 

;--- settings for 256 pixels ---
horiz256 LABEL BYTE
 DB 03h    ; horizontal clock
 DW 05f00h ; horiz. total
 DW 03f01h ; horiz. disp. enable end
 DW 04002h ; horiz. blank start
 DW 08203h ; horiz. blank end
 DW 04a04h ; horiz. retrace start
 DW 09a05h ; horiz. retrace end
 DW 02013h ; offset/logical width
 DW 00001h ; clock register (3c4h) (00101h)

;--- settings for 320 pixels ---
horiz320 LABEL BYTE
 DB 03h    ; horizontal clock
 DW 05f00h ; horiz. total
 DW 04f01h ; horiz. disp. enable end
 DW 05002h ; horiz. blank start
 DW 08203h ; horiz. blank end
 DW 05404h ; horiz. retrace start
 DW 08005h ; horiz. retrace end
 DW 02813h ; offset/logical width
 DW 00001h ; clock register (3c4h) (00101h)

;--- settings for 360 pixels ---
horiz360 LABEL BYTE
 DB 07h    ; horizontal clock
 DW 06b00h ; horiz. total
 DW 05901h ; horiz. disp. enable end
 DW 05a02h ; horiz. blank start
 DW 08e03h ; horiz. blank end
 DW 05e04h ; horiz. retrace start
 DW 08a05h ; horiz. retrace end
 DW 02d13h ; offset/logical width
 DW 00001h ; clock register (3c4h) (00101h)

;***** Settings for colors *****
EVEN
col256 LABEL BYTE
 DW 04005h    ; mode register (3ceh)
 DB 030h,061h ; mode control  (3c0h) 

col16 LABEL BYTE
 DW 00005h    ; mode register (3ceh)
 DB 030h,021h ; mode control  (3c0h)

col4 LABEL BYTE
 DW 03005h    ; mode register (3ceh)
 DB 030h,021h ; mode control  (3c0h)

text16 LABEL BYTE
 DW 01005h    ; mode register (3ceh)
 DB 030h,02ch ; mode control  (3c0h)

;***** Adressing mode *****
EVEN
planar LABEL WORD
 DW 00604h    ; unchain (3c4h)
 DW 00014h    ; turn off dword mode
 DW 0e317h    ; turn on byte mode

chained LABEL WORD
 DW 00e04h    ; chain   (3c4h)
 DW 04014h    ; turn on dword mode
 DW 0a317h    ; turn off byte mode

cga LABEL WORD
 DW 00204h    ;         (3c4h)
 DW 00014h
 DW 0a217h

herc LABEL WORD
 DW 00604h    ;         (3c4h)  
 DW 00014h
 DW 0c217h

;*** Tables ***
Vertab LABEL WORD
 DW OFFSET vert350, OFFSET vert400b, OFFSET vert400, OFFSET vert400h
 DW OFFSET vert448, OFFSET vert480, OFFSET vert512, OFFSET vert540
Hortab LABEL WORD
 DW OFFSET horiz128, OFFSET horiz160, OFFSET horiz180, OFFSET horiz256
 DW OFFSET horiz320, OFFSET horiz360
Coltab LABEL WORD
 DW OFFSET col256, OFFSET col16, OFFSET col4, OFFSET text16
Adrtab LABEL WORD
 DW OFFSET planar, OFFSET chained, OFFSET cga, OFFSET herc

PUBLIC _BlackPal
PUBLIC _WhitePal

_BlackPal DB 768 DUP(0)
_WhitePal DB 768 DUP(63)

_DATA  ENDS

_BSS SEGMENT
PUBLIC _TmpPal

_TmpPal DB 768 DUP(?)   ; palette buffer !!!!

_BSS ENDS

;-----------------------------------------
_TEXT SEGMENT
             PUBLIC _WaitVBL
             PUBLIC _WaitHBL
             PUBLIC _SetVGA
             PUBLIC _AveragePAL
;             PUBLIC _FadeIn
;             PUBLIC _FadeOut
;             PUBLIC _InFade
;             PUBLIC _OutFade

VSYNC MACRO          ; Om de VBL te wachten...
      call _WaitVbl
      ENDM

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


;*************************
;* Set Up VGA video mode *
;*************************

ALIGN
EVEN
_SetVGA PROC FAR

        push bp
        mov  bp,sp

        MPUSH eax,bx,cx,dx,si,di,ds,es
        mov   ax,DGROUP
        mov   ds,ax

;        mov  ax,13h                 ; let the BIOS start with
;        int  10h                    ; mode 13 : 320x200x256 chained 
        VSYNC 

        mov  ax,WORD PTR ss:[bp+6]  ; take WORD param
        cld

     ; Addressing mode
        mov  bx,ax
        push ax
        and  bx,MASK adr            ; get adressing mode
        shl  bx,1
        mov  si,WORD PTR[Adrtab+bx] ; corresponding table
        mov  dx,3c4h
        lodsw           ; (1)         
        mov  bl,ah                  ; chain/unchain (only 4 bits used)
        out  dx,al
        inc  dl
        in   al,dx
        and  al,0f0h   
        and  bl,00fh
        or   al,bl
        out  dx,al
        dec  dl
        mov  dl,0d4h
        lodsw           ; (2)    
        mov  bl,ah                  ; dword mode on/off
        out  dx,al
        inc  dl
        in   al,dx
        and  al,080h
        and  bl,060h    ; bits 5,6
        or   al,bl
        out  dx,al
        dec  dl
        outsw           ; (3)         byte mode on/off
        pop  ax

     ; Color mode
        mov  bx,ax
        push ax
        and  bx,MASK col            ; get color mode
        shr  bx,col-1            
        mov  si,WORD PTR[Coltab+bx] ; corresponding table       
        mov  dl,0ceh
        lodsw           ; (1)         display plane output
        mov  bl,ah
        out  dx,al
        inc  dl
        in   al,dx
        and  al,08fh    ; bits 4,5,6   
        or   al,bl
        out  dx,al
        dec  dl
        mov  dl,0c0h
        outsb           ; (2)         pixel panning compatibility + PCS
        lodsb
        mov  bl,al    
        inc  dl      
        in   al,dx
        dec  dl
        and  al,090h    ; bits 6,5,3,2,1,0
        or   al,bl
        out  dx,al
        pop  ax   

      ; Modify CRTC registers
        push ax 
        mov  dl,0d4h
        mov  al,11h                 ; cr11
        out  dx,al                  ; current value
        inc  dl                     ; point to data
        in   al,dx                  ; get cr11 value
        and  al,07fh                ; remove cr0-cr7
        out  dx,al                  ; write protect
        pop  ax 

      ; Horizontal parameters
        mov  bx,ax
        push ax
        and  bx,MASK hor            ; get horizontal parameters
        shr  bx,hor-1
        mov  si,WORD PTR[Hortab+bx] ; corresponding table
        mov  bl,BYTE PTR[si]        ; get horizontal clock
        inc  si
        mov  dl,0d4h
        mov  cx,7
        rep  outsw
        mov  dl,0c4h
        lodsw                       ; just OR the right bits
        mov  bh,ah                  ; (clock doubling)
        out  dx,al
        inc  dl
        in   al,dx
        and  al,037h
        or   al,bh
        out  dx,al
        pop  ax

      ; Vertical parameters
        push ax
        mov  cl,bl
        mov  bx,ax
        and  bx,MASK ver            ; get vertical parameters
        shr  bx,ver-1
        mov  si,WORD PTR[Vertab+bx] ; corresponding table
        or   cl,BYTE PTR[si]        ; get vertical clock
        inc  si         
        mov  dl,0c4h                ; alter sequencer register
        mov  ax,0100h               ; synchronous reset
        out  dx,ax
        mov  dl,0cch
        in   al,dx                  ; read clock
        and  al,033h
        or   al,cl
        mov  dl,0c2h
        out  dx,al                  ; new clock
        mov  dl,0c4h                ; sequencer again
        mov  ax,0300h               ; restart sequencer
        out  dx,ax                  ; running again
        mov  dl,0d4h
        outsw
        outsw
        outsw
        lodsw      ; (1) VR End : bits 7,6,3,2,1,0
        mov  cl,ah
        out  dx,al
        inc  dl
        in   al,dx
        and  al,030h
        and  cl,0cfh
        or   al,cl
        out  dx,al
        dec  dl  
        outsw
        outsw
        lodsw      ; (3) End VBlank : bits 6,5,4,3,2,1,0
        mov  cl,ah
        out  dx,al
        inc  dl
        in   al,dx
        and  al,07fh
        or   al,cl
        out  dx,al
        pop  ax
         
      ; Line doubling
        and  ax,MASK hgh
        shr  ax,hgh                 ; cell height
        mov  cl,al
        mov  dl,0d4h
        mov  al,009h
        out  dx,al
        inc  dl
        in   al,dx
        and  al,0e0h
        or   al,cl
        out  dx,al

        mov  dl,0c4h                ; Clear Vidmem
        mov  ax,0f02h
        out  dx,ax
        mov  cx,16384
        mov  ax,0a000h
        mov  es,ax
        xor  di,di
        xor  eax,eax
        rep  stosd
         

        MPOP eax,bx,cx,dx,si,di,ds,es 

        leave
        retf

_SetVGA ENDP

;*************************
;* Wait Vertical Retrace *
;*************************
ALIGN
EVEN
_WaitVBL PROC FAR

         MPUSH ax,dx

         mov  dx,3dah  ; Status Register
EVEN
@@:      in   al,dx
         test al,08    ; bit 3
         jnz  @B
EVEN
@@:      in   al,dx
         test al,08
         jz   @B

         MPOP ax,dx

         retf

_WaitVBL ENDP

;***************************
;* Wait Horizontal Retrace *
;***************************
ALIGN
EVEN
_WaitHBL PROC FAR

         MPUSH ax,dx

         mov  dx,3dah  ; Status Register
EVEN
@@:      in   al,dx
         test al,01    ; bit 0
         jnz  @B
EVEN
@@:      in   al,dx
         test al,01
         jz   @B

         MPOP ax,dx

         retf

_WaitHBL ENDP

ALIGN
EVEN

_AveragePAL PROC FAR    ; Average 2 palets 
         
; ss:[BP+6] = OFFSET Pal1
; ss:[BP+8] = SEG Pal1
; ss:[BP+10] = OFFSET Pal2
; ss:[BP+12] = SEG Pal2
; ss:[BP+14] = OFFSET Dest
; ss:[BP+16] = SEG Dest
; ss:[BP+18] = factor

         push bp
         mov  bp,sp
         
         pusha
         MPUSH ds,es,fs

         mov  ax,ss:[BP+8]
         mov  ds,ax
         mov  ax,ss:[BP+16]
         mov  es,ax
         mov  ax,ss:[BP+12]
         mov  fs,ax

         mov  si,ss:[BP+6]
         mov  di,ss:[BP+14]
         mov  bx,ss:[BP+10]   
         
         mov  dl,255
         sub  dl,BYTE PTR ss:[BP+18]

         mov   cl,BYTE PTR ss:[BP+18]
         mov   ch,cl
         not   ch

         INDICE = 0

         REPT 768                    

         lodsb                        ; (a*col1+(256-a)*col2)/256
         mul  cl                      ; a
         mov  dx,ax
         mov  al,BYTE PTR fs:[bx+INDICE]
         mul  ch                      ; 255 -a
         add  ax,dx
         mov  al,ah
         stosb  

         INDICE = INDICE + 1

         ENDM

         MPOP ds,es,fs 
         popa        

         leave
         retf

_AveragePAL ENDP


COMMENT^

ALIGN
EVEN
_FadeIn PROC FAR                     ; Black to Pal

; ss:[BP+6] = OFFSET Pal
; ss:[BP+8] = SEG Pal
; ss:[BP+10] = OFFSET Dest           ; supposed to be clear at the beginning !!
; ss:[BP+12] = SEG Dest


        push bp
        mov  bp,sp

        MPUSH cx,si,di,ds,es         ; don't save AX --> result

        mov   ax,ss:[BP+8]
        mov   ds,ax
        mov   ax,ss:[BP+12]
        mov   es,ax

        mov   si,ss:[BP+6]
        mov   di,ss:[BP+10]
        mov   ah,1                   ; true by default

        mov   cx,768
@@:     lodsb
        cmp   al,BYTE PTR es:[di]    ; have we reach the col ???
        jbe   huhu
        inc   BYTE PTR es:[di]
        xor   ah,ah                  ; false !!!
huhu:   inc   di
        dec   cx
        jnz   @B
        xor   al,al

        MPOP  cx,si,di,ds,es

        leave
        retf

_FadeIn ENDP

ALIGN
EVEN
_FadeOut PROC FAR                     ; Pal to Black

; ss:[BP+6] = OFFSET Pal
; ss:[BP+8] = SEG Pal

        push bp
        mov  bp,sp

        MPUSH cx,si,ds               ; AX = result !!!

        mov   ax,ss:[BP+8]
        mov   ds,ax

        mov   si,ss:[BP+6]
        mov   ax,1                   ; true by default

        mov   cx,768
@@:     cmp   BYTE PTR ds:[si],0     ; black ?????
        jne   hahu
        dec   BYTE PTR ds:[si]
        xor   al,al                  ; false !!!
hahu:   inc   si
        dec   cx
        jnz   @B

        MPOP  cx,si,ds

        leave
        retf

_FadeOut ENDP

ALIGN
EVEN
_InFade PROC FAR                     ; White to Pal

; ss:[BP+6] = OFFSET Pal
; ss:[BP+8] = SEG Pal
; ss:[BP+10] = OFFSET Dest           ; supposed to be white at the beginning !!
; ss:[BP+12] = SEG Dest


        push bp
        mov  bp,sp

        MPUSH cx,si,di,ds,es         ; AX = result

        mov   ax,ss:[BP+8]
        mov   ds,ax
        mov   ax,ss:[BP+12]
        mov   es,ax

        mov   si,ss:[BP+6]
        mov   di,ss:[BP+10]
        mov   ah,1                   ; true by default

        mov   cx,768
@@:     lodsb
        cmp   al,BYTE PTR es:[di]    ; have we reach the col ???
        jbe   huha
        dec   BYTE PTR es:[di]
        xor   ah,ah                  ; false !!!
huha:   inc   di
        dec   cx
        jnz   @B
        xor   al,al

        MPOP  cx,si,di,ds,es

        leave
        retf

_InFade ENDP

ALIGN
EVEN
_OutFade PROC FAR                     ; Pal to White

; ss:[BP+6] = OFFSET Pal
; ss:[BP+8] = SEG Pal

        push bp
        mov  bp,sp

        MPUSH cx,si,ds                ; AX = result

        mov   ax,ss:[BP+8]
        mov   ds,ax

        mov   si,ss:[BP+6]
        mov   ax,1                    ; true by default

        mov   cx,768
@@:     cmp   BYTE PTR ds:[si],63     ; white ?????
        jne   hahu
        inc   BYTE PTR ds:[si]
        xor   al,al                   ; false !!!
hahu:   inc   si
        dec   cx
        jnz   @B

        MPOP  cx,si,ds

        leave
        retf

_OutFade ENDP

^

_TEXT ENDS

      END
