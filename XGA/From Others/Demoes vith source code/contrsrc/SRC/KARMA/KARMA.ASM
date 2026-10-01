;******************************************************************
;* Karma's part: eyes effects --> Express contribution to Wired94 *
;******************************************************************
;       Autres includes : sincos.dw , mul320tb.inc , memoire.inc (malloc)
;       Loade digi.byt (64768 bytes)

	INCLUDE  PDFIK.INC
	INCLUDE  VIDEO.INC
        INCLUDE  PLAYINFO.INC
        INCLUDE  KEYBOARD.INC        ; lotsa macros

;--------------------------------------------------------------------------
;                          Structure m‚moire ...
;--------------------------------------------------------------------------
.386
	DGROUP GROUP _DATA, _BSS
	KARMA_TEXT SEGMENT DWORD PUBLIC USE16 'CODE'
                ASSUME cs:KARMA_TEXT, ds:_DATA3, fs:DGROUP
	KARMA_TEXT ENDS
	_DATA SEGMENT DWORD PUBLIC USE16 'DATA'
	_DATA ENDS
	_BSS SEGMENT DWORD PUBLIC USE16 'BSS'
	_BSS ENDS
        _DATA3 SEGMENT DWORD PRIVATE USE16 'FAR_DATA'
        _DATA3 ENDS
;--------------------------------------------------------------------------

SC_INDEX       = 3c4h      ;Registre d'index du contr“leur du s‚quenceur
SC_MAP_MASK    = 2                          ;Num‚ro du registre Map Mask
SC_MEM_MODE    = 4                   ;Num‚ro dy registre de mode m‚moire
GC_INDEX       = 3ceh          ;Registre d'index du contr“leur graphique
GC_READ_MAP    = 4                          ;Num‚ro du registre Read Map
GC_GRAPH_MODE  = 5                 ;Num‚ro du registre de mode graphique
GC_MISCELL     = 6                            ;Num‚ro du registre divers
CRTC_INDEX     = 3d4h            ;Registre d'index du contr“leur d'‚cran
CC_MAX_SCAN    = 9     ;Num‚ro du registre du maximum de lignes balay‚es
CC_START_HI    = 0Ch                        ;Num‚ro du registre Hi_Start
CC_UNDERLINE   = 14h                 ;Num‚ro du registre de soulignement
CC_MODE_CTRL   = 17h             ;Num‚ro du registre de contr“le de mode
DAC_WRITE_ADR  = 3C8h                                 ;Adresse DAC Write
DAC_READ_ADR   = 3C7h                                  ;Adresse DAC Read
DAC_DATA       = 3C9h                           ;Registre de donn‚es DAC
VERT_RETRACE   = 3DAh                       ;registre d'‚tat d'entr‚e #1
PIXX           = 320                             ;R‚solution horizontale

  Larg=320
  Haut=200
  Screen1 = 0
  Screen2 = (Larg*Haut/4)
  Screen3 = ((Larg*Haut/4)*2)
;***************************************************************
_DATA3 segment
;-----------------------table des sinus/cosinus--------------------
include   sincos.dw
;--------------donnees mode tweaked--------------------------------
vio_seg dw 0a000h
pv      db 1
pi      db 0
;--------------table de mul par 320--------------------------------
mul320tb:
include mul320tb.inc
;--------------donnees disto---------------------------------------
decal1 db 0
decal2 db 64

picture DW ?  ; pteur sur segment pic ...
CurStep DW ?  ; step for the distort...
Dest    DW ?  ; working screen

;---- param pour synchro avec zizik ----
EVEN
DebSong  WORD ?
FinSong  WORD ?

;---- param pour fading ----
Timeleft  WORD ?        ; temps restant pour execution
FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?
Termine  WORD 0 ;?        ; flag pour terminer !!!

cumul_step_lo DD 0
cumul_step_hi DD 0
cumul_old_lo  DD 0
cumul_old_hi  DD 0

_DATA3 ends

_DATA SEGMENT

;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'digi.byt',0  ; nom pic ...
Picparam  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname,0,0,0,,,0>

EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE


_DATA ENDS

_BSS SEGMENT

	EXTRN _FrameCounter     : WORD
	EXTRN _ExitDemo         : WORD
	EXTRN _CPUtime          : WORD
	EXTRN _StartAdr         : WORD
	EXTRN _WorkAdr          : WORD
	EXTRN _NextAdr          : WORD
	EXTRN _Triple           : WORD
	EXTRN _SyncFlag         : WORD

        ;!!!!!!!!!! sync music !!!!!!!!!!
        EXTRN _MP               : DWORD ; extern ModulePlayer * MB
        EXTRN _ReplayInfo       : mpInformation

EXTRN _TmpPal           : BYTE
EXTRN _FadeON           : WORD

_BSS ENDS
;-----------------*-*-*-*********//////////**********-*-*-*--------
;******************************************************************
KARMA_TEXT   SEGMENT
     EXTRN _AveragePAL: FAR

	PUBLIC _KARMA
;******************************************************************
INCLUDE MEMOIRE.INC
ALIGN
EVEN
_KARMA      PROC FAR
;******************************************************************
;          MAIN--<\<\<\--MAIN--/>/>/>--MAIN                       *
;               _//// \\     _//// \\                             *
;              / //<   >\   / //<   >\                            *
;             <_/<__> <__> <_/<__> <__>                           *
;******************************************************************

FADEPAL MACRO
        LOCAL NewFade,Faddi,lbl1
;===================== Fade Palette ===========================

;;;;;;;;;; plante pas !!!!!!

         cmp     FadeFlag,255
         jb      NewFade

         mov     fs:_FadeON,0  ; plus fader ...

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      fin

         mov     fs:_FadeON,0    ; don't set _TmpPal anymore ...
         jmp     lbl1
NewFade: MPUSH   ax,cx
         mov     ax,FadeFlag  ; average Black-MyPal
         push    ax
         push    fs
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
         mov     fs:_FadeON,1 ;1            ; set new PAL during next VR !!!!
         mov     cx,fs:_FrameCounter
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     Faddi
         mov     cx,1
Faddi:   add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     Faddi
         MPOP    ax,cx
lbl1:

;;;;;;; plante pas !!!!!!

;==============================================================
ENDM

NEXTSTEP MACRO
        LOCAL lbl1

;------------ FrameCounter manip ------------
        MPUSH  eax,ebx,ecx,edx

        mov    cx,fs:_FrameCounter
        test   cx,cx
        jnz    lbl1
        mov    cx,1

lbl1:   xor    eax,eax
        mov    ah,cl ; frame*256
     ;   mov    ax,384 ;307              ; 1.5*256 = factor
     ;   mul    cx

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

        mov    fs:_FrameCounter,0

        MPOP   eax,ebx,ecx,edx
;--------------------------------------------

ENDM

SHOWTIME MACRO col
        LOCAL lbl1
        test            fs:_CPUtime,1
        jz              lbl1
        COLOR           col
lbl1:

ENDM

TESTEND MACRO

         pushad
         MPUSH    ds,es,fs,gs

;==============================================
         mov      ax,DGROUP
         mov      ds,ax                   ; xchg FS,DS
         mov      ax,_DATA3
         mov      fs,ax

         ASSUME   ds:DGROUP,fs:_DATA3

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
         cmp     ax,WORD PTR fs:[FinSong]; is it time ????
         jb      @F                      ; to fade off ???

         mov     fs:Termine,1

         cmp     FadePtr2,OFFSET _BlackPal
         je      @F
         mov     fs:FadeFlag,0
         mov     eax,DWORD PTR fs:[FadePtr2]
         mov     DWORD PTR fs:[FadePtr1],eax   ; fade to black !!!!
         mov     ax,ds
         mov     fs:FadePtr2+2,ax
         mov     fs:FadePtr2,OFFSET _BlackPal

@@:      xor     eax,eax

         ASSUME  ds:_DATA3, fs:DGROUP

         MPOP    ds,es,fs,gs
         popad
         nop

ENDM

LOOPUNTILKEY MACRO lbl
         LOCAL   lbl1,lbl2,lbl3

         in      al,60h              ; EXIT ?
         cmp     al,78               ; '+'
         jne     lbl1
         mov     fs:_CPUtime,1       ; set CPUtime Flag to ON ....
         jmp     lbl
lbl1:    cmp     al,74               ; '-'
         jne     lbl2
         mov     fs:_CPUtime,0       ; set CPUtime Flag to OFF ....
         jmp     lbl
lbl2:    cmp     al,39h              ; Space Bar ...
         jne     lbl3
         mov     fs:_SpaceBar,1
         jmp     fin

lbl3:
         cmp     al,1                ; Escapff...
         jne     lbl
         mov     fs:_ExitDemo,1      ; exit the whole demo !!!!

ENDM

;*********************** REAL CODE ***********************

        push    	bp
        mov     	bp,sp
        pushad
        MPUSH   	ds,es,fs,gs

        mov             ax,_DATA3
	mov             ds,ax


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

        push            ds
	push            m320x200x256p
	call            _SetVGA
	add             sp,2
        pop             ds

        mov             si,offset sine
	mov             cx,320
	boucle_sincos:                          ;pour diviser par 2 'sincos'
	sar             word ptr ds:[SI],1
	add             SI,2
        LOOP            boucle_sincos

INITpart1:
; charge le bitmap 'digi.byt' dans le segment referenc‚ dans picture
; copie d'abord la ch. de car. 'digi.byt',0 dans picture
;
;
        push    fs
        push    eax

        mov     ax,DGROUP
        mov     fs,ax

        mov     eax,fs:_OfsinDta      ; OFFSET in Datafile
        mov     fs:Picparam.OfsInPdf,eax
        mov     ax,DGROUP             ; prepare for PDFIK call
        mov     es,ax
        mov     bx,OFFSET Picparam
        pusha
        call    PDFIK_ASM             ; call function 2 (extract+alloc)
        popa
        mov     ax,fs:Picparam.BufSeg ; where is the file in mem ?
        mov     picture,ax

        pop     eax
        pop     fs

;------------ succesfully PDFIKed ;-) -------------
        mov     ax,_DATA3
        mov     ds,ax

;---- wait right position/row in tune ----

        pushad
        MPUSH   ds,es,fs,gs

        ASSUME  ds:DGROUP
        ASSUME  fs:_DATA3
        mov     ax,DGROUP
        mov     ds,ax
        mov     ax,_DATA3   ; XCHG DS,FS !!!!
        mov     fs,ax

;;;;; attente bonne position music ;;;;; plante ???
WaitPos:
         mov     _ReplayInfo.numChannels,4 ; 4 voices

         les     bx,DWORD PTR [_MP]
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
         cmp     ax,WORD PTR fs:[DebSong]  ; is it time ????
         jb      WaitPos
         xor     eax,eax
;;;;;;;;; plante ???????
         ASSUME  ds:_DATA3
         ASSUME  fs:DGROUP
         MPOP    ds,es,fs,gs
         popad
         nop 
;------------------------------------------

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         mov     ax,DGROUP
         mov     fs,ax
         mov     ax,_DATA3
         mov     ds,ax
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

; init ....
          mov     Termine,0

;;;;; plante ???? non !!!
         mov     fs:_FadeON,0
         mov     FadeFlag,0
         mov     FadePtr1,OFFSET _BlackPal  ; Black to pic for the beginning !!!
         mov     ax,fs
         mov     FadePtr1+2,ax
         mov     FadePtr2,64000
         mov     ax,picture
         mov     FadePtr2+2,ax
         mov     ax,fs:_FrameCounter
         mov     Delai,ax
;;;;; plante ???? non !!!

         mov     bx,DGROUP
         mov     fs,bx

         mov     bx,fs:_StartAdr
         mov     WORD PTR fs:[bx],Screen1   ; _StartAdr->base = 0
         mov     WORD PTR fs:[bx+2],0       ; _StartAdr->flag = false
         mov     bx,fs:_WorkAdr
         mov     WORD PTR fs:[bx],Screen2   ; _WorkAdr->base
         mov     WORD PTR fs:[bx+2],0       ; _WorkAdr->flag = false
         mov     bx,fs:_NextAdr
         mov     WORD PTR fs:[bx],Screen3   ; _NextAdr->base
         mov     WORD PTR fs:[bx+2],0       ; _NextAdr->flag = false
         mov     fs:_Triple,1               ; triple buffering

         call            wait_vbl


;===================== MAIN LOOP ========================

part1:

;***** 2nd page *****
Do_a_frame:
        mov             di,fs:_WorkAdr
        cmp             WORD PTR fs:[di+2],1 ; _WorkAdr->flag true (previous _NextAdr) ?
        je              NextFrame        ; then construct next frame

        mov             ax,_DATA3
        mov             ds,ax
        mov             Dest,di               ; save pointer

        mov             si,Dest
        mov             ax,WORD PTR fs:[si]
        shr             ax,4                  ; segment + off. shr 4
        add             ax,0a000h
        mov             vio_seg,ax

        FADEPAL                                 ; fade palet !!!

        NEXTSTEP                                ; calculate nextstep :-)

        SHOWTIME        32

	call            disto2

        SHOWTIME        0

        TESTEND                                  ; test if we must fade out !!

        mov    bx,DGROUP
        mov    fs,bx
        mov    bx,_DATA3
        mov    ds,bx

        mov    di,fs:_NextAdr         ; save adr of next buffer

        mov    bx,Dest
        mov    WORD PTR fs:[bx+2],1    ; _WorkAdr->flag = true

        jmp  Nexxxt

;******** 3rd page *********
NextFrame:
         mov  di,fs:_NextAdr
         cmp  WORD PTR fs:[di+2],1 ; _NextAdr true ?
         je   NextFrame
    
Nexxxt:

        mov  bx,_DATA3
        mov  ds,bx
        mov  Dest,di               ; save pointer

        mov             si,Dest
        mov             ax,WORD PTR fs:[si]
        shr             ax,4                  ; segment + off. shr 4
        add             ax,0a000h
        mov             vio_seg,ax


        FADEPAL                                 ; fade palet !!!

        NEXTSTEP                                ; calculate nextstep :-)

        SHOWTIME        32

	call            disto2

        SHOWTIME        0

        TESTEND                                  ; test if we must fade out !!

        mov             bx,DGROUP
        mov             fs,bx
        mov             bx,_DATA3
        mov             ds,bx

        mov             bx,Dest
        mov             WORD PTR fs:[bx+2],1     ; _NextAdr->flag = true

        LOOPUNTILKEY part1                       ; exit if keypressed

fin:
        mov     fs:_FadeON,0             ; to be sure ....
	

;==================== END LOOP ==============================

; Lib‚ration m‚moire
	FREE            picture

        mov     ax,0a000h           ; Clear screen
        mov     es,ax
        mov     dx,3c4h
        mov     ax,0f02h
        out     dx,ax
        xor     eax,eax
        xor     di,di
        mov     cx,65536/4
        rep     stosd

        MPOP            ds,es,fs,gs
        popad
        nop
        leave

	retf
_KARMA    endp
;********************************************
;              MAIN END
;--------------------------------------------
;********************************************
disto2    proc near
;
; cette procedure est la meme que 'disto proc near'
; mais elle affiche l'image disto au pixel prŠs (><par 4 pix.)
;
hauteur  = 60 ;80
longueur = 320
xstartbm = 0
ystartbm = 20
screenof = (320*(60+10))/4
speedx   = 2 ;5
speedy   = 1 ;3

	mov     ax,picture
	mov     gs,ax

	xor ebx,ebx

        push    cx
        mov     cx,CurStep       
@@:
	add     decal1,speedy    ; FRAME COUNTER ADJUST 
	add     DECAL2,speedx

        dec     cx
        jnz     @B
        pop     cx

	mov al,decal1           ;  faire gaffe
	mov bx,offset dec1+2    ;
	mov cs:[BX],al          ;
	mov bx,offset dec3+2    ;
	mov cs:[BX],al          ;
	mov bx,offset dec5+2    ;
	mov cs:[BX],al          ;
	mov bx,offset dec7+2    ;
	mov cs:[BX],al          ;

				;  AUTOMODIFICATION !!!!
	mov al,decal2           ;
	mov bx,offset dec2+2    ;
	mov cs:[BX],al          ;
	mov bx,offset dec4+2    ;
	mov cs:[BX],al          ;
	mov bx,offset dec6+2    ;
	mov cs:[BX],al          ;
	mov bx,offset dec8+2    ;
	mov cs:[BX],al          ;

;------------plane0

	mov     ax,vio_seg
	mov     es,ax
	mov     di,screenof         ; offset (/4) de depart sur l'‚cran

	mov     ah,00000001b        ; 0001
	mov     al,sc_map_mask
	mov     dx,3C4h
	out     dx,ax

	mov     bp,xstartbm         ; x de depart sur le bitmap
	mov     cx,longueur/4
oneplane0:
	mov     dx,ystartbm         ; y de depart sur le bitmap
	push    cx
	mov     cx,hauteur
onecol0:
	push    cx
	mov     bx,dx                   ;dx=y
	mov     si,word ptr[mul320tb+2*ebx]
	add     si,bp                   ;bp=x
	mov     bx,bp                   ;decale en Y
dec1:
	add     bl,10         ; AM
	xor     bh,bh
	mov     ax,cosine[2*ebx]
	add     si,ax
	mov     bx,dx                   ;decale en X
dec2:                     ; AM
	add     bl,10
	mov     ax,cosine[2*ebx]
	sar     ax,1
	add     si,ax
	lodsb   gs:[si]
	stosb
	inc     dx
	add     di,79
	pop     cx
	loop    onecol0
	add     bp,4                    ; !!! 4 pour pixel prŠs!
	sub     di,(80*hauteur)-1
	pop     cx
	loop    oneplane0
;------------plane1
	mov     ax,picture
	mov     gs,ax
	mov     ax,vio_seg
	mov     es,ax
	mov     di,screenof         ; offset (/4) de depart sur l'‚cran
	mov     ah,00000010b        ; 0010
	mov     al,sc_map_mask
	mov     dx,3C4h
	out     dx,ax
	mov     bp,xstartbm+1       ; x de depart sur le bitmap
	mov     cx,longueur/4
oneplane1:
	mov     dx,ystartbm         ; y de depart sur le bitmap
	push    cx
	mov     cx,hauteur
onecol1:
	push    cx
	mov     bx,dx                   ;dx=y
	mov     si,word ptr[mul320tb+2*ebx]
	add     si,bp                   ;bp=x
	mov     bx,bp                   ;decale en Y
dec3:
	add     bl,10
	xor     bh,bh
	mov     ax,cosine[2*ebx]
	add     si,ax
	mov     bx,dx                   ;decale en X
dec4:
	add     bl,10
	mov     ax,cosine[2*ebx]
	sar     ax,1
	add     si,ax
	lodsb   gs:[si]
	stosb
	inc     dx
	add     di,79
	pop     cx
	loop    onecol1
	add     bp,4                    ; !!! 4 pour pixel prŠs!
	sub     di,(80*hauteur)-1
	pop     cx
	loop    oneplane1
;------------plane2
	mov     ax,picture
	mov     gs,ax
	mov     ax,vio_seg
	mov     es,ax
	mov     di,screenof         ; offset (/4) de depart sur l'‚cran
	mov     ah,00000100b        ; 0100
	mov     al,sc_map_mask
	mov     dx,3C4h
	out     dx,ax
	mov     bp,xstartbm+2       ; x de depart sur le bitmap
	mov     cx,longueur/4
oneplane2:
	mov     dx,ystartbm         ; y de depart sur le bitmap
	push    cx
	mov     cx,hauteur
onecol2:
	push    cx
	mov     bx,dx                   ;dx=y
	mov     si,word ptr[mul320tb+2*ebx]
	add     si,bp                   ;bp=x
	mov     bx,bp                   ;decale en Y
dec5:
	add     bl,10
	xor     bh,bh
	mov     ax,cosine[2*ebx]
	add     si,ax
	mov     bx,dx                   ;decale en X
dec6:        
	add     bl,10
	mov     ax,cosine[2*ebx]
	sar     ax,1
	add     si,ax
	lodsb   gs:[si]
	stosb
	inc     dx
	add     di,79
	pop     cx
	loop    onecol2
	add     bp,4                    ; !!! 4 pour pixel prŠs!
	sub     di,(80*hauteur)-1
	pop     cx
	loop    oneplane2
;------------plane3
	mov     ax,picture
	mov     gs,ax
	mov     ax,vio_seg
	mov     es,ax
	mov     di,screenof         ; offset (/4) de depart sur l'‚cran
	mov     ah,00001000b        ; 1000
	mov     al,sc_map_mask
	mov     dx,3C4h
	out     dx,ax
	mov     bp,xstartbm+3       ; x de depart sur le bitmap
	mov     cx,longueur/4
oneplane3:        
	mov     dx,ystartbm         ; y de depart sur le bitmap
	push    cx
	mov     cx,hauteur
onecol3:        
	push    cx

	mov     bx,dx                   ;dx=y
	mov     si,word ptr[mul320tb+2*ebx]
	add     si,bp                   ;bp=x
	mov     bx,bp                   ;decale en Y
dec7:        
	add     bl,10
	xor     bh,bh
	mov     ax,cosine[2*ebx]
	add     si,ax
	mov     bx,dx                   ;decale en X
dec8:        
	add     bl,10
	mov     ax,cosine[2*ebx]
	sar     ax,1
	add     si,ax
	lodsb   gs:[si]
	stosb
	inc     dx
	add     di,79
	pop     cx
	loop    onecol3
	add     bp,4                    ; !!! 4 pour pixel prŠs!
	sub     di,(80*hauteur)-1
	pop     cx
	loop    oneplane3

ret
disto2 endp
;********************************************
include disk.inc
;lecture
	;cx     doit contenir la taille
	;ds:dx  pointe sur le nom
	;ds:bp  l'adresse de destination
;ecriture 
	;cx      doit contenir la taille 
	;ds:dx   pointe sur le nom du fichier
	;bp      doit contenir l'offset d'ecriture DANS le fichier(16bits...)
	;ds:si   l'adresse de la zone a ecrire

;*************************************************        
_init320200 proc near

       ;-- On commence par d‚clencher le mode 13h pour que le BIOS -----
       ;-- effectue la plus grande partie de l'initialisation ----------
       ;-- Puis on modifie les registres qui n'ont pas encore le -------
       ;-- contenu souhait‚. -------------------------------------------

       mov   ax,0013h                               ;Appelle le mode 13h
       int   10h

       mov   dx,GC_INDEX                  ;D‚sactive par le bit num‚ro 4
       mov   al,GC_GRAPH_MODE        ;la s‚paration des adresses m‚moire
       out   dx,al                      ;dans le registre mode graphique
       inc   dx                                 ;du contr“leur graphique
       in    al,dx
       and   al,11101111b
       out   dx,al
       dec   dx

       mov   al,GC_MISCELL                 ;idem dans le registre divers
       out   dx,al                                  ;par le bit num‚ro 1
       inc   dx                                                        ;
       in    al,dx
       and   al,11111101b
       out   dx,al

       mov   dx,SC_INDEX            ;Modifie le registre de mode m‚moire
       mov   al,SC_MEM_MODE                   ;du contr“leur de s‚quence
       out   dx,al               ;de fa‡on … mettre fin … la r‚partition
       inc   dx                ;des adresses m‚moire sur plusieurs plans
       in    al,dx                   ;de bits et … fixer le plan courant
       and   al,11110111b           ;par le registre de masquage binaire
       or    al,4                                                      ;
       out   dx,al

       mov   ax,vio_seg                ;Remplit les quatre plans de bits
       mov   es,ax                   ;avec le code couleur 00h et efface
       xor   di,di                                              ;l'‚cran
       mov   ax,di
       mov   cx,8000h
       rep   stosw

       mov   dx,CRTC_INDEX                  ;Met fin au mode double -mot
       mov   al,CC_UNDERLINE         ; par le moyen du bit 6 du registre
       out   dx,al               ; de soulignement du contr“leur d'‚cran
       inc   dx
       in    al,dx
       and   al,10111111b
       out   dx,al
       dec   dx

       mov   al,CC_MODE_CTRL        ;Passe du mode mot au mode octet par
       out   dx,al            ;le moyen du bit 6 du registre de contr“le
       inc   dx                           ;de mode du contr“leur d'‚cran
       in    al,dx
       or    al,01000000b
       out   dx,al

       ret                                        ;retourne … l'appelant

_init320200 endp                                    ;Fin de la proc‚dure
;*************************************************        
clear_screens    proc near
	mov             dx,3c4h                 
	mov             al,sc_map_mask          
	mov             ah,00001111b
	out             dx,ax
	mov             ax,vio_seg
	mov             es,ax
	mov             di,0
	mov             ax,00
	mov             cx,64000/4
	rep             stosw
	call            show
	call            set
	mov             ax,vio_seg
	mov             es,ax        
	mov             di,0
	mov             ax,00                  
	mov             cx,64000/4
	rep             stosw
ret
clear_screens endp
;************************************
; flippe les 2 pages ecran (0 et 1) *
;************************************
;*************************************************
set        proc near

cmp     pi,1
je      se2
mov     pi,1
mov     word ptr vio_seg,0a400h      ;
jmp     ok_set                       ; alterne 0e et 1e pages !!
se2:                                 ;
mov     pi,0                         ;
mov     word ptr vio_seg,0a000h      ;
ok_set:
ret

set  endp
;*************************************************
show        proc near
sh1:
cmp   pv,1
je    sh2
mov   pv,1
mov   al,64
jmp   ok_show
sh2:
mov   pv,0
mov   al,0
;--------------------page visible , non concernee par setpix-----

ok_show:
mov   ah,al                         ;Octet fort de l'offset en AH
mov   dx,CRTC_INDEX                ;Adresse du contr“leur d'‚cran
mov   al,CC_START_HI                    ;Num‚ro du registre en AL
out   dx,ax                                   ;Effectue la sortie

ret
show       endp
;*************************************************
put_palette     proc    near
; offset dans ds:si    , 256 couleurs
; luminance dans bl
    pusha
    mov     ah,0
    mov     al,0                    ;the first color to write is # 0
    
    mov     cx,256*3                ;nb of bytes to write
    
    mov     dx,03c8h                ;VGA PEL address write mode register
    out     dx,al           
    inc     dx                      ;VGA PEL data register (03c9h)

paloo:    
    lodsb
    mul     bl
    mov     al,ah
    out     dx,al
    loop    paloo
    popa
ret
put_palette     endp
;*************************************************
; pour mettre la couleur du fond en noir et en blanc
;*************************************************       
black0  proc near
	mov     dx,3c8h
	xor     al,al
	out     dx,al
	mov     dx,3c9h
	xor     al,al
	out     dx,al
	out     dx,al
	out     dx,al
	ret
black0  endp
white0  proc near
	mov     dx,3c8h
	xor     al,al
	out     dx,al
	mov     al,63
	mov     dx,3c9h
	out     dx,al
	xor     al,al
	out     dx,al
	out     dx,al
	ret
white0  endp
gray0   proc near
	mov     dx,3c8h
	xor     al,al
	out     dx,al
	mov     al,20
	mov     dx,3c9h
	out     dx,al
	out     dx,al
	xor     al,al
	out     dx,al
	ret
gray0   endp

;**********************************************************        
; port 3da bit 3
wait_vbl        proc    near    ; pour attendre la VBL

	mov     dx,03DAh
	in      al,dx
	jmp     $+2
	test    al,08h
	jz      V_Ready
V_Not_Ready:
	in      al,dx
	jmp     $+2
	test    al,08h
	jz      V_Not_Ready
V_Ready:
	in      al,dx
	jmp     $+2
	test    al,08h
	jz      V_Ready
	ret

wait_vbl        endp

KARMA_TEXT   ENDS
end

























































































