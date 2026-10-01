
;****************************************************
; PLUS OU MOINS NET (C) 1994 Type One / TFL-TDV Prod.
;****************************************************

INCLUDE PDFIK.INC ; DataFile Manager
INCLUDE VIDEO.INC ; Flamoot VGA SetUp
INCLUDE PLAYINFO.INC ; Player structures
INCLUDE KEYBOARD.INC ; Keyboard macros

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
DGROUP GROUP _DATA,_BSS
SNUL_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
          ASSUME CS:SNUL_TEXT,DS:DGROUP
SNUL_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------

_DATA SEGMENT  

;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'snuls.raw',0
Picparam  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname,0,0,0,,,0>

EXTRN _Expo : WORD
EXTRN _ExpoEnd : WORD

_DATA ENDS

; donn‚es non initialis‚es !!!
_BSS SEGMENT

EXTRN _FrameCounter     : WORD
EXTRN _StartAdr         : WORD
EXTRN _WorkAdr          : WORD
EXTRN _NextAdr          : WORD
EXTRN _Triple           : WORD
EXTRN _SyncFlag         : WORD
EXTRN _ShiftOfs         : WORD
;!!!!!!!!!! synchro avec music !!!!!!!!!!!!
EXTRN _MP               : DWORD ; extern ModulePlayer * MB
EXTRN _ReplayInfo       : mpInformation

;---- param pour synchro avec zizik ----
EVEN
DebSong  WORD ?
FinSong  WORD ?

EVEN
PicSeg   WORD ?        ; ptr vers segment pattern
Timeleft WORD ?        ; temps restant pour execution

Sens     WORD ?        ; expo direction !!!
WaitABit WORD ?        ; pause flag

_BSS ENDS 

SNUL_TEXT SEGMENT
     PUBLIC _StartSnul


; Point d'entr‚e de l'intro !!!!!
;---------------------------------
ALIGN
EVEN
_StartSnul PROC FAR

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

         push    m320x400x256p
         call    _SetVGA
         add     sp,2 

         STARTUP
;--------------------------------------
         call    Snul                ; !!!!! Snul part !!!!!
;--------------------------------------

         mov  ax,0a000h              ; clear screen
         mov  es,ax
         xor  eax,eax
         xor  di,di
         mov  cx,65536/4
         rep  stosd

         mov  _ShiftOfs,0            ; don't shift !!!!

         MPOP ds,es,fs,gs
         popad
         nop

         leave                             ; restore stack
                                           ; mov sp,bp + pop bp
         retf                              ; C/C++ retirera le param 

_StartSnul ENDP


;==============================================================================
;=============================== Snul part ====================================
;==============================================================================

ALIGN
EVEN
Snul PROC NEAR

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


;--------------------------------------------------


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
         cmp     ax,WORD PTR[DebSong]   ; is it time ????
         jb      WaitPos

         xor     eax,eax   

;------------------------------------------

         mov     bx,_StartAdr
         mov     WORD PTR[bx],0         ; _StartAdr->base = 0
         mov     WORD PTR[bx+2],0       ; _StartAdr->flag = false
         mov     bx,_WorkAdr
         mov     WORD PTR[bx],0         ; _WorkAdr->base
         mov     WORD PTR[bx+2],0       ; _WorkAdr->flag = false
         mov     _Triple,0
         VSYNC


;--------------- Put pic in Vid Mem ---------------
         push    ds
         push    es
         mov     ax,PicSeg
         add     ax,(768+32) SHR 4
         mov     ds,ax
         mov     ax,0a000h
         mov     es,ax
         xor     si,si
         mov     dx,3c4h
         mov     al,2
         out     dx,al
         inc     dl
         i = 0
         REPT    4
         mov     al,(1 SHL i)
         out     dx,al
         mov     di,320*400/4
         mov     cx,65536/4
@@:      lodsb
         add     si,3
         stosb
         dec     cx
         jnz     @B
         sub     si,65536-1
         i=i+1
         ENDM
         mov     bp,di
         inc     bp
         mov     ax,ds
         add     ax,65536 SHR 4
         mov     ds,ax
         i=0
         REPT    4
         mov     al,(1 SHL i)
         out     dx,al
         mov     di,bp
         mov     cx,(320*400-65536)/4
@@:      lodsb
         add     si,3
         stosb
         dec     cx
         jnz     @B
         sub     si,(320*400-65536)-1
         i=i+1
         ENDM

         pop     es
         pop     ds


;---------------

         STARTUP

         mov     si,OFFSET _Expo        ; exponential curve
         mov     Sens,0
         mov     WaitABit,0             ; no wait by default !!!

         EVEN
Main: ; -= VSYNC =-
         mov     ax,_FrameCounter
         test    ax,ax
         jz      Main

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
         jb      @F 
       ; jae     GoOut                   ; quitter si on doit !!!!!
         mov     WaitABit,0              ; force exit !!!!
@@:
         xor     eax,eax
;--------------------------------------------------------------------

         SHOWTIME 32

;**************** Scroll the pic *****************
         cmp     si,OFFSET _ExpoEnd
         jne     @F
         cmp     Sens,1       ; if 2 directions yet  
         je      GoOut        ; Go away !!!!!
         mov     si,OFFSET _Expo
         mov     Sens,1       ; change direction
         mov     WaitABit,70*3; wait 3 sec
       
@@:      cmp     WaitABit,0   ; No wait ????
         je      @F
;         dec     WaitABit     ; --
         jmp     SkipDis
@@:      lodsw                ; load next coord
         cmp     Sens,0
         je      @F
         sub     ax,400       ; invert curve
         neg     ax
@@:      mov     dx,80
         mul     dx           ; aaaaarghh a mul !!!! horror !!!!
         mov     _ShiftOfs,ax
SkipDis:
;**************************************************

         SHOWTIME 0

         LOOP_UNTIL_KEY Main

GoOut:

        FLUSH_KEYBUF                  ; Flush keyboard buffer !!! ;-)

;----- EXIT -----

        STARTUP
        mov     ax,Picseg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

        popad
        nop
        ret

Snul ENDP

;==============================================================================

SNUL_TEXT ENDS

     END



