
;*************************************************
; SNAKE PIC (C) 1994 Type One / TFL-TDV Prod.
; GFX by Fred
;*************************************************

INCLUDE PDFIK.INC ; DataFile Manager
INCLUDE VIDEO.INC ; Flamoot VGA SetUp
INCLUDE PLAYINFO.INC ; Player structures
INCLUDE KEYBOARD.INC ; Keyboard macros

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
DGROUP GROUP _DATA,_BSS
SNAKE_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
            ASSUME CS:SNAKE_TEXT,DS:DGROUP
SNAKE_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------

_DATA SEGMENT


;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'snake.raw',0
Picparam  PARAM_STRUC<2,_DATA,OFFSET _Datafile,OFFSET Picname,0,0,0,,,0>


EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE

_DATA ENDS

;donn‚es non initialis‚es
_BSS SEGMENT

EXTRN _FrameCounter     : WORD
EXTRN _StartAdr         : WORD
EXTRN _WorkAdr          : WORD
EXTRN _NextAdr          : WORD
EXTRN _Triple           : WORD
EXTRN _SyncFlag         : WORD
EXTRN _TmpPal           : BYTE
EXTRN _FadeON           : WORD
;!!!!!!!!!! synchro avec music !!!!!!!!!!!!
EXTRN _MP               : DWORD ; extern ModulePlayer * MB
EXTRN _ReplayInfo       : mpInformation

;---- param pour synchro avec zizik ----
EVEN
DebSong  WORD ?
FinSong  WORD ?



EVEN
Picseg    WORD ?        ; seg for pattern

FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?
Termine  WORD ?        ; flag pour terminer !!!


_BSS ENDS

SNAKE_TEXT SEGMENT
     PUBLIC _StartSnake
     EXTRN _AveragePAL : FAR


; Point d'entr‚e de l'intro !!!!!
;---------------------------------
ALIGN
EVEN
_StartSnake PROC FAR

         push    bp                  ; bƒtit le cadre de pile
         mov     bp,sp

         pushad
         MPUSH ds,es,fs,gs

         STARTUP
;------- recuperer parametres sur le stack !!!! --------

         mov     ax,WORD PTR ss:[bp+6]  ; debut pos
         shl     eax,14
         or      ax,WORD PTR ss:[bp+8]  ; debut row
         or      ah,al
         shr     eax,8
         mov     DebSong,ax
         mov     ax,WORD PTR ss:[bp+10] ; fin pos
         shl     eax,14
         or      ax,WORD PTR ss:[bp+12] ; fin row
         or      ah,al
         shr     eax,8
         mov     FinSong,ax
         xor     eax,eax
;-------------------------------------------------------

         push    m320x200x256c   ; set 320x200x256 col/chained 60hz
         call    _SetVGA
         add     sp,2

         STARTUP
;--------------------------------------
         call    DoSnake             ; !!!!! title part !!!!!
;--------------------------------------

         mov  ax,0a000h              ; clear screen
         mov  es,ax
         xor  eax,eax
         xor  di,di
         mov  cx,65536/4
         rep  stosd

         MPOP ds,es,fs,gs
         popad
         nop

         leave                       ; restore stack
                                     ; mov sp,bp + pop bp
         retf

_StartSnake ENDP

;==============================================================================
;============================ Snake part ======================================
;==============================================================================

ALIGN
EVEN
DoSnake PROC NEAR

;------------------------------------------------------------------------------
         pushad

         mov     eax,_OfsinDta         ; OFFSET in Datafile
         mov     Picparam.OfsInPdf,eax
         mov     ax,_DATA              ; prepare for PDFIK call
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

         pop     es
         pop     ds

;---------------

         STARTUP


         call    PutSnake              ; transfert bitmap in vidmem and
                                       ; set pal to black !!!!


;---- wait right position/row in tune ----

WaitPos:
         mov     _ReplayInfo.numChannels,4 ; 4 voices

         les     bx,DWORD PTR[_MP]
         push    ds
         push    OFFSET _ReplayInfo

         ; _MP->GetInformation(&ReplayInfo)

         call    (ModulePlayer PTR es:[bx]).GetInformation
         add     sp,4

         mov     ax,_ReplayInfo.pos
         shl     eax,14
         or      ax,_ReplayInfo.row
         or      ah,al
         shr     eax,8
         cmp     ax,WORD PTR[DebSong]  ; is it time ????
         jb      WaitPos

         xor     eax,eax
;------------------------------------------

         mov     Termine,0 ; pas encore terminer !!!

         mov     _FadeON,0
         mov     FadeFlag,0
         mov     FadePtr1,OFFSET _BlackPal  ; Black to pic for the beginning !!!
         mov     ax,ds
         mov     FadePtr1+2,ax
         mov     FadePtr2,32
         mov     ax,Picseg
         mov     FadePtr2+2,ax
         mov     ax,_FrameCounter
         mov     Delai,ax


         mov     bx,_StartAdr
         mov     WORD PTR[bx],0         ; _StartAdr->base = 0
         mov     WORD PTR[bx+2],0       ; _StartAdr->flag = false
         mov     bx,_WorkAdr
         mov     WORD PTR[bx],0         ; _WorkAdr->base
         mov     WORD PTR[bx+2],0       ; _WorkAdr->flag = false
         mov     _Triple,0              ; "faux" double buffering
         mov     _SyncFlag,1
         VSYNC


EVEN
Main: ; -= VSYNC =-

wait_for_VBL:                       ; wait for Sync Flag
         cmp     _SyncFlag,1
         jne      wait_for_VBL
         mov     _SyncFlag,0


         cmp     FadeFlag,255
         jb      BNewFade2
         cmp     Termine,1    ; Terminer si dernier fade fini
         je      GoOut

         mov     _FadeON,0    ; don't set _TmpPal anymore ...
         jmp     @F
BNewFade2:mov     ax,FadeFlag  ; average Black-MyPal
         push    ax
         push    ds
         push    OFFSET _TmpPal
         mov     ax,FadePtr1+2
         push    ax
         mov     ax,FadePtr1
         push    ax
         mov     ax,FadePtr2+2
         push    ax
         mov     ax,FadePtr2
         push    ax
         call    _AveragePAL
         add     sp,7*2
         mov     _FadeON,1            ; set new PAL during next VR !!!
         mov     cx,_FrameCounter
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     BFaddi
         inc     cx
BFaddi:  add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     BFaddi
@@:

;----------- test if we must finish ... ----------
         mov     ax,_FrameCounter
         mov     _FrameCounter,0 ; set counter to NULL

         mov     _ReplayInfo.numChannels,4 ; 4 voices

         les     bx,DWORD PTR[_MP]
         push    ds
         push    OFFSET _ReplayInfo

         ; _MP->GetInformation(&ReplayInfo)

         call    (ModulePlayer PTR es:[bx]).GetInformation
         add     sp,4

         mov     ax,_ReplayInfo.pos
         shl     eax,14
         or      ax,_ReplayInfo.row
         or      ah,al
         shr     eax,8

         cmp     ax,WORD PTR[FinSong]    ; is it time ????
         jb      @F                      ; to fade off ???

         mov     Termine,1

         cmp     FadePtr2,OFFSET _BlackPal
         je      @F
         mov     FadeFlag,0
         mov     eax,DWORD PTR[FadePtr2]
         mov     DWORD PTR[FadePtr1],eax   ; fade to black !!!!
         mov     ax,ds
         mov     FadePtr2+2,ax
         mov     FadePtr2,OFFSET _BlackPal

@@:      xor     eax,eax
;--------------------------------------------------------------------

         SHOWTIME 32

         SHOWTIME 0

         mov     bx,_WorkAdr
         mov     WORD PTR[bx+2],1


         LOOP_UNTIL_KEY Main

;===============================================================

GoOut:

        FLUSH_KEYBUF                  ; Flush keyboard buffer !!! ;-)

        mov     _FadeON,0             ; to be sure ....

;----- EXIT -----

        STARTUP
        mov     ax,Picseg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

        popad
        nop
        ret

DoSnake   ENDP


PutSnake PROC NEAR                    ; put bitmap and set pal to black !!!


        MPUSH ax,cx,dx,si,di,ds,es

        mov   dx,3c8h                 ; pal reg.
        xor   al,al
        out   dx,al
        inc   dl
        mov   cx,768
@@:     out   dx,al                   ; black ....
        dec   cx
        jnz   @B


        mov   ax,Picseg
        add   ax,(768+32) SHR 4       ; segment of Snake pic "ConTrast"
        mov   ds,ax
        mov   ax,0a000h               ; video mem
        mov   es,ax

        xor   si,si                  ; skip alchemy header ...
        xor   di,di

        cld
        mov   cx,320*200/4
        rep   movsd                   ; copy to screen



        MPOP  ax,cx,dx,si,di,ds,es
        ret

PutSnake ENDP


;==============================================================================

SNAKE_TEXT ENDS

     END

