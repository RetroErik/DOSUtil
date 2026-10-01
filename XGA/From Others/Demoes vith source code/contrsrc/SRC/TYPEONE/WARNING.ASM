
;***********************************************************
; Warning - Only ASM !!!! (C) 1994 Type One / TFL-TDV Prod.
;***********************************************************

INCLUDE PDFIK.INC ; DataFile Manager
INCLUDE VIDEO.INC ; Flamoot VGA SetUp

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
DGROUP GROUP _DATA,_BSS
WARN_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
           ASSUME CS:WARN_TEXT,DS:DGROUP
WARN_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------

_DATA SEGMENT  

;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'warning.raw',0
Picparam  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname,0,0,0,,,0>

EXTRN _Expo    : WORD
EXTRN _ExpoEnd : WORD

EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE

_DATA ENDS

; donn‚es non initialis‚es !!!
_BSS SEGMENT

GastonPal DB 768 DUP(?)

EVEN
PicSeg   WORD ?        ; ptr vers segment pattern
FadeFlag WORD ?        ; flag pour fading

EXTRN _TmpPal: BYTE

_BSS ENDS 

WARN_TEXT SEGMENT
     PUBLIC _PutWarning
     PUBLIC _EndWarning
     EXTRN _WaitVBL: FAR 
     EXTRN _AveragePAL : FAR

;---- MACROs ----

VSYNC MACRO          ; Om de VBL te wachten...
      call _WaitVBL
      ENDM

STARTUP MACRO        ; MicroSoft Syntax.....
        mov ax,DGROUP
        mov ds,ax
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


; Point d'entr‚e de l'intro !!!!!
;---------------------------------
ALIGN
EVEN
_PutWarning PROC FAR

         push    bp                  ; bƒtit le cadre de pile
         mov     bp,sp
         
         pushad
         MPUSH ds,es,fs,gs

         STARTUP
         push    m320x200x256p
         call    _SetVGA
         add     sp,2 

         STARTUP
;--------------------------------------
         call    Warning             ; !!!!! put G.Lagaffe !!!!!
;--------------------------------------

         MPOP ds,es,fs,gs
         popad
         nop

         leave                             ; restore stack
                                           ; mov sp,bp + pop bp
         retf                              ; C/C++ retirera le param 

_PutWarning ENDP

ALIGN
EVEN
;-------- Fade G.Lagaffe !!! ---------
_EndWarning PROC FAR

         push    bp                  ; bƒtit le cadre de pile
         mov     bp,sp
         
         pushad
         MPUSH ds,es,fs,gs

         STARTUP

         push    es
         push    ds
         pop     es
         mov     ax,1017h
         xor     bx,bx
         mov     cx,256
         mov     dx,OFFSET GastonPal   ; Get current pal !!!!
         int     10h
         pop     es

         mov     FadeFlag,0

ToWhite: 

         cmp     FadeFlag,255
         jae     @F
         mov     ax,FadeFlag          ; average MyPal-White
         push    ax
         push    ds
         push    OFFSET _TmpPal
         push    ds
         push    OFFSET GastonPal
         push    ds
         push    OFFSET _WhitePal
         call    _AveragePAL
         add     sp,7*2
         mov     dx,3dah
lbl1:    in      al,dx
         test    al,8
         jz      lbl1
         call    DoPal
lbl2:    in      al,dx
         test    al,8
         jnz      lbl2
         add     FadeFlag,8 

         jmp     ToWhite
@@:      mov     FadeFlag,0 

ToBlack: 

         cmp     FadeFlag,255
         jae     @F
         mov     ax,FadeFlag          ; average MyPal-White
         push    ax
         push    ds
         push    OFFSET _TmpPal
         push    ds
         push    OFFSET _WhitePal
         push    ds
         push    OFFSET _BlackPal
         call    _AveragePAL
         add     sp,7*2
         mov     dx,3dah
llbl1:   in      al,dx
         test    al,8
         jz      llbl1
         call    DoPal
llbl2:   in      al,dx
         test    al,8
         jnz     llbl2
         add     FadeFlag,8 

         jmp     ToBlack

@@:
         MPOP ds,es,fs,gs
         popad
         nop

         leave                             ; restore stack
                                           ; mov sp,bp + pop bp
         retf                              ; C/C++ retirera le param 

_EndWarning ENDP

ALIGN
EVEN
DoPal PROC NEAR

    MPUSH ax,cx,dx,si

    mov   dx,3c8h
    xor   al,al      ; begin by color 0
    out   dx,al
    inc   dl            

    mov   si,OFFSET _TmpPal
    mov   cx,768
    rep   outsb

    MPOP  ax,cx,dx,si
    ret

DoPal ENDP

;==============================================================================
;============================ Put Warning part ================================
;==============================================================================

ALIGN
EVEN
Warning PROC NEAR

;------------------------------------------------------------------------------
         pushad

         mov     eax,_OfsinDta         ; OFFSET in Datafile
         mov     Picparam.OfsInPdf,eax
         mov     ax,DGROUP             ; prepare for PDFIK call 
         mov     es,ax 
         mov     bx,OFFSET Picparam  
         pusha 
         call    PDFIK_ASM             ; call function 2 (extract+alloc)
         popa
         mov     ax,Picparam.BufSeg ; where is the file in mem ?  
         mov     Picseg,ax

         push    ds
         push    es
         mov     ax,Picseg
         mov     ds,ax                 ; 32 bytes for Alchemy Header
         mov     si,32                 ; palette offset 
         mov     es,ax
         mov     di,32

         mov     cx,768                ; 256*3 components
@@:      lodsb
         shr     al,2                  ; 8 to 6 bits conversion
         stosb
         dec     cx
         jnz     @B

         mov     ax,1012h              ; Set Palet
         xor     bx,bx
         mov     dx,32
         mov     cx,256
         int     10h

         pop     es
         pop     ds

;---------------

; change Video base 
        mov     dx,3d4h
        mov     bx,320*200/4
        mov     al,0ch
        mov     ah,bh
        out     dx,ax
        mov     al,0dh
        mov     ah,bl
        out     dx,ax
        VSYNC         

; put picture onto screen !!!!!
        push    ds
        push    es
        mov     ax,Picseg
        mov     ds,ax
        mov     si,800                ; skip Alchemy header
        mov     ax,0a000h
        mov     es,ax

        mov     dx,3c4h
        mov     al,02h                ; bitplane sel. reg.
        out     dx,al
        inc     dl  

        i=0
        REPT    4
        xor     di,di
        mov     al,(1 SHL i)
        out     dx,al
        mov     cx,320*200/4
@@:     lodsb
        add     si,3
        stosb
        dec     cx
        jnz     @B
        sub     si,320*200-1
        i=i+1
        ENDM

        pop     es
        pop     ds
                  
        mov     si,OFFSET _Expo       ; exponential !!!
@@:     VSYNC
        lodsw
        sub     ax,400
        neg     ax
        sar     ax,1
        mov     bx,80
        mul     bx
        mov     bx,ax
        mov     dx,3d4h               ; new position
        mov     al,0ch
        mov     ah,bh
        out     dx,ax
        mov     al,0dh
        mov     ah,bl
        out     dx,ax

        cmp     si,OFFSET _ExpoEnd
        jne     @B


;----- EXIT -----

        mov     ax,Picseg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

        popad
        nop
        ret

Warning ENDP

;==============================================================================

WARN_TEXT ENDS

     END



