
;*************************************************
; ROTATIVE ZOOM (C) 1994 Type One / TFL-TDV Prod.
;*************************************************

INCLUDE PDFIK.INC ; DataFile Manager 
INCLUDE VIDEO.INC ; Flamoot VGA SetUp
INCLUDE PLAYINFO.INC ; Player structures
INCLUDE KEYBOARD.INC ; Keyboard macros

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
DGROUP GROUP _DATA,_BSS
ROTA_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
       ASSUME CS:ROTA_TEXT,DS:DGROUP
ROTA_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------

_DATA SEGMENT

; Quelques constantes bien utiles ......

Larg = 160       ; hauteur de l'‚cran en pixels
Haut = 80        ; largeur de l'‚cran en pixels
Windowx = 160    ; largeur fenetre
Windowy = 80     ; hauteur fenetre

Screen1 = 0
Screen2 = (Larg*Haut/4)
Screen3 = (Larg*Haut/4)*2

;---------------------------------------------

;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'tipon.raw',0
Picparam  PARAM_STRUC<2,_DATA,OFFSET _Datafile,OFFSET Picname,0,0,0,,,0>

EVEN
; rotation parameters
Angle  WORD 0          ; angle de rotation
Scalx  WORD 0          ; echelle en x (*256)
Scaly  WORD 0          ; echelle en y (*256)
Coordx WORD 0          ; coordonnee initiale x
Coordy WORD 0          ; coordonnee initiale y
Stepx  WORD 0          ; pas en x
Stepy  WORD 0          ; pas en y
Yptr   WORD 0          ; pointeur sinus en y
Xptr   WORD 0          ; pointeur sinus en x

cumul_step_lo DD 0
cumul_step_hi DD 0
cumul_old_lo  DD 0
cumul_old_hi  DD 0


EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE

_DATA ENDS

;donn‚es non initialis‚es
;-------------------------
_BSS SEGMENT

EXTRN _FrameCounter     : WORD
EXTRN _SinusTbl         : WORD  ; table sinus pour rotation (sin*256)
EXTRN _StartAdr         : WORD 
EXTRN _WorkAdr          : WORD
EXTRN _NextAdr          : WORD
EXTRN _Triple           : WORD
EXTRN _SyncFlag         : WORD
EXTRN _TmpPal           : BYTE
EXTRN _FadeON           : WORD
EXTRN _VGAcompatible    : WORD
;!!!!!!!!!! synchro avec music !!!!!!!!!!!!
EXTRN _MP               : DWORD ; extern ModulePlayer * MB
EXTRN _ReplayInfo       : mpInformation

EVEN


EVEN
Picseg    WORD ?        ; ptr vers segment pattern
TabSeg    WORD ?        ; ptr vers segment curves table
SinePtr   WORD ?        ; ptr vers sous-table
Timeleft  WORD ?        ; temps restant pour execution

;---- param pour synchro avec zizik ----
EVEN
DebSong  WORD ?
FinSong  WORD ?


Dest DW ?
FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?
Termine  WORD ?        ; flag pour terminer !!!

;-------------
; Flags 

Anim    WORD ?
RotFlag WORD ?
Indep   WORD ?
Sine    WORD ?

CurStep WORD ?         ; current step !!!

_BSS ENDS

ROTA_TEXT SEGMENT
     PUBLIC _StartZoom
     EXTRN _AveragePAL : FAR


; !!!! Point d'entree de l'intro !!!!

ALIGN
EVEN
_StartZoom PROC FAR

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

         cmp     _VGAcompatible,0
         je      @F 
         push    m160x80x256c        ; set 7-mode if full VGA compatible 
         jmp     FullVGA
@@:      push    m320x80x256c
FullVGA: call    _SetVGA
         add     sp,2

         STARTUP
;--------------------------------------
         call    Rotatif             ; !!!!! rotate part !!!!!
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

_StartZoom ENDP

;==============================================================================
;========================== Rotative part =====================================
;==============================================================================
ALIGN
EVEN
Rotatif PROC NEAR


; Some Macros ...

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

NEXTSTEP MACRO
        LOCAL lbl1

;------------ FrameCounter manip ------------
        MPUSH  eax,ebx,ecx,edx

        mov    cx,_FrameCounter
        test   cx,cx
        jnz    lbl1
        mov    cx,1

lbl1:   xor    eax,eax
        mov    ah,cl ; frame*256
       ; mov    ax,256 ;307              ; 1.2*256 = factor
       ; mul    cx

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

         mov     ah,48h                ; MALLOC
         mov     bx,(65535 SHR 4)+1    ; memory requested
         int     21h
         mov     TabSeg,ax             ; Segment address returned

; do precalculations   (calculer table des courbes !!!)

         push    es
         mov     ax,TabSeg             ; my table
         mov     es,ax
         xor     di,di
         mov     bx,0                  ; amplitude de base
         mov     cx,32                 ; 32 arrays of 2048 bytes (sinus)
EVEN        
looper:
         mov     si,OFFSET _SinusTbl   ; Sine table
         push    cx
         mov     cx,1024               ; 1024 valeurs/courbe
@@:
         lodsw
         imul    bx                    ; * amplitude
         mov     al,ah                 ; normaliser
         mov     ah,dl
         stosw                         ; sauver valeur
         dec     cx                    ; loop    @B
         jnz     @B
         pop     cx
         add     bx,8                  ; calculer amplitude suivante
         dec     cx                    ; loop    looper
         jnz     looper
         pop     es


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
         mov     Anim,0    ; pas encore animation
         mov     RotFlag,0 ; pas encore rotation
         mov     Indep,0   ; pas encore scale independant
         mov     Sine,0    ; pas encore sinus
         mov     SinePtr,0 ; 1st sinus table = 000000
         mov     Xptr,128


         mov     Angle,0
         mov     Scalx,512*2  
         mov     Scaly,512*2  
         mov     Coordx,92 
         mov     Coordy,192 
         mov     Stepx,-4*2 
         mov     Stepy,-4*2 

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
         mov     _Framecounter,0
         mov     Delai,0

         cmp     _VGAcompatible,0
         je      NoCompatible      ; if card doesn't support 7-mode technology

;==================== VGA compatible code =====================
;        works in 7-mode technology --> hardware pixel doubling (fast!)

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
MainRot: ; " VSYNC "

;***** 2nd page *****
Do_a_frame:
         mov  di,_WorkAdr
         cmp  WORD PTR[di+2],1 ; _WorkAdr->flag true (previous _NextAdr) ?
         je   NextFrame        ; then construct next frame

         mov  Dest,di          ; save pointer

         NEXTSTEP              ; calculate current step !!!!

         cmp     Anim,0
         je      Fade

         mov     ax,CurStep   ; get current step !!!

         cmp     RotFlag,0
         je      pasRot
         add     Angle,ax     ; reupdate position, angle and scaling
         add     Angle,ax
pasRot:   
         sub     Coordx,ax
         sub     Coordx,ax
         add     Coordy,ax    ; incrementer en fonction des VBLs attendues
         add     Coordy,ax
         mov     cx,ax        ; nombre de VBLs perdues...
@@:      mov     ax,Stepx
         add     Scalx,ax     ; echelle en x
         mov     ax,Stepy
         add     Scaly,ax     ; echelle en y
         add     Yptr,6       ; pointeur sinus vertical (moving)
         and     Yptr,1023
         add     Xptr,4       ; pointeur sinus horizontal (scaling)
         and     Xptr,1023
         dec     cx           ; loop    @B
         jnz     @B

         cmp     Sine,1
         jne     Clip
         cmp     SinePtr,63488; max reached ???
         je      Clip
         add     SinePtr,2048 ; if sine enabled, jump to next table

Clip:
         cmp     Scalx,32     ; keep scaling in the "range"
         jg      @F
         neg     Stepx
         cmp     Indep,0
         jne     tsta
         neg     Stepy
         cmp     RotFlag,1
         jne     Fade
         mov     Indep,1      ; enable bidirectionnal scaling
         add     Stepy,2      ; asymetric !!!!
         jmp     Fade
tsta:    cmp     RotFlag,1
         jne     @F
         mov     Sine,1       ; enable sinus !!! 
@@:      cmp     Scalx,2048
         jl      @F
         mov     RotFlag,1    ; active rotations now !!!  
         neg     Stepx
         cmp     Indep,0
         jne     @F
         neg     Stepy
         jmp     Fade
@@:      cmp     Scaly,32
         jg      @F
         neg     Stepy
         cmp     Indep,0
         jne     tstb
         neg     Stepx
         cmp     RotFlag,1
         jne     Fade
         mov     Indep,1      ; enable bidirectionnal scaling
         inc     Stepy        ; asymetric !!!!  
         jmp     Fade
tstb:    cmp     RotFlag,1
         jne     @F
         mov     Sine,1       ; enable sinus !!!
@@:      cmp     Scaly,2048
         jl      @F
         mov     RotFlag,1    ; active rotations now !!!
         neg     Stepy
         cmp     Indep,0
         jne     @F
         neg     Stepx
@@:    

Fade:
         cmp     FadeFlag,255
         jb     @F
         cmp     Termine,1            ; Terminer si dernier fade fini
         je      GoOutRot
         mov     Anim,1
         mov     _FadeON,0            ; no more new PAL ....
         jmp     Hela
@@:      mov     ax,FadeFlag          ; average Black-MyPal
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
         mov     _FadeON,1            ; set new PAL during VSYNC !! 
         mov     cx,CurStep           ; relative to step !!!
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     Faddi
         inc     cx
Faddi:   add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     Faddi
Hela:      



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
         jb      @F                      ; to fade off ???

         mov     Termine,1

         cmp     FadePtr2,OFFSET _WhitePal
         je      @F
         mov     FadeFlag,0
         mov     eax,DWORD PTR[FadePtr2]
         mov     DWORD PTR[FadePtr1],eax   ; fade to white !!!!
         mov     ax,ds
         mov     FadePtr2+2,ax
         mov     FadePtr2,OFFSET _WhitePal
@@:      xor     eax,eax
;--------------------------------------------------------------------


         SHOWTIME 32

         call    Rotate_It

         mov    di,_NextAdr

         mov    bx,Dest
         mov    WORD PTR[bx+2],1     ; _WorkAdr->flag = true

         SHOWTIME 0

         jmp  Nexxxt

;******** 3rd page *********
NextFrame:
         mov  di,_NextAdr
         cmp  WORD PTR[di+2],1 ; _NextAdr true ?
         je   NextFrame
    
Nexxxt:
         mov  Dest,di          ; save pointer

         NEXTSTEP              ; calculate current step !!!

         cmp     Anim,0
         je      Fade2

         mov     ax,CurStep   ; get current step !!!

         cmp     RotFlag,0
         je      pasRot2
         add     Angle,ax     ; reupdate position, angle and scaling
         add     Angle,ax
pasRot2:
         sub     Coordx,ax
         sub     Coordx,ax
         add     Coordy,ax    ; incrementer en fonction des VBLs attendues
         add     Coordy,ax
         mov     cx,ax        ; nombre de VBLs perdues...
@@:      mov     ax,Stepx
         add     Scalx,ax     ; echelle en x
         mov     ax,Stepy
         add     Scaly,ax     ; echelle en y
         add     Yptr,6       ; pointeur sinus vertical (moving)
         and     Yptr,1023
         add     Xptr,4       ; pointeur sinus horizontal (scaling)
         and     Xptr,1023
         dec     cx           ; loop    @B
         jnz     @B

         cmp     Sine,1
         jne     Clip2
         cmp     SinePtr,63488; max reached ???
         je      Clip2
         add     SinePtr,2048 ; if sine enabled, jump to next table

Clip2:
         cmp     Scalx,32     ; keep scaling in the "range"
         jg      @F
         neg     Stepx
         cmp     Indep,0
         jne     tsta2
         neg     Stepy
         cmp     RotFlag,1
         jne     Fade2
         mov     Indep,1      ; enable bidirectionnal scaling
         add     Stepy,2      ; asymetric !!!!
         jmp     Fade2
tsta2:   cmp     RotFlag,1
         jne     @F
         mov     Sine,1       ; enable sinus !!! 
@@:      cmp     Scalx,2048
         jl      @F
         mov     RotFlag,1    ; active rotations now !!!  
         neg     Stepx
         cmp     Indep,0
         jne     @F
         neg     Stepy
         jmp     Fade2
@@:      cmp     Scaly,32
         jg      @F
         neg     Stepy
         cmp     Indep,0
         jne     tstb2
         neg     Stepx
         cmp     RotFlag,1
         jne     Fade2
         mov     Indep,1      ; enable bidirectionnal scaling
         inc     Stepy        ; asymetric !!!!  
         jmp     Fade2
tstb2:   cmp     RotFlag,1
         jne     @F
         mov     Sine,1       ; enable sinus !!!
@@:      cmp     Scaly,2048
         jl      @F
         mov     RotFlag,1    ; active rotations now !!!
         neg     Stepy
         cmp     Indep,0
         jne     @F
         neg     Stepx
@@:    


Fade2:
         cmp     FadeFlag,255
         jb      @F
         cmp     Termine,1            ; Terminer si dernier fade fini ...
         je      GoOutRot
         mov     Anim,1
         mov     _FadeON,0            ; no more new PAL ....
         jmp     Hela2
@@:      mov     ax,FadeFlag          ; average Black-MyPal
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
         mov     _FadeON,1            ; set new PAL during VSYNC !!!!   
         mov     cx,CurStep           ; relative to CurStep
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     Faddi2
         inc     cx
Faddi2:  add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     Faddi2
Hela2:

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
         jb      @F                      ; to fade off ???

         mov     Termine,1


         cmp     FadePtr2,OFFSET _WhitePal
         je      @F
         mov     FadeFlag,0
         mov     eax,DWORD PTR[FadePtr2]
         mov     DWORD PTR[FadePtr1],eax   ; fade to white !!!!
         mov     ax,ds
         mov     FadePtr2+2,ax
         mov     FadePtr2,OFFSET _WhitePal
@@:      xor     eax,eax
;--------------------------------------------------------------------


         SHOWTIME 32

         call    Rotate_It

         mov    bx,Dest
         mov    WORD PTR[bx+2],1     ; _WorkAdr->flag = true

         SHOWTIME 0

         LOOP_UNTIL_KEY MainRot

         jmp     GoOutRot

;===============================================================

;===================== No VGA compatible code ==================

NoCompatible:  ; works in standard 320 width --> software pixel doubling (slow)

         mov     bx,_StartAdr
         mov     WORD PTR[bx],Screen1   ; _StartAdr->base = 0
         mov     bx,_WorkAdr
         mov     WORD PTR[bx],Screen2*2 ; _WorkAdr->base
         mov     WORD PTR[bx+2],0       ; _WorkAdr->flag = false
         mov     _Triple,0              ; double buffering
         mov     _SyncFlag,1
         VSYNC

EVEN
BMainRot: ; " VSYNC "

wait_for_VBL:                       ; wait for Sync Flag
         cmp     _SyncFlag,1
         jne      wait_for_VBL
         mov     _SyncFlag,0

         NEXTSTEP                   ; calculate current step !!!

         cmp     Anim,0
         je      BFade

         mov     ax,CurStep         ; get current step

         cmp     RotFlag,0
         je      BpasRot
         add     Angle,ax     ; reupdate position, angle and scaling
         add     Angle,ax
BpasRot:
         sub     Coordx,ax
         sub     Coordx,ax
         add     Coordy,ax    ; incrementer en fonction des VBLs attendues
         add     Coordy,ax
         mov     cx,ax        ; nombre de VBLs perdues...
@@:      mov     ax,Stepx
         add     Scalx,ax     ; echelle en x
         mov     ax,Stepy
         add     Scaly,ax     ; echelle en y
         add     Yptr,6       ; pointeur sinus vertical (moving)
         and     Yptr,1023
         add     Xptr,4       ; pointeur sinus horizontal (scaling)
         and     Xptr,1023
         dec     cx           ; loop    @B
         jnz     @B

         cmp     Sine,1
         jne     BClip
         cmp     SinePtr,63488; max reached ???
         je      BClip
         add     SinePtr,2048 ; if sine enabled, jump to next table

BClip:
         cmp     Scalx,32     ; keep scaling in the "range"
         jg      @F
         neg     Stepx
         cmp     Indep,0
         jne     Btsta
         neg     Stepy
         cmp     RotFlag,1
         jne     BFade
         mov     Indep,1      ; enable bidirectionnal scaling
         add     Stepy,2      ; asymetric !!!!
         jmp     BFade
Btsta:   cmp     RotFlag,1
         jne     @F
         mov     Sine,1       ; enable sinus !!! 
@@:      cmp     Scalx,2048
         jl      @F
         mov     RotFlag,1    ; active rotations now !!!  
         neg     Stepx
         cmp     Indep,0
         jne     @F
         neg     Stepy
         jmp     BFade
@@:      cmp     Scaly,32
         jg      @F
         neg     Stepy
         cmp     Indep,0
         jne     Btstb
         neg     Stepx
         cmp     RotFlag,1
         jne     BFade
         mov     Indep,1      ; enable bidirectionnal scaling
         inc     Stepy        ; asymetric !!!!  
         jmp     BFade
Btstb:   cmp     RotFlag,1
         jne     @F
         mov     Sine,1       ; enable sinus !!!
@@:      cmp     Scaly,2048
         jl      @F
         mov     RotFlag,1    ; active rotations now !!!
         neg     Stepy
         cmp     Indep,0
         jne     @F
         neg     Stepx
@@:    

BFade:
         cmp     FadeFlag,255
         jb     @F
         cmp     Termine,1            ; Terminer si dernier fade fini
         je      GoOutRot
         mov     Anim,1
         mov     _FadeON,0            ; no more new PAL ....
         jmp     BHela
@@:      mov     ax,FadeFlag          ; average Black-MyPal
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
         mov     _FadeON,1            ; set new PAL during VSYNC !! 
         mov     cx,CurStep           ; relative to CurStep
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     BFaddi
         inc     cx
BFaddi:  add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     BFaddi
BHela:

;------------------- test if we must finish ... ---------------------

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

         cmp     FadePtr2,OFFSET _WhitePal
         je      @F
         mov     FadeFlag,0
         mov     eax,DWORD PTR[FadePtr2]
         mov     DWORD PTR[FadePtr1],eax   ; fade to white !!!!
         mov     ax,ds
         mov     FadePtr2+2,ax
         mov     FadePtr2,OFFSET _WhitePal
@@:      xor     eax,eax
;--------------------------------------------------------------------

         SHOWTIME 32

         mov     di,_WorkAdr
         mov     Dest,di          ; save pointer

         call    BRotate_It       ; algo-B ==> software pixel doubling

         mov    bx,_WorkAdr
         mov    WORD PTR[bx+2],1     ; _WorkAdr->flag = true

         SHOWTIME 0

         LOOP_UNTIL_KEY BMainRot

;===============================================================

GoOutRot:

        FLUSH_KEYBUF                  ; Flush keyboard buffer !!! ;-)


;----- EXIT -----

        mov     _FadeON,0             ; don't set PAL ...

        STARTUP
        mov     ax,TabSeg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

        mov     ax,Picseg             ; idem ...
        mov     es,ax
        mov     ah,49h
        int     21h

        popad
        nop
        ret

Rotatif ENDP

;==============================================================================

;----------------- 7-mode algorithm --> hardware pixel doubling ---------------
ALIGN
EVEN
Rotate_It PROC NEAR                   ; rotation de l'image

incx  TEXTEQU <1234h>
incy  TEXTEQU <1234h>
xpos  TEXTEQU <1234h>
ypos  TEXTEQU <1234h>
YSINE TEXTEQU <1000h>

        push    ds

; patcher sinus vertical (moving) !!!!
        push    ds
        mov     si,SinePtr             ; base sinus !
        add     si,Yptr                ; + offset
        mov     ax,TabSeg
        mov     ds,ax
        mov     di,OFFSET patch_it+6   ; 1er patch !
        mov     cx,Windowx/2           ; pour tous les mov al,[bx+...]
        EVEN
@@:     lodsw                          ; charger sinus*256
        sal     ax,8
        xor     al,al 
        mov     cs:[di],ax             ; poker dans le code
        add     di,12                  ; patcher les offsets dans le code !
        lodsw
        sal     ax,8
        xor     al,al
        mov     cs:[di],ax
        add     di,13
        dec     cx                     ; loop    @B
        jnz     @B
        pop     ds

; patcher sinus horizontal (scaling) !!!!
        push    ds
        mov     si,SinePtr             ; base sinus !
        add     si,Xptr                ; + offset
        mov     ax,TabSeg
        mov     ds,ax
        mov     di,OFFSET patch_it+6   ; 1er patch !
        mov     cx,Windowx/2           ; pour tous les mov al,[bx+...]
EVEN
@@:     lodsw                          ; charger sinus*256
        add     cs:[di],ax             ; poker dans le code
        add     di,12                  ; patcher les offsets dans le code !
        lodsw
        add     cs:[di],ax
        add     di,13
        dec     cx                     ; loop    @B
        jnz     @B
        pop     ds


; rotation !!!
        xor     eax,eax
        mov     ax,Angle                ; recuperer l'angle O
        and     ax,511                  ; modulo 360

        movsx   ebx,_SinusTbl[eax*2]    ; sin(O)*256
        movsx   edx,Scalx               ; * facteur d'‚chelle en x
        imul    edx,ebx
        sar     edx,8
        mov     bp,dx                   ; bp = incy

        movsx   edx,Scaly               ; * facteur d'‚chelle en y
        imul    edx,ebx
        sar     edx,8
        mov     WORD PTR cs:[pat9+5],dx ; patch the code...

        movsx   ebx,_SinusTbl[eax*2+256]; -cos(O)*256
        neg     ebx                     ; cos(O)*256
        movsx   edx,Scalx               ; * facteur d'‚chelle en x
        imul    edx,ebx
        sar     edx,8
        mov     si,dx                   ; si = incx

        movsx   edx,Scaly               ; * facteur d'‚chelle en y
        imul    edx,ebx
        sar     edx,8
        mov     WORD PTR cs:[pat10+5],dx; patch the code...

        mov     ax,Coordx              ; coord. initiales
        sal     ax,8
        mov     WORD PTR cs:[posx+1],ax
        mov     ax,Coordy
        sal     ax,8
        mov     WORD PTR cs:[posy+1],ax

; 2D mapping

        mov     ax,0a000h             ; Screen base
        mov     es,ax
        mov     di,Dest               ; offset 0 (Screen)
        mov     di,WORD PTR[di]
        shl     di,2                  ; *4
        mov     ax,PicSeg             ; Picture base
        add     ax,(768+32) SHR 4     ; skip the header+pal !!!!!
        mov     ds,ax

        mov     cx,Windowy            ; 80 lines
EVEN
Fill:   push    cx                    ; mov     gs,cx ; save CX
posy:   mov     dx,ypos               ; position en y*256
posx:   mov     cx,xpos               ; position en x*256

; calcul d'une ligne ...
patch_it LABEL WORD
        REPT (Windowx/2)-1            ; 160 pixels width
        mov    bl,ch                  ; partie haute x
        mov    bh,dh                  ; partie haute y
        mov    al,[bx+YSINE]          ; prendre valeur sur map
        add    dx,bp                  ; increment y
        add    cx,si                  ; increment x
        mov    bl,ch                  ; partie haute x
        mov    bh,dh                  ; partie haute y
        mov    ah,[bx+YSINE]          ; prendre valeur sur map
        stosw                         ; afficher
        add    dx,bp                  ; increment y
        add    cx,si                  ; increment x
        ENDM
        mov    bl,ch
        mov    bh,dh
        mov    al,[bx+YSINE]
        add    dx,bp
        add    cx,si
        mov    bl,ch
        mov    bh,dh
        mov    ah,[bx+YSINE]
        stosw


; passer … la ligne suivante … afficher
pat9:   add     WORD PTR cs:[posx+1],incy      ; posx + sin(O)
pat10:  sub     WORD PTR cs:[posy+1],incx      ; posy - cos(O)

        IF (Larg-Windowx) NE 0
          add     di,(Larg-Windowx)   ; ligne suivante...
        ENDIF

        pop     cx                    ; mov  cx,gs ; restore CX
        dec     cx
        jnz     Fill
@@:


        pop     ds

        ret

Rotate_It ENDP

;----------- No VGA compatible algorithm --> software pixel doubling -----------
ALIGN
EVEN
BRotate_It PROC NEAR                   ; rotation de l'image

incx  TEXTEQU <1234h>
incy  TEXTEQU <1234h>
xpos  TEXTEQU <1234h>
ypos  TEXTEQU <1234h>
YSINE TEXTEQU <1000h>

        push    ds


; patcher sinus vertical (moving) !!!!
        push    ds
        mov     si,SinePtr             ; base sinus !
        add     si,Yptr                ; + offset
        mov     ax,TabSeg
        mov     ds,ax
        mov     di,OFFSET Bpatch_it+6  ; 1er patch !
        mov     cx,Windowx             ; pour tous les mov al,[bx+...]
        EVEN
@@:     lodsw                          ; charger sinus*256
        sal     ax,8
        xor     al,al 
        mov     cs:[di],ax             ; poker dans le code
        add     di,15                  ; patcher les offsets dans le code !
        dec     cx
        jnz     @B
        pop     ds

; patcher sinus horizontal (scaling) !!!!
        push    ds
        mov     si,SinePtr             ; base sinus !
        add     si,Xptr                ; + offset
        mov     ax,TabSeg
        mov     ds,ax
        mov     di,OFFSET Bpatch_it+6  ; 1er patch !
        mov     cx,Windowx             ; pour tous les mov al,[bx+...]
EVEN
@@:     lodsw                          ; charger sinus*256
        add     cs:[di],ax             ; poker dans le code
        add     di,15                  ; patcher les offsets dans le code !
        dec     cx
        jnz     @B
        pop     ds


; rotation !!!
        xor     eax,eax
        mov     ax,Angle                ; recuperer l'angle O
        and     ax,511                  ; modulo 360

        movsx   ebx,_SinusTbl[eax*2]    ; sin(O)*256
        movsx   edx,Scalx               ; * facteur d'‚chelle en x
        imul    edx,ebx
        sar     edx,8
        mov     bp,dx                   ; bp = incy

        movsx   edx,Scaly               ; * facteur d'‚chelle en y
        imul    edx,ebx
        sar     edx,8
        mov     WORD PTR cs:[Bpat9+5],dx; patch the code...

        movsx   ebx,_SinusTbl[eax*2+256]; -cos(O)*256
        neg     ebx                     ; cos(O)*256
        movsx   edx,Scalx               ; * facteur d'‚chelle en x
        imul    edx,ebx
        sar     edx,8
        mov     si,dx                   ; si = incx

        movsx   edx,Scaly               ; * facteur d'‚chelle en y
        imul    edx,ebx
        sar     edx,8
        mov     WORD PTR cs:[Bpat10+5],dx; patch the code...

        mov     ax,Coordx              ; coord. initiales
        sal     ax,8
        mov     WORD PTR cs:[Bposx+1],ax
        mov     ax,Coordy
        sal     ax,8
        mov     WORD PTR cs:[Bposy+1],ax

; 2D mapping

        mov     ax,0a000h             ; Screen base
        mov     es,ax
        mov     di,Dest               ; offset 0 (Screen)
        mov     di,WORD PTR[di]
        shl     di,2                  ; *4
        mov     ax,PicSeg             ; Picture base
        add     ax,(768+32) SHR 4     ; skip the header+pal !!!!!
        mov     ds,ax

        mov     cx,Windowy            ; 80 lines
EVEN
BFill:  push    cx                    ; mov     gs,cx ; save CX
Bposy:  mov     dx,ypos               ; position en y*256
Bposx:  mov     cx,xpos               ; position en x*256


; calcul d'une ligne ...
Bpatch_it LABEL WORD
        REPT (Windowx)-1              ; 160 pixels width
        mov    bl,ch                  ; partie haute x
        mov    bh,dh                  ; partie haute y
        mov    al,[bx+YSINE]          ; prendre valeur sur map
        mov    ah,al                  ; doubler taille
        stosw                         ; afficher
        add    dx,bp                  ; increment y
        add    cx,si                  ; increment x
        ENDM
        mov    bl,ch
        mov    bh,dh
        mov    al,[bx+YSINE]
        mov    ah,al
        stosw


; passer … la ligne suivante … afficher
Bpat9:  add     WORD PTR cs:[Bposx+1],incy      ; posx + sin(O)
Bpat10: sub     WORD PTR cs:[Bposy+1],incx      ; posy - cos(O)

        IF (Larg-Windowx) NE 0
          add     di,(Larg-Windowx)*2 ; ligne suivante...
        ENDIF

        pop     cx                    ; mov  cx,gs ; restore CX
        dec     cx
        jnz     BFill
@@:


        pop     ds

        ret

BRotate_It ENDP


;==============================================================================

ROTA_TEXT ENDS

     END

