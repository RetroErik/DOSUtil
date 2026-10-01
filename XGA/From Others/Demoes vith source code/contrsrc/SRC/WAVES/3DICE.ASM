;**********************************************************
;* ICEBERG effect !!!!! (C) Type One 1994 / TFL-TDV Prod. *
;**********************************************************

INCLUDE PDFIK.INC ; DataFile Manager
INCLUDE VIDEO.INC ; Flamoot VGA SetUp
INCLUDE PLAYINFO.INC ; Player structures
INCLUDE KEYBOARD.INC ; keyboard macros

; declaration modŠle m‚moire
;----------------------------
.386
DGROUP GROUP _DATA,_BSS
ICE_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
          ASSUME CS:ICE_TEXT,DS:DGROUP
ICE_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------

_DATA SEGMENT

; Quelques constantes bien utiles ......

Larg = 160       ; hauteur de l'‚cran en pixels
Haut = 30        ; largeur de l'‚cran en pixels
Windowx = 160    ; largeur fenetre
Windowy = 30     ; hauteur fenetre

Screen1 = 0
Screen2 = ((160*2)*200/4)
Screen3 = ((160*2)*200/4*2)
Screen4 = ((160*2)*200/4*3)

;-- donnees pattern --
EXTRN _Datafile  : BYTE 
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'mandel.bin',0
Backname  BYTE 'backgrnd.raw',0
Curvname  BYTE 'curve.bin',0
Picparam  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Backname,0,0,0,,,0>

LenOFVline EQU (OFFSET laby48 - OFFSET laby49)
OpcodeSize EQU 5 ; SizeOf(mov WORD PTR[di+1234h],12h)
EVEN
HautTab LABEL WORD ; convertit hauteur en offset a jumper/patcher dans rout
 i=0
 REPT 64
 DW i
 i=(i+OpcodeSize)
 ENDM 

Xsize = 160   ; some constants
Ysize = 30
Meche = 10
Debut = 80 

Ytable LABEL WORD
       i = (2 + Meche) * Xsize
       REPT Ysize
       DW i
       i = i + Xsize
       ENDM

cumul_step_lo DD 0
cumul_step_hi DD 0
cumul_old_lo  DD 0
cumul_old_hi  DD 0


EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE

_DATA ENDS

; -- donn‚es non initialis‚es --
_BSS SEGMENT

EXTRN _FrameCounter     : WORD
EXTRN _SinusTbl         : WORD  ; table sinus*256
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

Termine  WORD ?        ; flag pour terminer !!!

EVEN
CurvSeg  WORD ?        ; segment of wave curve...

ALIGN 4
EVEN
Begin   = (Xsize*(2+Meche))
Overflow = Xsize
SizeBuf = (Xsize*(Ysize+2+Meche)+Overflow)
BufSeg  WORD ?         ; seg of buffer for flames
BufSeg2 WORD ?
BufPtr  WORD ?
BufPtr2 WORD ?
ALIGN 4
EVEN
Maxima DB Xsize DUP(?)

EVEN
WaveFlag WORD ?

EVEN                
CurvePtr   WORD ?       ; wave curve parameters 
CurveStep  WORD ?
SpirAngle  WORD ?       ; spiral angle
SpirRadius WORD ?       ;   "    radius
CircRadius WORD ?       ; circle radius

EVEN
Dest DW ?

EVEN
Backseg  WORD ?        ; seg for background
PicSeg   WORD ?        ; ptr vers segment pattern
TmpSeg   WORD ?        ; ptr Tmp ...
TmpOfs   WORD ?        ; OFFSET second map in Tmp
Temps    WORD ?

;-------- Flag d'autorisation ---------
Wave1  WORD ?
Wave2  WORD ?
Goutte WORD ?
Oxygen WORD ?
Spir   WORD ?
Circ   WORD ?
Plouf  WORD ?
WavTxt WORD ?
Mandel WORD ?

FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?

_BSS ENDS

ICE_TEXT SEGMENT
      EXTRN _GetRandom  : FAR
      EXTRN _Amorce     : FAR
      EXTRN _AveragePAL : FAR
      PUBLIC _StartIce

ALIGN
EVEN
_StartIce PROC FAR

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


         push    m320x200x256p
         call    _SetVGA
         add     sp,2  

         STARTUP
;--------------------------------------
         call    IceBerg             ; !!!!! iceberg part !!!!!
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

         leave                             ; restore stack
                                           ; mov sp,bp + pop bp
         retf                              ; C/C++ retirera le param 

_StartIce ENDP

;==============================================================================
;=============================== IceBerg part =================================
;==============================================================================

IceBerg PROC NEAR

;************ some macros ************

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

        mov    CurveStep,ax  ; CurveStep = factor * FrameCounter

        mov    _FrameCounter,0

        MPOP   eax,ebx,ecx,edx
;--------------------------------------------

ENDM



;====================================================

FADING   MACRO
         LOCAL NewFade,Faddi,Passer
; ---------- Fading -----------

         cmp     FadeFlag,255
         jb      NewFade

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      GoOut

         mov     _FadeON,0    ; don't set _TmpPal anymore ...
         jmp     Passer

NewFade: MPUSH   ax,cx

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
         mov     cx,CurveStep
         sub     cx,Delai             ; temps chargement

         test    cx,cx
         jnz     Faddi
         inc     cx
Faddi:   add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     Faddi
  
         MPOP    ax,cx
Passer:
         ENDM

;==============================================

UPDATE MACRO                 ; update variables & flags
       LOCAL   lbl1,lbl2

       MPUSH   ax,cx

; ------- maj clock -------
       mov     cx,CurveStep
lbl1:  inc     Temps        ; + 1/70 sec.
       dec     cx           ; "clock"
       jnz     lbl1


; ------- set effects -------
       mov     ax,Temps
       cmp     ax,5*70      ; 5 sec
       jl      lbl2
       mov     BYTE PTR cs:[Viscoz+1],3

       cmp     ax,10*70     ; 10 sec.
       jl      lbl2
       mov     Wave1,1      ; active 1st wave
       mov     BYTE PTR cs:[Viscoz+1],4

       cmp     ax,20*70     
       jl      lbl2
       mov     Plouf,1      ; active ploufs

       cmp     ax,24*70 ;30*70
       jl      lbl2
       mov     BYTE PTR cs:[Viscoz+1],6 
       mov     Circ,1       ; active big blub
       mov     Wave2,1      ; active 2nd wave

       cmp     ax,40*70
       jl      lbl2
       mov     BYTE PTR cs:[Viscoz+1],4
       mov     Goutte,0     ; no more gouttes
       mov     Spir,1       ; active Spir ...
       mov     Plouf,0      ; no more ploufs

       cmp     ax,50*70
       jl      lbl2
       mov     Spir,0
       mov     BYTE PTR cs:[Viscoz+1],3 ; - visqueux
       mov     WavTxt,1

       cmp     ax,50*70
       jl      lbl2
       mov     Spir,1

       cmp     ax,60*70
       jl      lbl2
       mov     BYTE PTR cs:[Viscoz+1],4
       mov     Goutte,1
       mov     Plouf,1

       cmp     ax,90*70
       jl      lbl2
       mov     Plouf,0
       mov     Spir,0

       cmp     ax,94*70
       jl      lbl2
       mov     Wave1,0
       mov     Wave2,0

       cmp     ax,95*70
       jl      lbl2
       mov     Mandel,1
       mov     Spir,1
       mov     Wave1,1
       mov     Wave2,1

       cmp     ax,100*70
       jl      lbl2
       mov     Plouf,1

lbl2:

       mov     Delai,0

       MPOP    ax,cx

       ENDM

;======================================================

DOEFFECT MACRO
       LOCAL   Nof,lbl1,lbl2,lbl3,lbl4,lbl5,lbl6,lbl7,lbl8,lbl9

       cmp     CurveStep,2
       jge     lbl1
       test    WaveFlag,1
       jz      Nof
lbl1:  call    Fluid               ; do fluid consistence

       cmp     CurveStep,2
       jl      lbl2
    
Nof:
       test    Goutte,1            ; can we do some "goutelettes" ?
       jz      lbl2
       call    Gouttes
  
lbl2:  xor     WaveFlag,1

       test    Wave1,1             ; 1st wave ?????
       jz      lbl3
       call    DoWave              ; do some perturbations (if we can)  
lbl3:
       test    Oxygen,1
       jz      lbl4
       call    Oxygene             ; some oxygenation ?????
lbl4:
       test    Circ,1              ; some circles ???
       jz      lbl5
       call    Circles 
lbl5:
       test    Spir,1              ; some spiral ?
       jz      lbl6
       call    Spiral
lbl6:
       test    Plouf,1             ; some ploufs ???
       jz      lbl7
       call    Ploufs
lbl7:
       test    WavTxt,1           
       jz      lbl8
       call    PutTxt              ; Put text !!!!!
lbl8:
       test    Mandel,1
       jz      lbl9
       call    PutMandel           ; Put MandelBrot !!!!!
lbl9:

       ENDM

;=======================================================

TESTEND  MACRO
         LOCAL NoFade

         MPUSH  eax,bx,es

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
         jb      NoFade                  ; to fade off ???

         mov     Termine,1

         cmp     FadePtr2,OFFSET _BlackPal
         je      NoFade

         mov     FadeFlag,0
         mov     eax,DWORD PTR[FadePtr2]
         mov     DWORD PTR[FadePtr1],eax   ; fade to black !!!!
         mov     ax,ds
         mov     FadePtr2+2,ax
         mov     FadePtr2,OFFSET _BlackPal

NoFade:

         MPOP    eax,bx,es

       ENDM

;=========================================================

;************************************


       pushad  
       MPUSH  ds,es,fs,gs


         mov     eax,_OfsinDta         ; OFFSET in Datafile
         mov     Picparam.OfsInPdf,eax
         mov     ax,_DATA              ; prepare for PDFIK call 
         mov     es,ax 
         mov     bx,OFFSET Picparam  
         pusha 
         call    PDFIK_ASM             ; call function 2 (extract+alloc)
         popa
         mov     ax,Picparam.BufSeg ; where is the file in mem ?  
         mov     Backseg,ax

         push    ds
         push    es
         mov     ax,Backseg
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


; * charger MandelBrot pic *
       mov     Picparam.DtaOfsFil,OFFSET Picname ; name of pic 2
       mov     eax,_OfsinDta         ; OFFSET in Datafile
       mov     Picparam.OfsInPdf,eax 
       mov     ax,DGROUP             ; prepare for PDFIK call
       mov     es,ax
       mov     bx,OFFSET Picparam
       pusha
       call    PDFIK_ASM             ; call function 2 (extract+alloc)
       popa
       mov     ax,Picparam.BufSeg    ; where is the file in mem ?
       mov     Picseg,ax             

       mov     eax,Picparam.NormSize ; taille file
       mov     TmpOfs,ax             ; stocker offset
       add     ax,ax
       shr     ax,4
       inc     ax
       mov     bx,ax                 ; memory requested

       mov     ah,48h                ; MALLOC
       xor     al,al
       int     21h
       mov     TmpSeg,ax             ; Segment address returned


       mov     Picparam.DtaOfsFil,OFFSET Curvname ; name of curve table
       mov     eax,_OfsinDta         ; OFFSET in Datafile
       mov     Picparam.OfsInPdf,eax 
       mov     ax,DGROUP             ; prepare for PDFIK call
       mov     es,ax
       mov     bx,OFFSET Picparam
       pusha
       call    PDFIK_ASM             ; call function 2 (extract+alloc)
       popa
       mov     ax,Picparam.BufSeg    ; where is the file in mem ?
       mov     CurvSeg,ax             


       mov     ah,48h                ; MALLOC
       mov     bx,(SizeBuf SHR 4)+1  ; memory requested
       int     21h
       mov     BufSeg,ax             ; Segment address returned
       mov     BufPtr,ax
       mov     ah,48h
       mov     bx,(SizeBuf SHR 4)+1
       int     21h
       mov     BufSeg2,ax
       mov     BufPtr2,ax 
        
       call   PutBack
       call   InitMap
;       call   _Amorce 

;*********************************************************
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

         mov     _FrameCounter,0
         mov     Delai,0
         xor     eax,eax   
;------------------------------------------
;*********************************************************

       mov     Termine,0 ; pas encore terminer !!!

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
;       mov     ax,_FrameCounter
;       mov     Delai,ax               ; Delai chargement

       VSYNC



;--------- init fading ----------
       mov     Temps,0
       mov     _FadeON,0
       mov     FadeFlag,0
       mov     FadePtr1,OFFSET _BlackPal  ; Black to pic for the beginning !!!
       mov     ax,ds
       mov     FadePtr1+2,ax
       mov     FadePtr2,32
       mov     ax,Backseg
       mov     FadePtr2+2,ax
;--------------------------------

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;*************** MAIN loop *****************
;--------------
EVEN
Main:


;***** 2nd page *****
Do_a_frame:
       mov  di,_WorkAdr
       cmp  WORD PTR[di+2],1 ; _WorkAdr->flag true (previous _NextAdr) ?
       je   NextFrame        ; then construct next frame

       NEXTSTEP              ; new step !!!

       FADING                ; macro for fading

       UPDATE                ; update flags,vars,counters
                             ; and set FrameCounter to 0

       TESTEND               ; test if end-pos ??? --> if yes fade off

       SHOWTIME 48

       call    ClearMap     ; clear Work-buffer (warning modify reg !!!)

       SHOWTIME 32

       DOEFFECT             ; do the <> effects and set some flags

       SHOWTIME 24

       call    PrintMap     ; project the map onto Work-buffer
       mov    di,_NextAdr   ; save adr of next buffer

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

       NEXTSTEP              ; new step !!!

       FADING                ; macro for fading !!!!

       UPDATE                ; set vars,counters,flags and
                             ; set FrameCounter to 0

       TESTEND               ; test if end-pos ???? --> if yes fade off

       SHOWTIME 48

       call    ClearMap            ; clear screen (warning modify reg. !!)

       SHOWTIME 32

       DOEFFECT                    ; call the <> effects and set some flags

       SHOWTIME 24

       call   PrintMap

       mov    bx,Dest
       mov    WORD PTR[bx+2],1     ; _NextAdr->flag = true

       SHOWTIME 0

       LOOP_UNTIL_KEY Main         ; wait a key else loop

GoOut:

;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

       FLUSH_KEYBUF                ; flush keyboard buffer !!!

        mov     _FadeON,0             ; to be sure ....

;----- EXIT -----

        STARTUP
        mov     ax,BufSeg2
        mov     es,ax
        mov     ah,49h
        int     21h
        mov     ax,BufSeg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

        mov     ax,CurvSeg
        mov     es,ax
        mov     ah,49h
        int     21h 
        mov     ax,TmpSeg
        mov     es,ax
        mov     ah,49h
        int     21h
        mov     ax,Picseg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h
        mov     ax,Backseg
        mov     es,ax
        mov     ah,49h
        int     21h

        MPOP    ds,es,fs,gs
        popad
        nop 
        ret

IceBerg ENDP

;***************************
;* Clear the Map on screen *
;***************************

ClearMap PROC NEAR

         mov  Dest,di          ; save pointer
         mov  di,WORD PTR[di]  ; _NextAdr->base
         add  di,(Debut+15)*(Xsize*2)/4
         mov  ax,0a000h
         mov  es,ax
         mov  dx,3c4h
         mov  ax,0f02h
         out  dx,ax           

         push dx
         mov  dx,3ceh
         mov  ax,4105h         ; mode VGA write 1
         out  dx,ax  

         push si
         push ds
         mov  ax,0a000h
         mov  ds,ax
         mov  si,Screen4+(Debut+15)*(Xsize*2)/4
         mov  cx,(Xsize*2)*42/4          ; restore 42 pixels of the background
         rep  movsb
         pop  ds
         pop  si

         mov  ax,4005h         ; mode VGA write 0
         out  dx,ax
         pop  dx
          
         xor  eax,eax
         mov  cx,(Xsize*2)*(64-42)/(4*4) ; clear screen
         rep  stosd

         ret

ClearMap ENDP

;*****************************************
;* Print the Map in False Goraud Shading *
;*****************************************
ALIGN
EVEN
PrintMap PROC NEAR

       pushad
       MPUSH ds,es,fs,gs

       mov  ax,BufPtr
       mov  fs,ax

       push ds
       push es
       pop  ds
       pop  es         ; xchg ds,es

       xor  edx,edx    ; clean edx
       xor  ecx,ecx    ; clean ecx
       xor  eax,eax    ; clean eax 

       mov  di,OFFSET Maxima
       mov  cx,Xsize/4 ; clear Maxima 
       rep  stosd
 
       i=0
       REPT 2
       LOCAL Affich,PrintMap
       mov  dx,3c4h
       mov  ax,02h+(3 SHL (i*2))*256       ; ie plane
       out  dx,ax  
       mov  bx,(Begin+i+(Xsize*(Ysize-1))) 
       mov  si,OFFSET laby49               ; offset rout layer 1
                                           ; Maxima = array for max. height

       xor  ax,ax   
       mov  cx,Ysize-1                     ; 30 layers
       EVEN                                ; align label
PrintMap:

       mov  di,es:[Dest]                   ; begin by the beginning
       mov  di,WORD PTR es:[di]            ; _WorkAdr->base
       add  di,Debut*(Xsize*2)/4
       push cx 
       mov  cx,(Xsize*2)/4
       EVEN                                ; align label
Affich: 
       mov  al,BYTE PTR fs:[bx]            ; get height
       add  al,32                          ; get value between 0 - 63
       mov  dl,BYTE PTR es:[Maxima+ecx*2+i-2]; get our current max height
       cmp  al,dl                          ; compare with maximum height
       jle  @F
       mov  bp,WORD PTR es:[HautTab+eax*2] ; get coord*5
       mov  BYTE PTR es:[Maxima+ecx*2+i-2],al; we have a max now !!!
       xor  dh,dh                          ; clean dx ...
       mov  dx,WORD PTR es:[HautTab+edx*2] ; get max*5
       add  dx,si                          ; add base of rout 
       mov  al,BYTE PTR cs:[si+bp]         ; save mov or ret opcode 
       mov  BYTE PTR cs:[si+bp],0C3h       ; do a ret instead of mov ....
       call dx                             ; call the right rout 
       mov  BYTE PTR cs:[si+bp],al         ; replace the mov (0C6h)
@@:    add  bx,2 
       inc  di
       cmp  BYTE PTR es:[Maxima+ecx*2+i-2],0
       jz   @F
       dec  BYTE PTR es:[Maxima+ecx*2+i-2] ; update maximum height for next
@@:    dec  cx                             ; layer 
       jnz  Affich                         ; better than loop on 386-486

       pop  cx

       sub  bx,Xsize*2                     ; previous line
       add  si,LenOFVline                  ; ajust offset for next layer 
       dec  cx
       jnz  PrintMap

       i=i+1
       ENDM

       MPOP ds,es,fs,gs                    ; restore DS
       popad
       nop
       ret

PrintMap ENDP

;*******************************
;* calculate Fluid consistence *
;*******************************
ALIGN   ; effect (C) ARM/Iguana (doc taken from tin !!!)
EVEN
Fluid PROC NEAR

       MPUSH ax,cx,di,es,fs

       mov   ax,BufPtr2     
       mov   es,ax        ; U[1]
       mov   ax,BufPtr  
       mov   fs,ax        ; U[0]

; first do the fluid consistence !!!!!!!

       mov   di,Xsize*(Meche+2)

       mov   cx,Ysize
EVEN
@@:    push  cx
Viscoz LABEL BYTE
       mov   cl,2 ; 1st value     
       REPT  Xsize
       LOCAL Yopi,Yopi2

; u[1,x,y] = (u[0,x-1,y] + u[0,x+1,y] + u[0,x,y-1] + u[0,x,y+1)/2 - u[1,x,y]               

       mov   al,BYTE PTR fs:[di-1]       ; u(t)
       add   al,BYTE PTR fs:[di+1]
       add   al,BYTE PTR fs:[di-Xsize]
       add   al,BYTE PTR fs:[di+Xsize]
       sar   al,1
       sub   al,BYTE PTR es:[di]         ; u(t-1)

; u[1,x,y] = 1/2^n * u[1,x,y]                  

       mov   ah,al
       sar   ah,cl                       ; n = 6 !!!
       sub   al,ah

       cmp   al,-32
       jge   Yopi
       mov   al,-32
Yopi:  cmp   al,31
       jle   Yopi2
       mov   al,31
Yopi2: stosb
     
       ENDM  

       pop   cx
       dec   cx
       jnz   @B    

finish:

;------ swap the arrays !!! ------

       mov   ax,BufPtr     ; swap U[0] and U[1]
       xchg  ax,BufPtr2
       mov   BufPtr,ax

       MPOP  ax,cx,di,es,fs

       ret

Fluid ENDP


;*******************
;* do 1 or 2 waves *
;*******************
ALIGN   
EVEN
DoWave PROC NEAR

       MPUSH  eax,cx,si,di,es,fs

       mov    ax,CurvSeg
       mov    fs,ax                     ; segment to reference curve

       mov    ax,BufPtr
       mov    es,ax 

;  do the "perturbation" !!!!!

       xor    eax,eax   
  
       xor    si,si                     ; trajectoire wave
       add    si,CurvePtr

       mov    cx,CurveStep              ; what is the step ???
       test   cx,cx                     ; warning if = 0 !!!
       jnz    Yopihe
       mov    cx,1

Yopihe:

; 1st wave !!!!!!

       mov    ax,WORD PTR fs:[si+2]     ; y
       mov    di,WORD PTR[Ytable+eax*2] ; y*160
       add    di,WORD PTR fs:[si]       ; + x
                                        ; DI contains position on the map !!!!!

       mov    al,BYTE PTR es:[di]
       sub    al,16                     ; - tranchant
       cmp    al,-32
       jge    @F
       mov    al,-32
@@:    mov    BYTE PTR es:[di],al

; 2nd wave !!!!!!

       test   Wave2,1
       jz     no2ndWave

       mov    ax,WORD PTR fs:[si+512+2] ; y
       mov    di,WORD PTR[Ytable+eax*2] ; y*160
       add    di,WORD PTR fs:[si+512]   ; + x
                                        ; DI contains position on the map !!!!!

       mov    al,BYTE PTR es:[di]
       sub    al,16                     ; - tranchant
       cmp    al,-32
       jge    @F
       mov    al,-32
@@:    mov    BYTE PTR es:[di],al

no2ndWave:

       add    si,4

       add    CurvePtr,4                ; maj counter             

       dec    cx
       jnz    Yopihe

       and    CurvePtr,4095

       MPOP   eax,cx,si,di,es,fs
       ret

DoWave ENDP

ALIGN
EVEN
;*******************
; oxygene !!!! ....  
;*******************
Oxygene PROC NEAR                     ; oxygenator

      MPUSH ax,bx,cx,si,es

      mov   ax,BufPtr
      mov   es,ax

      call  _GetRandom
      mov   bx,ax
      shr   bx,9

      mov   cx,Xsize                  ; calculate alea-lines
      mov   si,Xsize*(Meche+2)
EVEN 
oxy:  call  _GetRandom 
      cmp   ax,10000
      ja    @F
      call  _GetRandom
      mov   bx,ax
      shr   bx,9
@@:   sub   bl,32                     ; get value between -31 & 31
      sar   bl,2
      mov   BYTE PTR es:[si],bl
      mov   BYTE PTR es:[si+Xsize],bl
      inc   si
      dec   cx
      jnz   oxy                       ; loop oxy

      MPOP  ax,bx,cx,si,es
      ret

Oxygene ENDP


ALIGN
EVEN
;************************
; gouttes d'eau !!!! ....  
;************************
Gouttes PROC NEAR                     ; gouttes d'eau

      MPUSH eax,bx,dx,si,es

      mov   ax,BufPtr
      mov   es,ax

      xor   eax,eax

      call  _GetRandom                ; Random(Y)
      xor   dx,dx
      mov   bx,32768/30
      div   bx
      mov   si,WORD PTR[Ytable+eax*2] 

      call  _GetRandom                ; Random(X)
      xor   dx,dx
      mov   bx,32768/160
      div   bx
      add   si,ax
       
      mov   bl,BYTE PTR es:[si]
      call  _GetRandom                ; "poids" goutte
      sar   ax,11
      sub   bl,al                     ; --> perturbation(X,Y)
      cmp   bl,-32
      jge   no_over
      mov   bl,-32
no_over:
      mov   BYTE PTR es:[si],bl
 
      MPOP  eax,bx,dx,si,es
      ret

Gouttes ENDP

;**************
;* Tourbillon *
;**************
ALIGN
EVEN
Spiral PROC NEAR    ; !!!!! Gros bug qui donne bien !!!!!

       MPUSH eax,bx,cx,dx,si,es

       mov  ax,BufPtr
       mov  es,ax

       xor  eax,eax
       mov  ax,SpirAngle  ; take current "angle"
       mov  bx,WORD PTR[_SinusTbl+eax*2+256] ; -cos(theta)
       neg  bx 
       mov  ax,WORD PTR[_SinusTbl+eax*2]     ; sin(theta)
       imul SpirRadius    ; multiplied by radius
     ;  sar  dx,8+3
       sar  ax,8+3        ; /256 !!!!
       add  ax,15         ; middle of y axis
       js   SpirOver
       cmp  ax,30         ; check overflow ???
       jge  SpirOver
       mov  si,WORD PTR[Ytable+eax*2] ; take corresponding y 
       mov  ax,bx
       imul SpirRadius    ; -cos*radius
   ;    sar  dx,8 
       sar  ax,8          ; /256
       add  ax,80         ; middle of x axis
       js   SpirOver
       cmp  ax,160        ; check overflow ???
       jge  SpirOver
       add  si,ax         ; position+x

       mov  al,BYTE PTR es:[si]
       sub  al,16         ; cut water !!!!
       cmp  al,-32
       jge  @F
       mov  al,-32
@@:    mov  BYTE PTR es:[si],al                  
     
SpirOver:
  
       mov  cx,CurveStep  ; step !!     
       test cx,cx
       jnz  @F
       mov  cx,1
@@:
       inc  SpirAngle
       and  SpirAngle,511
       inc  SpirRadius
       and  SpirRadius,511 
       dec  cx
       jnz  @B

       MPOP eax,bx,cx,dx,si,es        

       ret

Spiral ENDP

;***********
;* Circles *
;***********
ALIGN
EVEN
;------ Bresenham's circle algo -------

Circles PROC NEAR   ; --> draw circle in the map coord 80,15 ....

       MPUSH    eax,bx,cx,edx,si,di,es
       
       mov      ax,BufPtr
       mov      es,ax

       mov      cx,CurveStep
       test     cx,cx
       jnz      DoCircles
       mov      cx,1
DoCircles: 
       push     cx

       xor      eax,eax    ; x = 0
       xor      edx,edx    ; y = radius
       mov      dx,CircRadius; with x = 0 and y = radius, first point is at 270ø
       inc      CircRadius
       cmp      CircRadius,255
       jl       @F
       mov      Circ,0     ; disable circles
@@:

       mov      di,dx
       sal      di,1       
       sub      di,3
       neg      di         ; d = 3 - (2*radius) --> init the decision var

Circl: cmp      ax,dx      ; while (x<y)
       jg       OutLoop

       push     dx
       sar      dx,1          
   
; eigth-point symmetry
       cmp      dx,13
       jg       NoPoint
       cmp      ax,79
       jg       NoPoint
       
       push     si
       mov      cx,WORD PTR[Ytable+edx*2] ; y * 160
       sub      cx,(Meche+2)*160
       mov      si,ax                     ; + x
       add      si,cx
       mov      bl,BYTE PTR es:[si+160*(14+Meche+2)+80] ; plot(80+x,15+y)
       sub      bl,2
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si+160*(14+Meche+2)+80],bl
       mov      si,ax
       sub      si,cx
       mov      bl,BYTE PTR es:[si+160*(14+Meche+2)+80] ; plot(80+x,15-y)
       sub      bl,2
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si+160*(14+Meche+2)+80],bl
       mov      si,ax
       neg      si
       sub      si,cx
       mov      bl,BYTE PTR es:[si+160*(14+Meche+2)+80] ; plot(80-x,15-y)
       sub      bl,2
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si+160*(14+Meche+2)+80],bl
       mov      si,cx
       sub      si,ax
       mov      bl,BYTE PTR es:[si+160*(14+Meche+2)+80] ; plot(80-x,15+y)
       sub      bl,2
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si+160*(14+Meche+2)+80],bl
       mov      cx,WORD PTR[Ytable+eax*2] ; x * 160
       sub      cx,(Meche+2)*160
       mov      si,dx
       sub      si,cx
       mov      bl,BYTE PTR es:[si+160*(14+Meche+2)+80] ; plot(80+y,15-x)
       sub      bl,2
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si+160*(14+Meche+2)+80],bl
       mov      si,dx
       neg      si
       sub      si,cx
       mov      bl,BYTE PTR es:[si+160*(14+Meche+2)+80] ; plot(80-y,15-x)
       sub      bl,2
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si+160*(14+Meche+2)+80],bl
       mov      si,cx
       sub      si,dx
       mov      bl,BYTE PTR es:[si+160*(14+Meche+2)+80] ; plot(80-y,15+x)
       sub      bl,2
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si+160*(14+Meche+2)+80],bl
       mov      si,cx
       add      si,dx
       mov      bl,BYTE PTR es:[si+160*(14+Meche+2)+80] ; plot(80+y,15+x)
       sub      bl,2
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si+160*(14+Meche+2)+80],bl
       pop      si

NoPoint: pop    dx

       test     di,di      ; if(d<0)
       jns      @F         ; don't decrement y
       add      di,6
       mov      si,ax
       sal      si,2
       add      di,si      ; d += (4 * x) + 6  --> update decision variable 
       inc      ax         ; increment x   
  
       jmp      Circl      ; end of while (x < y)
  
@@:    add      di,10
       mov      si,ax
       sub      si,dx
       sal      si,2
       add      di,si      ; d += 4*(x - y) + 10 --> """""
       dec      dx         ; decrement y
       inc      ax         ; increment x
              
       jmp      Circl      ; end of while (x < y)   
             
OutLoop:
       
       pop      cx
       dec      cx
       jnz      DoCircles
      

       MPOP     eax,bx,cx,edx,si,di,es

       ret

Circles ENDP

ALIGN
EVEN
;************************
; petits ploufs !!!! ....  
;************************
Ploufs PROC NEAR                      ; petits ploufs

      MPUSH ax,bx,cx,dx,si

      cmp   cs:[Encore],0             ; new plouf ???? 
      jg    @F

      call  _GetRandom                ; Random(Radius)
      xor   dx,dx
      mov   si,32768/32               ; rayon 32 au max !!! 
      div   si
      push  ax  
       
      call  _GetRandom                ; Random(Y)
      xor   dx,dx
      mov   si,32768/30
      div   si
      mov   bx,ax

      call  _GetRandom                ; Random(X)
      xor   dx,dx
      mov   si,32768/160
      div   si
      pop   dx       

; AX = x  BX = y  DX = radius

      mov   cs:[Encore],dx            ; nb steps ...
      mov   cs:[Rayon],0
      mov   cs:[Xcoord],ax
      mov   cs:[Ycoord],bx 

@@:   
 
      mov   cx,CurveStep
      test  cx,cx
      jnz   @F
      mov   cx,1
@@:
      mov   ax,cs:[Xcoord]
      mov   bx,cs:[Ycoord]
      mov   dx,cs:[Rayon]
      call  Cirk                      ; do circle

      inc   cs:[Rayon]                ; maj local var ...
      dec   cs:[Encore]
      dec   cx
      jnz   @B  
       
      MPOP  ax,bx,cx,dx,si
      ret

Encore DW 0
Rayon  DW ?
Xcoord DW ?
Ycoord DW ?

Ploufs ENDP



;****************************
;* general rout for Circles *
;****************************
ALIGN
EVEN
;------ Bresenham's circle algo -------

Cirk   PROC NEAR   ; --> draw circle in the map coord x,y radius r ....

; AX = x   BX = y   DX = radius

       MPUSH    ax,ebx,cx,dx,si,di,es
       
       mov      cs:[Xcenter],ax ; save coordinates
       mov      cs:[Ycenter],bx 

       mov      ax,BufPtr
       mov      es,ax

       xor      ebx,ebx

       xor      ax,ax      ; x = 0   y = radius (dx !!!)
                           ; with x = 0 and y = radius, first point is at 270ø

       mov      di,dx
       sal      di,1       
       sub      di,3
       neg      di         ; d = 3 - (2*radius) --> init the decision var

Circl: cmp      ax,dx      ; while (x<y)
       jg       OutLoop

       push     dx
       sar      dx,1          
   
; eigth-point symmetry
       
       mov      bx,cs:[Xcenter]
       add      bx,ax
       mov      cs:[xxcp],bx
       mov      bx,cs:[Ycenter]
       add      bx,ax
       mov      cs:[yxcp],bx
       mov      bx,cs:[Xcenter]
       sub      bx,ax
       mov      cs:[xxcm],bx
       mov      bx,cs:[Ycenter]
       sub      bx,ax
       mov      cs:[yxcm],bx
       mov      bx,cs:[Xcenter]
       add      bx,dx
       mov      cs:[xycp],bx
       mov      bx,cs:[Ycenter]
       add      bx,dx
       mov      cs:[yycp],bx
       mov      bx,cs:[Xcenter]
       sub      bx,dx
       mov      cs:[xycm],bx
       mov      bx,cs:[Ycenter]
       sub      bx,dx
       mov      cs:[yycm],bx    

       push     si

       mov      bx,cs:[yycp]
       cmp      bx,29
       jg       Next1
       cmp      bx,0
       jl       Next1
       mov      bx,cs:[xxcp]
       cmp      bx,159
       jg       Next1
       cmp      bx,0
       jl       Next1  

; si ok .........
       mov      bx,cs:[yycp]
       mov      si,WORD PTR[Ytable+ebx*2] ; y * 160
       add      si,cs:[xxcp]              ; + x
       mov      bl,BYTE PTR es:[si]       ; plot(x,y)
       dec      bl
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si],bl

Next1:
       mov      bx,cs:[yycm]
       cmp      bx,29
       jg       Next2
       cmp      bx,0
       jl       Next2
       mov      bx,cs:[xxcp]
       cmp      bx,159
       jg       Next2
       cmp      bx,0
       jl       Next2  

; si ok .........
       mov      bx,cs:[yycm]
       mov      si,WORD PTR[Ytable+ebx*2] ; y * 160
       add      si,cs:[xxcp]              ; + x 
       mov      bl,BYTE PTR es:[si]       ; plot(x,y)
       dec      bl
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si],bl

Next2:
       mov      bx,cs:[yycp]
       cmp      bx,29
       jg       Next3
       cmp      bx,0
       jl       Next3
       mov      bx,cs:[xxcm]
       cmp      bx,159
       jg       Next3
       cmp      bx,0
       jl       Next3  

; si ok .........
       mov      bx,cs:[yycp]
       mov      si,WORD PTR[Ytable+ebx*2] ; y * 160
       add      si,cs:[xxcm]              ; + x
       mov      bl,BYTE PTR es:[si]       ; plot(x,y)
       dec      bl
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si],bl

Next3:
       mov      bx,cs:[yycm]
       cmp      bx,29
       jg       Next4
       cmp      bx,0
       jl       Next4
       mov      bx,cs:[xxcm]
       cmp      bx,159
       jg       Next4
       cmp      bx,0
       jl       Next4  

; si ok .........
       mov      bx,cs:[yycm]
       mov      si,WORD PTR[Ytable+ebx*2] ; y * 160
       add      si,cs:[xxcm]              ; + x
       mov      bl,BYTE PTR es:[si]       ; plot(x,y)
       dec      bl
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si],bl

Next4:
       mov      bx,cs:[yxcp]
       cmp      bx,29
       jg       Next5
       cmp      bx,0
       jl       Next5
       mov      bx,cs:[xycp]
       cmp      bx,159
       jg       Next5
       cmp      bx,0
       jl       Next5  

; si ok .........
       mov      bx,cs:[yxcp]
       mov      si,WORD PTR[Ytable+ebx*2] ; y * 160
       add      si,cs:[xycp]              ; + x
       mov      bl,BYTE PTR es:[si]       ; plot(x,y)
       dec      bl
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si],bl

Next5:
       mov      bx,cs:[yxcm]
       cmp      bx,29
       jg       Next6
       cmp      bx,0
       jl       Next6
       mov      bx,cs:[xycp]
       cmp      bx,159
       jg       Next6
       cmp      bx,0
       jl       Next6  

; si ok .........
       mov      bx,cs:[yxcm]
       mov      si,WORD PTR[Ytable+ebx*2] ; y * 160
       add      si,cs:[xycp]              ; + x
       mov      bl,BYTE PTR es:[si]       ; plot(x,y)
       dec      bl
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si],bl

Next6:
       mov      bx,cs:[yxcp]
       cmp      bx,29
       jg       Next7
       cmp      bx,0
       jl       Next7
       mov      bx,cs:[xycm]
       cmp      bx,159
       jg       Next7
       cmp      bx,0
       jl       Next7  

; si ok .........
       mov      bx,cs:[yxcp]
       mov      si,WORD PTR[Ytable+ebx*2] ; y * 160
       add      si,cs:[xycm]              ; + x
       mov      bl,BYTE PTR es:[si]       ; plot(x,y)
       dec      bl
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si],bl

Next7:
       mov      bx,cs:[yxcm]
       cmp      bx,29
       jg       Next8
       cmp      bx,0
       jl       Next8
       mov      bx,cs:[xycm]
       cmp      bx,159
       jg       Next8
       cmp      bx,0
       jl       Next8  

; si ok .........
       mov      bx,cs:[yxcm]
       mov      si,WORD PTR[Ytable+ebx*2] ; y * 160
       add      si,cs:[xycm]              ; + x
       mov      bl,BYTE PTR es:[si]       ; plot(x,y)
       dec      bl
       cmp      bl,-32
       jge      @F
       mov      bl,-32
@@:    mov      BYTE PTR es:[si],bl


Next8:


NoPoint:
       pop      si 
       pop      dx

       test     di,di      ; if(d<0)
       jns      @F         ; don't decrement y
       add      di,6
       mov      si,ax
       sal      si,2
       add      di,si      ; d += (4 * x) + 6  --> update decision variable 
       inc      ax         ; increment x   
  
       jmp      Circl      ; end of while (x < y)
  
@@:    add      di,10
       mov      si,ax
       sub      si,dx
       sal      si,2
       add      di,si      ; d += 4*(x - y) + 10 --> """""
       dec      dx         ; decrement y
       inc      ax         ; increment x
              
       jmp      Circl      ; end of while (x < y)   
             
OutLoop:
       
       MPOP     ax,ebx,cx,dx,si,di,es

       ret

Xcenter DW ?
Ycenter DW ?
xxcp    DW ?
yxcp    DW ?
xxcm    DW ?
yxcm    DW ?
xycp    DW ?
yycp    DW ?
xycm    DW ?
yycm    DW ?    

Cirk   ENDP

;******************
;* Put BackGround *
;******************

ALIGN
EVEN
PutBack PROC NEAR
 
        MPUSH ax,cx,dx,ds,es

        mov   dx,3c8h
        xor   al,al
        out   dx,al
        inc   dl
        mov   cx,768
@@:     out   dx,al          ; set screen to black
        dec   cx
        jnz   @B 

        VSYNC

        mov   ax,Backseg
        mov   ds,ax
        mov   si,768+32
        mov   ax,0a000h
        mov   es,ax
 

        i = 0
        REPT  4
        mov   dx,3c4h   ; select right bitplane
        mov   ax,02h+(1 SHL i)*256
        out   dx,ax

        xor   di,di  

        mov   cx,320*138/4    ; background is 320x138 pixels
@@:     lodsb           ; copy to 4 page in videomem !!!
        mov   BYTE PTR es:[Screen2+di],al
        mov   BYTE PTR es:[Screen3+di],al
        mov   BYTE PTR es:[Screen4+di],al              
        stosb
        add   si,3
        dec   cx
        jnz   @B

        sub   si,320*138-1

        i = i + 1
        ENDM

        MPOP  ax,cx,dx,ds,es

        ret

PutBack ENDP

;***********
;* Put TXT *
;***********

ALIGN
EVEN
PutTxt PROC NEAR

       MPUSH   eax,cx,si,di,es

       mov     cx,CurveStep       
       sub     WORD PTR cs:[Pwait],cx  ; maj pause 
       cmp     WORD PTR cs:[PWait],0   ; doit-on-printer ????
       jg      Passer

       mov     ax,BufPtr    ; set es to MAP
       mov     es,ax
       mov     di,(2+Meche)*Xsize ; debut map ....
       
       mov     al,cs:[Intensity]
       mov     ah,al        ; copy intensity in all EAX !!!
       mov     bx,ax
       shl     eax,16
       mov     ax,bx
       cld

; take the right routine .....
       mov     si,cs:[RoutPtr]
       cmp     si,OFFSET Rout+16
       jae     Passer
       add     di,cs:[si]   ; centrage bitmap

       call    WORD PTR cs:[si+2]  ; call routine ...

       cmp     cs:[Intensity],15   ; trop haut ???
       jge     NoMonter
       cmp     cs:[Intensity],-7   ; trop bas ???
       jle     NoMonter

       mov     ax,WORD PTR cs:[CurPause]
       mov     WORD PTR cs:[Pause],ax

       mov     ax,cs:[Incr]
       mov     cx,CurveStep
       test    cx,cx
       jnz     @F
       mov     cx,1         
@@:    add     WORD PTR cs:[Comp],ax ; elever/baisser 
       dec     cx
       jnz     @B

NoMonter:
       mov     cx,CurveStep
       sub     WORD PTR cs:[Pause],cx ; pause ....
       cmp     WORD PTR cs:[Pause],0
       jg      Passer
       mov     ax,cs:[CurPause]
       xchg    ax,cs:[CurPause+2]     ; swap lever/baisser pauses
       mov     cs:[CurPause],ax
       neg     cs:[Incr]
       mov     ax,cs:[Incr]
       add     WORD PTR cs:[Comp],ax  ; rabaisser/relever 1 fois     
 
       inc     cs:[NbSwap]            ; inc nb swaps ...
       cmp     cs:[NbSwap],2
       jb      Passer                 

       mov     cs:[NbSwap],0
       mov     WORD PTR cs:[Comp],0     ; remise … 0 du niveau ... 
       mov     WORD PTR cs:[PWait],70*2 ; nouvelle lettre si monte et descendu
       add     WORD PTR cs:[RoutPtr],4  ; next lettre

Passer:

       MPOP    eax,cx,si,di,es 

       ret

wavtxt1:
       INCLUDE wavtxt1.asm
       ret

wavtxt2:
       INCLUDE wavtxt2.asm
       ret

wavtxt3:
       INCLUDE wavtxt3.asm 
       ret

wavtxt4:
       INCLUDE wavtxt4.asm
       ret

Comp      DB 0
Intensity DB 0
NbSwap    DB 0

EVEN
PWait     DW 0
Pause     DW 0
Incr      DW 64
CurPause  DW 70*5,70
RoutPtr   DW OFFSET Rout
Rout      DW 15+5*160,OFFSET wavtxt3
          DW 40+5*160,OFFSET wavtxt1
          DW 45+5*160,OFFSET wavtxt2
          DW 40+5*160,OFFSET wavtxt4

PutTxt ENDP

;******************
;* Put MandelBrot *
;******************

PutMandel PROC NEAR

          MPUSH   ax,cx,bx,dx,si,di,ds,es

          cmp     WORD PTR cs:[MDelay],5*70
          jge     EndMandel

          mov     ax,BufPtr    ; set es to MAP
          mov     es,ax
          mov     di,(2+Meche)*Xsize ; debut map ....

          mov     cx,CurveStep
          mov     cs:[NbStep],cx
          push    cx
          mov     dx,Picseg
          mov     bx,TmpOfs
          mov     ax,TmpSeg
          mov     ds,ax
          xor     si,si
          add     di,40+5*160 

          INCLUDE mandel.asm

          pop     cx

          cmp     BYTE PTR cs:[Morph],63
          jge     @F

          test    cx,cx
          jnz     Rattrap
          mov     cx,1
Rattrap:
          push    cx

          xor     si,si
          mov     es,dx       ; set to original map
          xor     di,di
          mov     cx,bx       ; nb of bytes ...
ToMorph:  mov     al,es:[di]
          add     BYTE PTR ds:[si+bx],al
          adc     BYTE PTR ds:[si],0   ; carry
          add     BYTE PTR ds:[si+bx],al
          adc     BYTE PTR ds:[si],0   ; carry
          add     BYTE PTR ds:[si+bx],al
          adc     BYTE PTR ds:[si],0   ; carry
          add     BYTE PTR ds:[si+bx],al
          adc     BYTE PTR ds:[si],0   ; carry
          inc     si
          inc     di
          dec     cx
          jnz     ToMorph

          inc     BYTE PTR cs:[Morph]  ; step + 1

          pop     cx
          dec     cx
          jnz     Rattrap

          jmp     SkipCompte

@@:       mov     cx,WORD PTR cs:[NbStep]
          test    cx,cx
          jnz     RatPause
          mov     cx,1
RatPause:
          inc     WORD PTR cs:[MDelay]
          dec     cx
          jnz     RatPause

SkipCompte:

EndMandel:
          MPOP    ax,cx,bx,dx,si,di,ds,es

          ret

Morph     DB 0
EVEN
MDelay    DW 0
NbStep    DW 0

PutMandel ENDP

ALIGN
EVEN
InitMap PROC NEAR

       MPUSH eax,cx,di,es

;---- init flags d'autorisation ----
       mov  Goutte,1
       mov  Wave1,0
       mov  Wave2,0
       mov  Oxygen,0  
       mov  Spir,0
       mov  Circ,0
       mov  Plouf,0
       mov  WavTxt,0
       mov  Mandel,0
;----                ----
       mov  CurvePtr,0
       mov  SpirAngle,0
       mov  SpirRadius,0
       mov  CircRadius,0
       mov  WaveFlag,1 

       mov  ax,TmpSeg
       mov  es,ax
       xor  di,di
       mov  cx,TmpOfs
       shr  cx,1
       xor  eax,eax
       rep  stosd      ; clean TmpMap

       push ds
       pop  es
       xor  eax,eax    ; clean eax 
       mov  cx,Xsize/4
       mov  di,OFFSET Maxima
       rep  stosd      ; clean maxima buffer (ES=Old DS !!!)
       mov  ax,BufSeg
       mov  es,ax
       mov  cx,(SizeBuf)/4
       xor  eax,eax
       xor  di,di
       rep  stosd      ; clean map buffer
       mov  ax,BufSeg2
       mov  es,ax
       mov  cx,(SizeBuf)/4
       xor  eax,eax
       xor  di,di
       rep  stosd

       MPOP eax,cx,di,es

       ret

InitMap ENDP

;----- VFAST Line !!!! - Self modifying Pregenerated code - --------

;lably49:
 INCLUDE vlin.inc

ICE_TEXT ENDS

 END
