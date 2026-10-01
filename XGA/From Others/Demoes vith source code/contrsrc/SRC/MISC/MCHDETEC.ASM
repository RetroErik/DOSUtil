;**********************************************
; MCH DETECT (C) 1994 Type One / TFL-TDV Prod.
;**********************************************

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

Sorry   BYTE 10,13,'Sorry Dude, You must have VGA card to see dis Demo...',10,13,'$'
Sorry2  BYTE 10,13,'Sorry, You must have a 386+ to run dis Demo properly !!!',10,13,'$'

_DATA ENDS

_TEXT SEGMENT
             PUBLIC _MCH_Detect

EXIT    MACRO        ; ""
        mov ax,4c00h
        int 21h
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

;==============================================================================
ALIGN 
EVEN
_MCH_Detect PROC FAR    ; dispose-t-on d'une machine convenable ???

.8086
         push    bp
         mov     bp,sp
         MPUSH   ax,bx,cx,dx,si,di,ds,es

         mov     WORD PTR cs:[Save_BP+1],bp

;-------- Routine de d‚tection ---------
         xor     bx,bx                ;- VGA Detect -
         mov     ax,01a00h
         int     10h
         cmp     bl,7
         jc      @F
         cmp     bl,00dh
         jc      VGA_Ok
@@:      lea     dx,Sorry             ; Sorry You've not...
         mov     ah,9
         int     21h
         EXIT
VGA_Ok:                               ;- Processor Detect - (C) Bible PC
         xor     ax,ax                ; Fixer AX sur 0
         push    ax                   ; et placer sur la pile
         popf                         ; Retirer de la pile comme reg. de flags
         pushf                        ; Replacer sur la pile
         pop     ax                   ; et ramener dans AX
         and     ax,0f000h            ; Annuler tous les bits sauf les 4 sup.
         cmp     ax,0f000h            ; bits 12 … 15 sont-ils tous … 1 ?
         je      @F                   ; --> Beurk XT : EXIT
         mov     ax,07000h            ; 286 ou 386
         push    ax                   ; Placer la valeur 07000h sur la pile
         popf                         ; Retirer comme registre de flags
         pushf                        ; et replacer sur la pile
         pop     ax                   ; Ramener dans le registre AX
         and     ax,07000h            ; Masquer tous les bits sauf 12 … 14
         jne     pc386_Ok             ; --> Ok 386
@@:      lea     dx,Sorry2            ; d‚sol‚....
         mov     ah,9
         int     21h                  ; rem: d‚tection inhibe les interruptions
         sti
         EXIT

pc386_Ok:
         sti

Save_BP  LABEL WORD
         mov     bp,1234h

         MPOP    ax,bx,cx,dx,si,di,ds,es
         mov     sp,bp
         pop     bp

         retf

_MCH_Detect ENDP


_TEXT ENDS

         END





