;*******************************
; GOPI's Dots (C) TFL-TDV 1994 *
;*******************************


   INCLUDE  PDFIK.INC
   INCLUDE  VIDEO.INC
   INCLUDE  PLAYINFO.INC

;*****************************************************************************
;                          Structure m‚moire ...
;*****************************************************************************
.386
        DGROUP GROUP _DATA, _BSS
        GOPI_TEXT SEGMENT DWORD PUBLIC USE16 'CODE'
                ASSUME cs:GOPI_TEXT, ds:GOPI_DATA, fs:DGROUP
        GOPI_TEXT ENDS
        _DATA SEGMENT DWORD PUBLIC USE16 'DATA'
        _DATA ENDS
        _BSS SEGMENT DWORD PUBLIC USE16 'BSS'
        _BSS ENDS
        GOPI_DATA SEGMENT DWORD PRIVATE USE16 'FAR_DATA'
        GOPI_DATA ENDS
;*****************************************************************************
GOPI_DATA SEGMENT

 include angles.inc
 ;contient les 360 valeurs du sinus et du cosinus multipli‚es par 256
 ;label= cos,sin (Dword)

 include pal1.inc
 include fgopi.inc
 include data1.inc         ;Demi-sphere
 include data2.inc         ;Pyramide
 include data3.inc         ;Fosse+pyramide
 include data4.inc         ;Fosses
 include data5.inc         ;Fosse+TDV
 include data6.inc         ;Barriere+TFL
;*****************************************************************************
CURRENT_PAGE    DW      0                      ; offset page courante
PAGE_SIZE       EQU     16000                  ; taille d'une page en bytes
PLANE_BITS      EQU     03h                    ; Bits 0-1 of Xpos = Plane #
MAP_MASK_PLANE1 EQU     00102h                 ; Map Register + Plane 1
PAGE_ADDR       DW      0, 16000, 32000, 48000 ; offsets de chaque page
VISUAL_PAGE     DW      0                      ; page affich‚e
ACTIVE_PAGE     DW      0                      ; page active
VERT_RETRACE    EQU     08h                    ; INPUT_1: Vertical Retrace Bit
CRTC_Index      EQU     03D4h                  ; Contr“leur crt VGA
START_DISP_LO   EQU     00Dh                   ; CRTIndex: display start lo
START_DISP_HI   EQU     00Ch                   ; CRTIndex: display start hi
INPUT_1         EQU     03DAh                  ; Registre statut d'input #1
ALL_PLANES_ON   EQU     00F02h                 ; Map Register + All Bit Planes
SC_Index        EQU     03C4h                  ; Contr“leur s‚quenceur VGA
VIO_SEG         word    ?
CPU_FLAG        word    ?                      ; pour le temps cpu
SW              word    ?                      ; pour le switchage des pages
Larg=320
Haut=200
Screen1 = 0
Screen2 = (Larg*Haut/4)

EVEN
; - Plot Tables -
XTable LABEL WORD         ; Table pr‚multipli‚e des abscisses
       i = 0
       REPT Larg
       dw (1 SHL (i AND 3)), i SHR 2 ; Plane number + Hor. offset
       i = i + 1
       ENDM

YTable LABEL WORD         ; Table pr‚multipli‚e des ordonn‚es
       i = 0
       REPT  Haut         ; Hauteur Screen en pixels
       dw i
       i = i + Larg/4     ; Largeur Screen en pixels
       ENDM

Dest DW 0

;*****************************************************************************
xv      EQU 0
yv      EQU 1024*4
zv      EQU 1024*2*4
vv      EQU 1024*3*4
savpos1 EQU 1024*4*4
savpos2 EQU 1024*5*4
savptr  WORD savpos1,savpos2

HeapSeg WORD ?
HeapSize EQU 1024*4+xv+yv+zv+vv+savpos1+savpos2

; xv           DWORD  1024 DUP(0)      ;vecteur de travail en x
; yv           DWORD  1024 DUP(0)      ;vecteur de travail en y
; zv           DWORD  1024 DUP(0)      ;vecteur de travail en z
; vv           DWORD  1024 DUP(0)      ;vecteur de travail couleur
; savpos1      DWORD  1024 DUP(0)      ;vecteur ou on sauve coordonees
; savpos2      DWORD  1024 DUP(0)      ;associ‚es aux points
; savptr       WORD   OFFSET savpos1,OFFSET savpos2 

 pagescr      byte  ?
 x            word  ?                 ;n‚cessaire pour la routine
 y            word  ?                 ;...setpix!
 couleur      byte  ?                 ;
 agr          byte  6                 ;agrandissement
 agl          word  0                 ;angle de rotation
 trs          byte  0                 ;deformation
 trs_flag     byte  0                 ;deformation
 save         word  ?                 ;variable!

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


GOPI_DATA ENDS
;*****************************************************************************
_DATA SEGMENT

EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE

_DATA ENDS

_BSS SEGMENT

        EXTRN _FrameCounter     : WORD
	EXTRN _ExitDemo         : WORD
	EXTRN _CPUtime          : WORD
        EXTRN _SpaceBar         : WORD
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
;*****************************************************************************
GOPI_TEXT SEGMENT
     EXTRN _AveragePAL: FAR

                 EXTRN   _WaitVBL : FAR
                 PUBLIC  _GOPI

 include video1.inc   ;openvideo
                      ;closevideo
                      ;load_pal
                      ;waitvrt
 include video2.inc   ;clear_vga_screen
                      ;set_visual_page
                      ;set_active_page
                      ;setpix
                      ;cpu_time
                      ;sw_pages
                      ;out_16
 include divers.inc   ;free_keyboard
 include transf1.inc  ;     transf1                ;agrandissement
 include transf2.inc  ;     transf2a               ;rotation z
                      ;     transf2b               ;rotation x
                      ;     transf2c               ;rotation y

 include transf3.inc  ;     transf3a               ;rotation zx
                      ;     transf3b               ;rotation zy
                      ;     transf3c               ;rotation xy
;*****************************************************************************
MPUSH macro reg1:req,reg2:vararg
      push reg1
      ifnb <reg2>
      mpush reg2
      endif
      endm
;*****************************************************************************
MPOP macro reg1:req,reg2:vararg
      ifnb <reg2>
      mpop reg2
      endif
      pop reg1
      endm
;*****************************************************************************

ClearDots MACRO
      LOCAL labl

      MPUSH ax,cx,dx,si,di,es

      mov  ax,savptr       ; swap save buf !!!
      xchg ax,savptr+2
      mov  savptr,ax


      mov  dx,3c4h
      mov  ax,0f02h
      out  dx,ax           ; enable all bitplanes !!!!

      mov  ax,0a000h
      mov  es,ax
      xor  al,al
      mov  si,savptr       ; ptr on save-vector

      mov  cx,nbdots
labl: mov  di,WORD PTR gs:[si] ; take coord
      add  si,4 
      stosb                ; clear dot !!!!
      dec  cx
      jnz  labl      


      MPOP ax,cx,dx,si,di,es

ENDM

loaddots macro vx,vy,vz:req
         local bcl1
         MPUSH ax,bx,cx,si         
    
         xor  bx,bx
         xor  si,si
         xor  eax,eax
         mov  cx,nbdots
bcl1:
         mov  al,BYTE PTR VX[bx]
         mov  BYTE PTR gs:xv[si],al

         mov  al,BYTE PTR VY[bx]
         mov  BYTE PTR gs:yv[si],al

         mov  al,BYTE PTR vz[bx]
         mov  BYTE PTR gs:vv[si],al
         sub  al,6            ;6 = maxz div 2
         mov  BYTE PTR gs:zv[si],al

         inc  bx
         add  si,4

         dec  cx
         jnz  bcl1

         MPOP ax,bx,cx,si 
endm
;*****************************************************************************
convdots macro vz2,vz1:req
         local bcl1
         MPUSH ax,bx,cx,dx,si
 
         xor  bx,bx
         xor  si,si
         mov  cx,nbdots
bcl1:
         mov   al,trs
         mul   BYTE PTR vz1[si]
         mov   dx,ax               ;save=vz1*trs

         mov   al,16
         sub   al,trs              ;al=16-trs

         mul BYTE PTR vz2[si]      ;ax=(16-trs)*vz2

         mov di,dx
         add ax,di                 ;ax=(16-trs)*vz2+vz1*trs
         shr ax,4                  ;ax=ax /16
         mov BYTE PTR gs:zv[bx],al
         mov BYTE PTR gs:vv[bx],al    ; only LSB used for color !!!!

         add  bx,4
         inc  si

         dec  cx
         jnz  bcl1
 
         MPOP ax,bx,cx,dx,si
endm
;*****************************************************************************
inctrs1 macro
        local suit1,suit2,suit3,decrm
 push ax

;incremente et decremente la transformation
 mov al,trs_flag
 test al,al
 jnz decrm
 mov al,trs
 inc al         ;flag=0 =>inc
 jmp suit1
decrm:          ;flag=1 =>dec
 mov al,trs
 dec al
suit1:
 mov trs,al

 cmp al,16
 jb suit2
 mov trs_flag,1  ; >16 =>  flag=1
suit2:
 cmp al,0
 jg  suit3
 mov trs_flag,0  ; =<0 =>  flag=0
suit3:
 
 pop ax
endm
;*****************************************************************************
inctrs2 macro
        local suit1
  push ax

;incremente  la transformation
  mov al,trs
  cmp al,16
  jb suit1
  mov al,15
suit1:
  inc al
  mov trs,al

  pop ax
endm
;*****************************************************************************
READ_KEY MACRO
       LOCAL l1,l2,l3,l4

       in      al, 60h                            ; buffer clavier
       cmp     al, 78                             ; '+' ?
       jnz     l1
       mov     WORD PTR ds:[cpu_flag], 1
       mov     WORD PTR fs:[_CPUtime],1
       Free_Keyboard
l1:    cmp     al, 74                             ; '-' ?
       jnz     l2
       mov     WORD PTR fs:[_CPUtime],0
       mov     WORD PTR ds:[cpu_flag], 0
       Free_Keyboard
l2:    cmp     al,39h                             ; spacebar ?
       jne     l3
       mov     fs:_SpaceBar,1                     ; skip part
       Free_KeyBoard
       jmp     fin
l3:    cmp     al, 1                              ; esc ?
       jne     l4
       mov     fs:_ExitDemo,1                     ; exit demo
       Free_KeyBoard
       jmp     fin

l4:

       ENDM
;*****************************************************************************
_GOPI PROC FAR

        push    bp
        mov     bp, sp
        pushad
        MPUSH   ds,es,fs,gs

        mov     ax,GOPI_DATA ; set GOPI data
        mov     ds,ax
        mov     ax,DGROUP
        mov     fs,ax

;------- recuperer parametres sur le stack !!!! --------

         push    eax
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
         pop     eax

;-------------------------------------------------------


        push    m320x200x256p    ; set 320x200x256 tweaked 
        call    _SetVGA
        add     sp, 2

;---- wait right position/row in tune ----

        MPUSH   eax,bx,ds,es,fs

        ASSUME  ds:DGROUP
        ASSUME  fs:GOPI_DATA
        mov     ax,DGROUP
        mov     ds,ax
        mov     ax,GOPI_DATA   ; XCHG DS,FS !!!!
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

         xor     eax,eax
         mov     ax,_ReplayInfo.pos
         shl     eax,14
         or      ax,_ReplayInfo.row
         or      ah,al
         shr     eax,8
         cmp     ax,WORD PTR fs:[DebSong]  ; is it time ????
         jb      WaitPos
         xor     eax,eax
;;;;;;;;; plante ???????
         ASSUME  ds:GOPI_DATA
         ASSUME  fs:DGROUP
      
         MPOP    eax,bx,ds,es,fs

;------------------------------------------



;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         mov     ax,DGROUP
         mov     fs,ax
         mov     ax,GOPI_DATA
         mov     ds,ax
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

         mov     ah,48h                ; MALLOC
         mov     bx,(HeapSize SHR 4)+1 ; memory requested
         int     21h
         mov     HeapSeg,ax            ; Segment address returned
         mov     gs,ax                 ; GS = Heap !!!!!


         mov     ax,fs:_CPUtime
         mov     cpu_flag,ax

; init ....
          mov     Termine,0

;;;;; plante ???? non !!!
         mov     fs:_FadeON,0
         mov     FadeFlag,0
         mov     FadePtr1,OFFSET _BlackPal  ; Black to pic for the beginning !!!
         mov     ax,fs
         mov     FadePtr1+2,ax
         mov     FadePtr2,OFFSET pal
         mov     ax,ds
         mov     FadePtr2+2,ax
        ; mov     ax,fs:_FrameCounter
        ; mov     Delai,ax
         mov     fs:_FrameCounter,0
         mov     Delai,0
;;;;; plante ???? non !!!

        mov     bx, fs:_StartAdr
        mov     WORD PTR fs:[bx], screen1
        mov     WORD PTR fs:[bx+2], 0
        mov     bx, fs:_WorkAdr
        mov     WORD PTR fs:[bx], screen2
        mov     WORD PTR fs:[bx+2], 0
        mov     fs:_Triple, 0
        mov     fs:_SyncFlag, 1
        call    _WaitVbl
;*****************************************************************************
Part2:
       cmp  fs:_SyncFlag, 1
       jnz  Part2
       mov  fs:_SyncFlag, 0

;===================== Fade Palette ===========================

;;;;;;;;;; plante pas !!!!!!

         cmp     FadeFlag,255
         jb      NewFade

         mov     fs:_FadeON,0  ; plus fader ...

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      fin

         mov     fs:_FadeON,0    ; don't set _TmpPal anymore ...
         jmp     @F
NewFade: mov     ax,FadeFlag  ; average Black-MyPal
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
         mov     fs:_FadeON,1         ; set new PAL during next VR !!!!
         mov     cx,fs:_FrameCounter
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     Faddi
         mov     cx,1
Faddi:   add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     Faddi
@@:

;;;;;;; plante pas !!!!!!



;==============================================================

       mov       ax,0a000h
       mov       es,ax

       cpu_time  48
       ClearDots
    ;   clear_vga_screen       ; !!!!!!!! 

       cpu_time  32
       loaddots  x32,y32,dt1  ;charge ds xv,xy,xz l'objet
       convdots  dt1,dt2      ;transformation

       mov       bx,fs:_WorkAdr
       mov       bx,WORD PTR fs:[bx]
       mov       Dest,bx

       cpu_time  16
       transf3a               ;rotation
       cpu_time 0
       inctrs2                ;incremente la transformation

       mov     bx,fs:_WorkAdr
       mov     WORD PTR fs:[bx+2],1

       READ_KEY               ; read keyboard

      mov  ax,agl

      mov  cx,fs:_FrameCounter
      test cx,cx
      jnz  @F
      mov  cx,1 
@@:   add  ax,4*2
      dec  cx
      jnz  @B

      mov  fs:_FrameCounter,0

      cmp  ax,360*4    ;si l'angle >360ø =>=0
      jb   negal2 
      xor ax,ax
      mov trs,al
      mov agl,ax
      mov fs:_FadeON,0 ; fade off
      Jmp part3
negal2:
      mov  agl,ax
      jmp  part2
;*****************************************************************************
Part3:
       cmp  fs:_SyncFlag, 1
       jne  Part3
       mov  fs:_SyncFlag, 0

      mov       ax,0a000h
      mov       es,ax

      cpu_time 48
      ClearDots
    ;  clear_vga_screen
     
      cpu_time 32
      loaddots  x32,y32,dt2  ;charge ds xv,xy,xz l'objet
      convdots  dt2,dt3      ;transformation
 
      mov       bx,fs:_WorkAdr
      mov       bx,WORD PTR fs:[bx]
      mov       Dest,bx

      cpu_time 16
      transf3b
      inctrs2
      cpu_time 0


      READ_KEY

      mov bx,fs:_WorkAdr
      mov WORD PTR fs:[bx+2],1

      mov  ax,agl
      mov  cx,fs:_FrameCounter
      test cx,cx
      jnz  @F
      mov  cx,1
@@:   add  ax,4*2
      dec  cx
      jnz  @B   
      mov  fs:_FrameCounter,0 


      cmp  ax,360*4     ;si l'angle >360ø =>=0
      jb  negal3
      xor ax,ax
      mov trs,al
      mov agl,ax
      Jmp part4
negal3:
      mov  agl,ax
      jmp  part3
;*****************************************************************************
Part4:
       cmp  fs:_SyncFlag, 1
       jnz  part4
       mov  fs:_SyncFlag, 0

      mov      ax,0a000h
      mov      es,ax

      cpu_time 48
      ClearDots 
    ;  clear_vga_screen

      cpu_time 32
      loaddots  x32,y32,dt3  ;charge ds xv,xy,xz l'objet
      convdots  dt3,dt4      ;transformation

      mov       bx,fs:_WorkAdr
      mov       bx,WORD PTR fs:[bx]
      mov       Dest,bx

      cpu_time 16
      transf3c
      inctrs2
      cpu_time 0

      READ_KEY

      mov     bx,fs:_WorkAdr
      mov     WORD PTR fs:[bx+2],1

      mov  ax,agl
      mov  cx,fs:_FrameCounter
      test cx,cx
      jnz  @F
      mov  cx,1
@@:   add  ax,4*2
      dec  cx
      jnz  @B   
      mov  fs:_FrameCounter,0 

      cmp  ax,360*4    ;si l'angle >360ø =>=0
      jb   negal4
      xor  ax,ax
      mov trs,al
      mov agl,ax
      jmp  part5
negal4:
      mov  agl,ax

      jmp part4
;*****************************************************************************
Part5:
       cmp  fs:_SyncFlag, 1
       jnz  part5
       mov  fs:_SyncFlag, 0

      mov   ax,0a000h
      mov   es,ax

      cpu_time 48
      ClearDots
     ; clear_vga_screen

      cpu_time 32
      loaddots  x32,y32,dt4  ;charge ds xv,xy,xz l'objet
      convdots  dt4,dt5      ;transformation

      mov       bx,fs:_WorkAdr
      mov       bx,WORD PTR fs:[bx]
      mov       Dest,bx

      cpu_time 16 
      transf3a
      inctrs2
      cpu_time 0

      READ_KEY

      mov bx,fs:_WorkAdr
      mov WORD PTR fs:[bx+2],1

      mov  ax,agl
      mov  cx,fs:_FrameCounter
      test cx,cx
      jnz  @F
      mov  cx,1
@@:   add  ax,4*2
      dec  cx
      jnz  @B   
      mov  fs:_FrameCounter,0 

      cmp  ax,360*4   ;si l'angle >360ø =>=0
      jb   negal5
      xor ax,ax
      mov trs,al
      mov agl,ax
      Jmp part6
negal5:
      mov  agl,ax
      jmp  part5
;*****************************************************************************
Part6:
       cmp  fs:_SyncFlag, 1
       jnz  part6
       mov  fs:_SyncFlag, 0

      mov   ax,0a000h
      mov   es,ax

      cpu_time 48
      ClearDots
     ; clear_vga_screen

      cpu_time 32
      loaddots  x32,y32,dt5  ;charge ds xv,xy,xz l'objet
      convdots  dt5,dt6      ;transformation

      mov       bx,fs:_WorkAdr
      mov       bx,WORD PTR fs:[bx]
      mov       Dest,bx

      cpu_time 16
      transf3b
      inctrs2
      cpu_time 0

      READ_KEY

      mov bx,fs:_WorkAdr
      mov WORD PTR fs:[bx+2],1

      mov  ax,agl
      mov  cx,fs:_FrameCounter
      test cx,cx
      jnz  @F
      mov  cx,1
@@:   add  ax,4*2
      dec  cx
      jnz  @B   
      mov  fs:_FrameCounter,0 

      cmp  ax,360*4  ;si l'angle >360ø =>=0
      jb  negal6
      xor ax,ax
      mov trs,al
      mov agl,ax
      Jmp part7
negal6:
      mov  agl,ax
      jmp  part6
;*****************************************************************************
Part7:
;     sw_pages
       cmp  fs:_SyncFlag, 1
       jnz  part7
       mov  fs:_SyncFlag, 0

      mov   ax,0a000h
      mov   es,ax

      cpu_time 48
      ClearDots
     ; clear_vga_screen

      cpu_time 32
      loaddots  x32,y32,dt6  ;charge ds xv,xy,xz l'objet
      convdots  dt6,dt5      ;transformation

      mov       bx,fs:_WorkAdr
      mov       bx,WORD PTR fs:[bx]
      mov       Dest,bx

      cpu_time 16
      transf3a
      inctrs2
      cpu_time 0

      READ_KEY

      mov bx,fs:_WorkAdr
      mov WORD PTR fs:[bx+2],1


      mov  ax,agl
      mov  cx,fs:_FrameCounter
      test cx,cx
      jnz  @F
      mov  cx,1
@@:   add  ax,4*2
      dec  cx
      jnz  @B   
      mov  fs:_FrameCounter,0 

      cmp  ax,360*4  ;si l'angle >360ø =>=0
      jb  negal7
      xor ax,ax
      mov trs,al
      mov agl,ax
      Jmp part8
negal7:
      mov  agl,ax
      jmp  part7
;*****************************************************************************
Part8:
;     sw_pages
       cmp  fs:_SyncFlag, 1
       jnz  part8
       mov  fs:_SyncFlag, 0

;===================== Fade Palette ===========================

;;;;;;;;;; plante pas !!!!!!

         cmp     FadeFlag,255
         jb      NewFade2

         mov     fs:_FadeON,0  ; plus fader ...

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      fin

         mov     fs:_FadeON,0    ; don't set _TmpPal anymore ...
         jmp     @F
NewFade2: mov     ax,FadeFlag  ; average Black-MyPal
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
         mov     fs:_FadeON,1         ; set new PAL during next VR !!!!
         mov     cx,fs:_FrameCounter
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     Faddi2
         mov     cx,1
Faddi2:   add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     Faddi
@@:

;;;;;;; plante pas !!!!!!



;==============================================================


         pushad
         MPUSH    ds,es,fs,gs

;==============================================
         mov      ax,DGROUP
         mov      ds,ax                   ; xchg FS,DS
         mov      ax,GOPI_DATA
         mov      fs,ax
         ASSUME   ds:DGROUP,fs:GOPI_DATA

;----------- test if we must finish ... ----------

         mov      _ReplayInfo.numChannels,4 ; 4 voices
         
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
         cmp     ax,WORD PTR fs:[FinSong]; is it time ????
         jb      @F                      ; to fade off ???

         mov     ax,DGROUP
         mov     fs,ax
         mov     ax,GOPI_DATA
         mov     ds,ax
         ASSUME  ds:GOPI_DATA,fs:DGROUP

         mov     Termine,1

         cmp     FadePtr2,OFFSET _BlackPal
         je      @F
         mov     FadeFlag,0
         mov     eax,DWORD PTR [FadePtr2]
         mov     DWORD PTR [FadePtr1],eax   ; fade to black !!!!
         mov     ax,fs
         mov     FadePtr2+2,ax
         mov     FadePtr2,OFFSET _BlackPal

@@:      xor     eax,eax

         MPOP    ds,es,fs,gs
         popad
         nop

      mov      ax,0a000h
      mov      es,ax

      cpu_time 48
      ClearDots
     ; clear_vga_screen

      cpu_time 32
      loaddots  x32,y32,dt5  ;charge ds xv,xy,xz l'objet
      
      mov       bx,fs:_WorkAdr
      mov       bx,WORD PTR fs:[bx]
      mov       Dest,bx

      cpu_time 16
      transf3c
      cpu_time 0

      READ_KEY

      mov bx,fs:_WorkAdr
      mov WORD PTR fs:[bx+2],1

      mov  ax,agl
      mov  cx,fs:_FrameCounter
      test cx,cx
      jnz  @F
      mov  cx,1
@@:   add  ax,4*2
      dec  cx
      jnz  @B   
      mov  fs:_FrameCounter,0 

      cmp  ax,360*4  ;si l'angle >360ø =>=0
      jb  negal8
      xor ax,ax
      mov trs,al
      mov agl,ax
      Jmp fin
negal8:
      mov  agl,ax
      jmp  part8

;*****************************************************************************

fin:

      mov    fs:_FadeON,0

      mov    ax,0a000h
      mov    es,ax
      xor    di,di        ; !!!!!! 
      mov    dx,3c4h
      mov    ax,0f02h
      out    dx,ax
      mov    cx,65536/4   ; clear 256ko de Video
      xor    eax,eax
      rep    stosd

      Free_Keyboard

      mov     ax,HeapSeg            ; segment to free
      mov     es,ax
      mov     ah,49h                ; MFREE
      int     21h



      MPOP    ds,es,fs,gs
      popad               ; restore
      nop


      leave
      retf
_GOPI ENDP

GOPI_TEXT ENDS
end
