
;*************************************************
; ELEPHANT PIC (C) 1994 Type One / TFL-TDV Prod.
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
ELEPH_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
            ASSUME CS:ELEPH_TEXT,DS:DGROUP
ELEPH_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------

_DATA SEGMENT


Screen1 = 0
Screen2 = (320*200/4)
Screen3 = (320*200/4*2)


;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'elephant.raw',0
Picparam  PARAM_STRUC<2,_DATA,OFFSET _Datafile,OFFSET Picname,0,0,0,,,0>

cumul_step_lo DD 0
cumul_step_hi DD 0
cumul_old_lo  DD 0
cumul_old_hi  DD 0
factor        DW 256

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
Dest DW ?

EVEN
Picseg    WORD ?        ; seg for pattern

FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?
Termine  WORD ?        ; flag pour terminer !!!

CurStep WORD ?         ; current step !!!


_BSS ENDS

ELEPH_TEXT SEGMENT
     PUBLIC _StartEleph
     EXTRN _AveragePAL : FAR

; Point d'entr‚e de l'intro !!!!!
;---------------------------------
ALIGN
EVEN
_StartEleph PROC FAR

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

         push    m320x200x256p ;m320x100x256c   ; set 320x200x256 col/chained 60hz
         call    _SetVGA
         add     sp,2

         STARTUP
;--------------------------------------
         call    DoEleph             ; !!!!! title part !!!!!
;--------------------------------------

         mov  dx,3c4h
         mov  ax,0f02h
         out  dx,ax
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

_StartEleph ENDP

;==============================================================================
;============================ Eleph part ======================================
;==============================================================================

ALIGN
EVEN
DoEleph PROC NEAR

; some macros 

;-------------------------------------------------------------------------------

NEXTSTEP MACRO
        LOCAL lbl1

;------------ FrameCounter manip ------------
        MPUSH  eax,ebx,ecx,edx

        mov    cx,_FrameCounter
        test   cx,cx
        jnz    lbl1
        mov    cx,1

lbl1:   xor    eax,eax
    ;;    mov    ah,cl ; frame*256
        mov    ax,factor           ; take factor
        mul    cx

        mov    ecx,cumul_step_lo   ; save old cumulated step (64 bits)
        mov    cumul_old_lo,ecx
        mov    ecx,cumul_step_hi
        mov    cumul_old_hi,ecx   
     
        add    cumul_step_lo,eax   ; multiprecision
        adc    cumul_step_hi,0

        mov    ecx,cumul_step_hi
        mov    eax,cumul_step_lo
        shrd   eax,ecx,8           ; / 256
        mov    edx,cumul_old_hi
        mov    ebx,cumul_old_lo
        shrd   ebx,edx,8

        sub    eax,ebx
;        sbb    ecx,edx

        mov    CurStep,ax  ; CurStep = factor * FrameCounter

        mov    _FrameCounter,0

        MPOP   eax,ebx,ecx,edx
;--------------------------------------------

ENDM


NEWCOORD MACRO
         LOCAL   lbl2,lbl3,lobl1,lobl2,majSize,okscal
         MPUSH   ax,cx

         mov     ax,CurStep

         add     cs:[DXsize],ax
         cmp     cs:[DXsize],319 
         jae     lbl2
         jmp     lobl1
lbl2:    mov     cs:[DXsize],319
         inc     factor
         sub     cs:[SXsize],ax
         cmp     cs:[SXsize],1  ; jusque 1 pixel de large !!!!
         jge     lobl1
         mov     cs:[SXsize],1
lobl1:   add     cs:[DYsize],ax
         cmp     cs:[DYsize],199 
         jae     lbl3
         jmp     lobl2
lbl3:    mov     cs:[DYsize],199
         inc     factor         ; accelere
        ; add     factor,2
         sub     cs:[SYsize],ax
         cmp     cs:[SYsize],1  
         jge     lobl2
         mov     cs:[SYsize],1
lobl2:

         MPOP    ax,cx
ENDM

;------------------------------------

TESTFADE MACRO
         LOCAL BNewFade2,BFaddi,lbl1

         cmp     FadeFlag,255
         jb      BNewFade2
         cmp     Termine,1    ; Terminer si dernier fade fini
         je      GoOut

         mov     _FadeON,0    ; don't set _TmpPal anymore ...
         jmp     lbl1
BNewFade2:
         MPUSH   ax,cx

         mov     ax,FadeFlag  ; average Black-MyPal
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
         mov     cx,CurStep
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     BFaddi
         inc     cx
BFaddi:  add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     BFaddi

         MPOP    ax,cx
lbl1:

ENDM

;----------------------------

TESTFINISH MACRO
         LOCAL   lbl1
         MPUSH   eax,bx,es

;----------- test if we must finish ... ----------

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
         jb      lbl1                    ; to fade off ???

         mov     Termine,1

         cmp     FadePtr2,OFFSET _BlackPal
         je      lbl1
         mov     FadeFlag,0
         mov     eax,DWORD PTR[FadePtr2]
         mov     DWORD PTR[FadePtr1],eax   ; fade to black !!!!
         mov     ax,ds
         mov     FadePtr2+2,ax
         mov     FadePtr2,OFFSET _BlackPal

lbl1:      

         MPOP    eax,bx,es
        
ENDM



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
;         mov     ax,_FrameCounter
;         mov     Delai,ax
         mov     _FrameCounter,0
         mov     Delai,0


         mov     bx,_StartAdr
         mov     WORD PTR[bx],Screen1   ; _StartAdr->base = 0
         mov     WORD PTR[bx+2],0       ; _StartAdr->flag = false
         mov     bx,_WorkAdr
         mov     WORD PTR[bx],Screen2   ; _WorkAdr->base
         mov     WORD PTR[bx+2],0       ; _WorkAdr->flag = false
         mov     bx,_NextAdr
         mov     WORD PTR[bx],Screen3   ; _NextAdr->base
         mov     WORD PTR[bx+2],0       ; _NextAdr->flag = false
         mov     _Triple,1              ; triple buffering

         VSYNC


EVEN
Main: ; -= VSYNC =-

;***** 2nd page *****
Do_a_frame:
         mov  di,_WorkAdr
         cmp  WORD PTR[di+2],1 ; _WorkAdr->flag true (previous _NextAdr) ?
         je   NextFrame        ; then construct next frame

         NEXTSTEP                   ; new step !!!

         TESTFADE                   ; prepare for fading

         NEWCOORD                   ; new coordinates !!!

         TESTFINISH                 ; test if end

         mov  Dest,di               ; save pointer

         SHOWTIME 32
         call    ZoomEleph          ; zoom elephant
         SHOWTIME 0

         mov    di,_NextAdr         ; save adr of next buffer

         mov    bx,Dest
         mov    WORD PTR[bx+2],1    ; _WorkAdr->flag = true

         jmp  Nexxxt

;******** 3rd page *********
NextFrame:
         mov  di,_NextAdr
         cmp  WORD PTR[di+2],1 ; _NextAdr true ?
         je   NextFrame
    
Nexxxt:
         NEXTSTEP                   ; new step !

         TESTFADE                   ; prepare for fading

         NEWCOORD

         TESTFINISH                 ; test if end

         mov  Dest,di               ; save pointer

         SHOWTIME 32
         call    ZoomEleph          ; zoom elephant
         SHOWTIME 0


         mov    bx,Dest
         mov    WORD PTR[bx+2],1     ; _NextAdr->flag = true


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

DoEleph   ENDP


;******** Zoom Elephant *********
ZoomEleph PROC NEAR

          MPUSH ax,cx,dx,si,di,bp,ds,es

          mov   ax,0a000h             ; video base
          mov   es,ax

          mov  bx,[Dest]                   ; begin by the beginning
          mov  bx,WORD PTR [bx]            ; _WorkAdr->base

;          -- centrage -- 
          mov   di,cs:DYsize
          shr   di,1
          sub   di,100 
          neg   di                    ; 100 - Y/2
          mov   ax,80
          mul   di                    ; ahurk !!!!
          mov   di,ax
          mov   ax,cs:DXsize
          shr   ax,1 
          sub   ax,160                ; 160 - X/2
          neg   ax
          mov   cs:Centre,ax
          shr   ax,2
          add   di,ax

          add   di,bx                 ; + StartAdr !!! 

          mov   bx,cs:[SYsize]
          shr   bx,1
          sub   bx,128
          neg   bx
          sal   bx,8
          mov   cs:Patch4+1,bx
          mov   bx,cs:[SXsize]
          shr   bx,1
          sub   bx,128 ;113
          neg   bx
          sal   bx,8
          mov   cs:Patch5+1,bx

;         -----------------

          mov   ax,Picseg
          add   ax,(768+32) SHR 4
          mov   ds,ax                 ; DS=adr pic

          mov   cs:Patch2+2,80        ; len of line
          mov   ax,cs:DXsize
          shr   ax,2
          test  ax,ax
          jnz   @F
          inc   ax
@@:
          mov   cs:[Nbloop1],ax
          and   ax,0fffeh  
          jnz   @F
          add   ax,2  
@@:
          sub   cs:Patch2+2,ax        ; - len of bitmap
          shr   ax,1 
          mov   cs:[Nbloop2],ax

          xor   dx,dx
          mov   ax,cs:SXsize          ; source X-Width
          sal   ax,8 
          rcl   dx,8  
          div   cs:DXsize             ; calculate X-ratio
          mov   si,ax                 ; increment

          mov   cx,cs:[Centre]
          and   cx,3
          jz    skiper
@@:       sub   cs:[Patch5+1],si
          dec   cx                    ; align 
          jnz   @B
skiper:
          jmp   $+2                   ; flush prefetch queue
          

Patch4    LABEL  WORD
          mov   cx,1234h              ; y point fixe

          mov   bp,cs:DYsize          ; nb plots in height 
Haut:     push  bp

          push  di                    ; save di
          xor   di,di 

          mov   bp,cs:[Nbloop1]       ; nb plots/line
Patch5    LABEL  WORD 
          mov   dx,1234h              ; x point fixe
          mov   bh,ch                 ; new index
Larg:
          mov   bl,dh
          mov   al,BYTE PTR[bx]       ; take corresponding pixel
          mov   BYTE PTR cs:[di+Plan1],al
          add   dx,si
          mov   bl,dh
          mov   al,BYTE PTR[bx]
          mov   BYTE PTR cs:[di+Plan2],al
          add   dx,si
          mov   bl,dh
          mov   al,BYTE PTR[bx]
          mov   BYTE PTR cs:[di+Plan3],al
          add   dx,si
          mov   bl,dh
          mov   al,BYTE PTR[bx]
          mov   BYTE PTR cs:[di+Plan4],al
          add   dx,si                 ; next point
          inc   di 
          dec   bp
          jnz   Larg
          
          jmp   $+2 ; flush prefetch queue

; one line done ....

          pop   di

          MPUSH cx,dx,si,ds  ; copy onto screen

          mov   dx,3c4h
          mov   ax,0102h ; 1st bitplane
          out   dx,ax
          inc   dl
       
          mov   bx,cs:[Nbloop2]
          mov   bp,di

          push  cs
          pop   ds

          mov   si,OFFSET Plan1
          mov   cx,bx
          rep   movsw           ; copy 1 line ....
          mov   di,bp

          mov   al,02h
          out   dx,al
          mov   si,OFFSET Plan2
          mov   cx,bx
          rep   movsw
          mov   di,bp

          mov   al,04h
          out   dx,al
          mov   si,OFFSET Plan3
          mov   cx,bx
          rep   movsw 
          mov   di,bp

          mov   al,08h
          out   dx,al
          mov   si,OFFSET Plan4
          mov   cx,bx
          rep   movsw

          MPOP  cx,dx,si,ds 

Patch2    LABEL WORD
          add   di,1234h 
          add   cx,si                 ; next line          

          pop   bp
          dec   bp
          jnz   Haut

          MPOP  ax,cx,dx,si,di,bp,ds,es
          ret

;----------------------------------------

SXsize DW 255    ; source sizes
SYsize DW 226
DXsize DW 7      ; dest sizes
DYsize DW 6 
Centre DW 0
Nbloop1 DW 0
Nbloop2 DW 0

Plan1 DB 84 DUP(0)
Plan2 DB 84 DUP(0)
Plan3 DB 84 DUP(0)
Plan4 DB 84 DUP(0)

ZoomEleph ENDP

;==============================================================================

ELEPH_TEXT ENDS

     END

