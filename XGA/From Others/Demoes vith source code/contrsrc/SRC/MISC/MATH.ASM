;************************************************
;* Math Unit: (C) Type One 1994 / TFL-TDV Prod. *
;************************************************

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

_DATA SEGMENT
             PUBLIC _Expo
             PUBLIC _ExpoEnd

_Expo LABEL WORD
      INCLUDE expo.inc
_ExpoEnd LABEL WORD

_DATA ENDS

_BSS SEGMENT
             PUBLIC _SinusTbl

EVEN
_SinusTbl WORD 1024 DUP(?)  ; zone pour la table sinus (*256) ...
ALIGN 4
EVEN

_BSS ENDS

_TEXT SEGMENT
             PUBLIC _DoSinusTbl
             PUBLIC _Amorce
             PUBLIC _GetRandom

;#############################################################
;MakeSinTable creates a 0-1023 integer sine table
;(c) 1993 by Mikko Reinikainen
;#############################################################

ALIGN
EVEN
_DoSinusTbl PROC FAR

    push bp
    mov bp,sp
    pusha
    push es      ; REM: assume DS=_DATA

    push ds
    pop es
    mov di,OFFSET _SinusTbl
    mov si,OFFSET _SinusTbl+2*256
    push di
    push si
    mov cx,129 
    sub ax,ax
@@:
    mov [si],ax  ; calculate 
    sub si,2     ; (incremental algorithm like bresenham circle)
    stosw
    mov dx,cx
    shl dx,1
    add ax,dx
    loop @B

    pop di
    pop si
    mov cx,256
@@:
    lodsw
    neg ax
    stosw
    loop @B
   
    mov si,OFFSET _SinusTbl
    mov di,OFFSET _SinusTbl+512*2
    mov cx,512
@@:
    lodsw
    sar ax,6 ; *16384/64 = *256
    mov [si-2],ax
    stosw
    loop @B
 
    pop es
    popa
    leave   ; mov sp,bp + pop bp

    retf

_DoSinusTbl ENDP


;***************************
;* Random number generator *
;***************************
ALIGN
EVEN
_GetRandom PROC FAR

; Posted by Jare/IGUANA
    
     mov    ax,WORD PTR cs:[Suivant]  
     add    ax,9248h
     ror    ax,3
     mov    WORD PTR cs:[Suivant],ax
     and    ax,7fffh

     retf

Suivant WORD ?                   ; zone pour nombre aleatoire

_GetRandom ENDP

ALIGN
EVEN
;*************************
;* Init Random Generator *
;*************************
_Amorce PROC FAR
        
    push   bp
    mov    bp,sp
    push   ax                    ; REM: assume DS=_DATA

    xor    al,al
    out    43h,al                ; get timer 0 value
    in     al,40h
    mov    ah,al
    in     al,40h
    mov    WORD PTR cs:[Suivant],ax  ; use it as init value

    pop    ax
    leave         ; mov sp,bp + pop bp

    retf

_Amorce ENDP

_TEXT ENDS

     END
