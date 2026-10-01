;--------------------------------------------------------------------------
; Wired '94 Morflame's Part ... Not very interesting, but always fun ...
; 386 minimum
; Programming : Morflame (Guy De Smet) october 1994
;--------------------------------------------------------------------------

        INCLUDE  PDFIK.INC
        INCLUDE  VIDEO.INC
        INCLUDE  PLAYINFO.INC

;--------------------------------------------------------------------------
;                           Memory Struct        
;--------------------------------------------------------------------------
.386        
        DGROUP GROUP _DATA, _BSS
        MRF_TEXT SEGMENT DWORD PUBLIC USE16 'CODE'
                ASSUME cs:MRF_TEXT, ds:_DATA2; , fs:DGROUP
        MRF_TEXT ENDS
        _DATA SEGMENT DWORD PUBLIC USE16 'DATA'
        _DATA ENDS
        _DATA2 SEGMENT DWORD PRIVATE USE16 'FAR_DATA'
        _DATA2 ENDS
        _BSS SEGMENT DWORD PUBLIC USE16 'BSS'
        _BSS ENDS
;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
; constantes utiles
  MAX_VERT=1000
  MAX_POL=700
  MAX_OBJ=50
  Larg=320
  Haut=200
  Screen1 = 0
  Screen2 = (Larg*Haut/4)
  Screen3 = ((Larg*Haut/4)*2)
;--------------------------------------------------------------------------
_DATA2 SEGMENT
   ; Files data pointers
        
        Fic3d   WORD ?
        Ceil      WORD ?
        mapping   WORD ?
        logo    WORD ?

   ; for the page switching 
        SW byte 0

   ; cpu_time
        cpu_flag byte 0

   ; tables :
        INCLUDE TABLES2.INC
        INCLUDE PALETTE.SPR
   
   ; Drawing precision
       precision byte 1

   ; Animation counter  ----> SCRIPT
       frame_animation word 0

   ; Animation step (incr‚mentation units) ---> SYNCHRONISATION
       pas_animation word 0

   ; Lighting
       luminosite byte 0

;---- param for synchro with musak ----
EVEN
DebSong  WORD ?
FinSong  WORD ?

;---- param pour fading ----
Timeleft WORD ?         ; time left for execute
FadeFlag WORD ?         ; fading flag
FadePtr1 WORD 2 DUP(?)  ; palette fading pointer
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?
Termine  WORD 0         ; end flag!

Dest     DW ?           ; working screen

cumul_step_lo DD 0
cumul_step_hi DD 0
cumul_old_lo DD 0
cumul_old_hi DD 0

Automatic DW 1

_DATA2 ENDS

_DATA SEGMENT

;-- data pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
       Ficname    BYTE 'world.v3d',0
       Ficparam   PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Ficname,0,0,0,,,0>
       Ficname2   BYTE 'morceil.bin',0
       Ficparam2  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Ficname2,0,0,0,,,0>
       Ficname3  BYTE 'morfloor.bin',0
       Ficparam3 PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Ficname3,0,0,0,,,0>
       Ficname4  BYTE 'morcon.raw',0
       Ficparam4 PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Ficname4,0,0,0,,,0>

         EXTRN _FrameCounter     : WORD
         EXTRN _ExitDemo         : WORD
         EXTRN _SpaceBar         : WORD
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


EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE


_DATA ENDS

MRF_TEXT SEGMENT
     EXTRN _AveragePAL: FAR


ALIGN
EVEN
; macros 
INCLUDE MEMOIRE.INC             ; memory 
INCLUDE MORGMAC.INC             ; graphics
INCLUDE 320x200.INC             ; mode x routines (320x200 60Hz)
INCLUDE TRACING.INC             ; morflame's main drawing routines

;------------------------------------------------------------------------------
SYNC_FRAME MACRO code, label
; Do a loop based upon animation step...
LOCAL boucle_sync
IF CODE EQ 0
                mov         cx, pas_animation
label:          push        cx
ELSEIF CODE EQ 1
         
                pop         cx
                dec         cx
                jnz         label
ENDIF

ENDM
;------------------------------------------------------------------------------
LUMIERE MACRO        
LOCAL paloo        
        pusha
        mov     ah,0               
        mov     al,0                    ;the first color to write is # 0
        mov     cx,256*3                ;nb of bytes to write
        mov     dx,03c8h                ;VGA PEL address write mode register
        out     dx,al
        inc     dx                      ;VGA PEL data register (03c9h)
paloo:  lodsb   [si]
        mul     bl
        mov     al,ah
        out     dx,al
        loop    paloo
        popa
ENDM
;------------------------------------------------------------------------------
AFFICHE_LOGO MACRO
LOCAL Cbcl1,Cbcl2
; put pict on the 4 pages (why not ?)
        push    ds
        push    es
        mov     ax,Logo
        mov     ds,ax
        mov     si,800                ; skip Alchemy header

        mov     dx,3c4h
        mov     al,02h                ; bitplane sel. reg.
        out     dx,al
        inc     dl  
        
        cld
        mov     ax,0a000h
        mov     es,ax
        i3=0
        REPT    4
        xor     di,di
        mov     al,(1 SHL i3)
        out     dx,al
        mov     cx,320*200/4
@@:     lodsb
        add     si,3
        stosb
        dec     cx
        jnz     @B
        sub     si,320*200-1
        i3=i3+1
        ENDM

        mov     dx,3c4h
        mov     ax,0f02h
        out     dx,ax

        mov     dx,3ceh
        mov     ax,4105h  ; WRITE MODE 1
        out     dx,ax

        cld
        mov     ax,0a000h
        mov     ds,ax
        mov     cx,65536-80*200
        xor     si,si
        mov     di,80*200
        rep     movsb

        mov     dx,3ceh
        mov     ax,4005h  ; WRITE MODE 0
        out     dx,ax

        
        pop     es
        pop     ds
ENDM

         EXTRN   _WaitVBL : FAR
         PUBLIC  _Morflame1
;------------------------------------------------------------------------------
;                  P R O C E D U R E   P R I N C I P A L E
;------------------------------------------------------------------------------
ALIGN
EVEN
_Morflame1 PROC FAR
        push    bp
        mov     bp, sp
        pushad
        MPUSH   ds,es,fs,gs 
        LSDS    _DATA2, ax

;------- recuperer parametres sur le stack !!!! --------
         xor     eax,eax
         mov     ax,WORD PTR ss:[bp+6]  ; debut pos
         shl     eax,14
         or      ax,WORD PTR ss:[bp+8]  ; debut row
         or      ah,al
         shr     eax,8
         mov     DebSong,ax
         xor     eax,eax
         mov     ax,WORD PTR ss:[bp+10] ; fin pos
         shl     eax,14
         or      ax,WORD PTR ss:[bp+12] ; fin row
         or      ah,al
         shr     eax,8
         mov     FinSong,ax
         xor     eax,eax
;-------------------------------------------------------


        call    Part1

        mov     ax,DGROUP
        mov     fs,ax
        mov     fs:_FadeON,0

        mov     dx,3c4h
        mov     ax,0f02h
        out     dx,ax
        mov     ax,0a000h
        mov     es,ax
        xor     di,di
        mov     cx,65536/4
        xor     eax,eax
        rep     stosd

        MPOP    ds,es,fs,gs
        popad
        nop
        leave
        retf
_Morflame1 ENDP
;------------------------------------------------------------------------------
;                      P A R T I E  D O O M  S T Y L E
;------------------------------------------------------------------------------
ALIGN
EVEN
Part1 PROC

; some macros .....

TESTEND  MACRO
         LOCAL lbl1,lbl2

         pushad
         MPUSH    ds,es,fs,gs

;==============================================
         mov      ax,DGROUP
         mov      ds,ax                   ; xchg FS,DS
         mov      ax,_DATA2
         mov      fs,ax

         ASSUME   ds:DGROUP,fs:_DATA2

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
         jae     lbl2                    ; to fade out ???

;+++++++++++++++++++++++++++++++++++++++
         cmp     frame_animation,3500    ; in all cases, do fade out !!!
         jb      lbl1
;+++++++++++++++++++++++++++++++++++++++

lbl2:
         mov     fs:Termine,1

         cmp     FadePtr2,OFFSET _BlackPal
         je      lbl1
         mov     fs:FadeFlag,0
         mov     eax,DWORD PTR fs:[FadePtr2]
         mov     DWORD PTR fs:[FadePtr1],eax   ; fade to black !!!!
         mov     ax,ds
         mov     fs:FadePtr2+2,ax
         mov     fs:FadePtr2,OFFSET _BlackPal

lbl1:      xor     eax,eax

         ASSUME  ds:_DATA2, fs:DGROUP

         MPOP    ds,es,fs,gs
         popad
         nop

ENDM

FADEPAL MACRO
        LOCAL NewFade,Faddi,lbl1

;===================== Fade Palette ===========================

         mov     ax,DGROUP
         mov     fs,ax
         mov     ax,_DATA2
         mov     ds,ax

         cmp     FadeFlag,255
         jb      NewFade

         mov     fs:_FadeON,0  ; plus fader ...

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      endl

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
;==============================================================

ENDM

;*************** Here begins the code !!!! *************


        push    bp
        mov     bp, sp

        pushad 
        MPUSH   ds,es,fs,gs




        LSDS    _DATA2, ax

;------------------------------------------------------------------------------
;           L E C T U R E   F I C H I E R S  T E X T U R E S
;------------------------------------------------------------------------------
         
         push    ds
         assume  ds:DGROUP
         LSDS    DGROUP, ax
         mov     eax,_OfsinDta         ; OFFSET in Datafile
         mov     (Ficparam3.OfsInPdf),eax
         mov     ax,DGROUP             ; prepare for PDFIK call
         mov     es,ax
         mov     bx,OFFSET Ficparam3
         pusha
         call    PDFIK_ASM             ; call function 2 (extract+alloc)
         popa
         mov     ax,(Ficparam3.BufSeg) ; where is the file in mem ?
         pop     ds
         assume  ds:_DATA2
         mov     mapping,ax


         push    ds
         assume  ds:DGROUP
         LSDS    DGROUP, ax
         mov     eax,_OfsinDta         ; OFFSET in Datafile
         mov     (Ficparam2.OfsInPdf),eax
         mov     ax,DGROUP             ; prepare for PDFIK call
         mov     es,ax
         mov     bx,OFFSET Ficparam2
         pusha
         call    PDFIK_ASM             ; call function 2 (extract+alloc)
         popa
         mov     ax,(Ficparam2.BufSeg) ; where is the file in mem ?
         pop     ds
         assume  ds:_DATA2
         mov     ceil,ax

;------------------------------------------------------------------------------
;               L E C T U R E   F I C H I E R     L O G O
;------------------------------------------------------------------------------

         push    ds
         assume  ds:DGROUP
         LSDS    DGROUP, ax
         mov     eax,_OfsinDta         ; OFFSET in Datafile
         mov     (Ficparam4.OfsInPdf),eax
         mov     ax,DGROUP             ; prepare for PDFIK call
         mov     es,ax
         mov     bx,OFFSET Ficparam4
         pusha
         call    PDFIK_ASM             ; call function 2 (extract+alloc)
         popa
         mov     ax,(Ficparam4.BufSeg) ; where is the file in mem ?
         pop     ds
         assume  ds:_DATA2
         mov     logo,ax


;------------------------------------------------------------------------------
;                           S E T M O D E     X
;------------------------------------------------------------------------------

        mov     ax, DGROUP
        mov     ds, ax

        push    m320x200x256p ;60Hz
        call    _SetVGA
        add     sp,2

        mov     ax, _DATA2
        mov     ds, ax


;---- wait right position/row in tune ----

        MPUSH eax,bx,ds,es,fs

        ASSUME  ds:DGROUP
        ASSUME  fs:_DATA2
        mov     ax,DGROUP
        mov     ds,ax
        mov     ax,_DATA2   ; XCHG DS,FS !!!!
        mov     fs,ax

;;;;; attente bonne position music ;;;;;
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
         
         ASSUME  ds:_DATA2
         ASSUME  fs:DGROUP

         MPOP eax,bx,ds,es,fs


;------------------------------------------

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         mov     ax,DGROUP
         mov     fs,ax
         mov     ax,_DATA2
         mov     ds,ax
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


; init ....
          mov     Termine,0

         ASSUME ds:_DATA2, fs:DGROUP

         mov     fs:_FadeON,0
         mov     FadeFlag,0

         mov     FadePtr1,OFFSET _BlackPal  ; Black to pic for the beginning !!!
         mov     ax,fs
         mov     FadePtr1+2,ax
         mov     FadePtr2,OFFSET pal
         mov     ax,ds
         mov     FadePtr2+2,ax

         mov     fs:_FrameCounter,0
         mov     Delai,0 
;------------------------------------------------------------------------------
;                      I N I T I A L I S A T I O N S
;------------------------------------------------------------------------------

        LSFS    DGROUP, ax

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

        call    _WaitVBL

        mov     fs:_FrameCounter,0


;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
;                    B O U C L E   P R I N C I P A L E
;------------------------------------------------------------------------------
        Affiche_Logo
        
        LSFS    DGROUP, ax
        mov     frame_animation, 1123
        mov     fs:_FrameCounter, 0        

;============================== MAIN LOOP ===============================
        
main_loop:
        
        LSFS    DGROUP, ax

;***** 2nd page *****
Do_a_frame:
        mov     di,fs:_WorkAdr
        cmp     WORD PTR fs:[di+2],1; _WorkAdr->flag true (previous _NextAdr) ?
        je      NextFrame           ; then construct next frame

        mov     Dest,di             ; save pointer

        FADEPAL                     ; fade palet !!!

        call    SUPER_MORFLAME      ; all code of Wolf's Morflame :-)

        ; exit

        cmp     frame_animation, 3995
        jg      endl


        TESTEND                 ; look at the tune to know if we must exit !!!!


        LSFS    DGROUP, ax

        mov     di,fs:_NextAdr       ; save adr of next buffer

        mov     bx,Dest
        mov     WORD PTR fs:[bx+2],1 ; _WorkAdr->flag = true

        jmp     Nexxxt

;******** 3rd page *********
NextFrame:
        mov     di,fs:_NextAdr
        cmp     WORD PTR fs:[di+2],1  ; _NextAdr true ?
        je      NextFrame
    
Nexxxt:
        mov     Dest,di               ; save pointer

        FADEPAL                       ; fade palet !!!

        call    SUPER_MORFLAME        ; all code of Wolf's Morflame :-)

        ; exit

        cmp     frame_animation, 3995
        jg      endl

        TESTEND       ; look at the tune to know if we must exit !!!!

        LSFS   DGROUP, ax

        mov    bx,Dest
        mov    WORD PTR fs:[bx+2],1     ; _NextAdr->flag = true


        mov     ax,DGROUP
        mov     fs,ax

        in      al, 60h                            ; buffer clavier
        cmp     al, 78                             ; '+' ?
        jnz     @F
        mov     fs:_CPUtime, 1
        mov     cpu_flag, 1
        Free_Keyboard
@@:     cmp     al, 74                             ; '-' ?
        jnz     @F
        mov     fs:_CPUtime, 0
        mov     cpu_flag, 0
        Free_Keyboard
@@:     cmp     al, 68                             ; 'F10' ?
        jnz     @F
        mov     precision, 0
        mov     Automatic,0
        Free_Keyboard
@@:     cmp     al, 87                             ; 'F11' ?
        jnz     @F
        mov     precision, 1
        mov     Automatic,0
        Free_Keyboard

@@:     cmp     al, 39h                            ; space bar ???
        jne     @F
        mov     fs:_SpaceBar,1                     ; skip part !!!
        jmp     endl

@@:     cmp     al, 1                              ; esc ?
        jnz     main_loop
        mov     fs:_ExitDemo,1                     ; EXIT DEMO !
endl:
        Free_Keyboard

;============================= END LOOP ======================================

;------------------------------------------------------------------------------
; Lib‚ration des zones m‚moires

        mov     fs:_FadeON,0 ; stop fading ...

        FREE logo
        FREE ceil
        FREE mapping

        Free_Keyboard

        MPOP    ds,es,fs,gs
        popad
        nop

        leave

        ret

error:
        xor     bx, bx
        mov     ax, 0E07h
        int     10h

        MPOP     ds,es,fs,gs
        popad
        nop

        leave

        ret

Part1 ENDP

SUPER_MORFLAME PROC NEAR

;------------------------------------------------------------------------------
;                P R O C E D U R E  D ' A F F I C H A G E
;------------------------------------------------------------------------------

; one proc for all MAIN LOOP code

;------------ FrameCounter manip ------------
        MPUSH  eax,ebx,ecx,edx

        mov    cx,fs:_FrameCounter
        test   cx,cx
        jnz    @F
        mov    cx,1

@@:     xor    eax,eax
        mov    ax,409 ;1.6*256 ;384 ;1.5*256 486            ; 1.9*256
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
;       sbb    ecx,edx


        mov    pas_animation,ax  ; PAS_ANIMATION = 1.999 * FrameCounter

        test   Automatic,1
        jz     skip_auto_ajust

        cmp    ax,7
        jle    @F
        mov    precision,0      ; low detail if too many steps (slow) !!
@@:     cmp    ax,2             ; high detail if fast!
        ja     @F
        mov    precision,1
@@:

skip_auto_ajust:

        MPOP   eax,ebx,ecx,edx
;--------------------------------------------

        mov    fs:_FrameCounter,0

        CPU_TIME 48
        
        ; Fucking animation processing ... no time to do better !

        mov     ax, pas_animation
        add     frame_animation, ax

        ; D‚but vide actuellement
        
        cmp     frame_animation,  868
        jle     end_anim
        
        cmp     precision, 0
        jnz     @F
        call FLOORS_LOW_DETAIL
@@:     cmp     precision, 1
        jnz     @F
        call FLOORS_MEDIUM_DETAIL
@@:
        cmp     frame_animation,  868
        jge     a1
        jmp     end_anim


a1:     cmp     frame_animation, 1123
        jle     end_anim
        
        ; --------------
        ; first passage
        ; --------------
        
        cmp     frame_animation, 1253
        jge     a2
        SYNC_FRAME 0, sync1
        sub     cam_y, 4096
        SYNC_FRAME 1, sync1
        jmp     end_anim


        ; ---------------------------------------------
        ; cul-de-sac, looking for exit
        ; ---------------------------------------------
a2:     cmp     frame_animation, 1319
        jge     a3
        SYNC_FRAME 0, sync2
        Tourne_gauche 2
        sub     cam_y, 512        ; -10
        SYNC_FRAME 1, sync2

        jmp     end_anim        

        ; ---------------------------------------------
        ; to exit
        ; ---------------------------------------------
a3:     cmp     frame_animation, 1339
        jge     a4
        SYNC_FRAME 0, sync3
        add     cam_y, 2226
        add     cam_x, 1536
        SYNC_FRAME 1, sync3
        jmp     end_anim        
a4:     cmp     frame_animation, 1379
        jge     a5        
        SYNC_FRAME 0, sync4
        Tourne_Droite 1
        add     cam_y, 1280
        add     cam_x, 1536
        SYNC_FRAME 1, sync4
        jmp     end_anim        
        ; -------------
        ; to big room
        ; -------------
a5:     cmp     frame_animation, 1620
        jge     a11
        SYNC_FRAME 0, sync5
        add     cam_x, 2048
        SYNC_FRAME 1, sync5
        jmp     end_anim

a11:    cmp     frame_animation, 1670
        jge     a12
        SYNC_FRAME 0, sync11
        add     cam_x, 819
        Tourne_Gauche 1
        SYNC_FRAME 1, sync11
        jmp     end_anim

        ; ----------
        ; Big room
        ; ----------
a12:    cmp     frame_animation, 1675
        jl      end_anim

a13:    cmp     frame_animation, 1715
        jge     a14
        SYNC_FRAME 0, sync13
        add     cam_x, 512
        add     cam_y, 1024
        Tourne_Gauche 1
        SYNC_FRAME 1, sync13
        jmp     end_anim

a14:    cmp     frame_animation, 1770
        jge     a15
        SYNC_FRAME 0, sync14
        add     cam_y, 1024
        SYNC_FRAME 1, sync14
        jmp     end_anim
a15:    cmp     frame_animation, 1940
        jge     a16
        SYNC_FRAME 0, sync15
        add     cam_y, 1012
        add     cam_x, 128                      ; ACHTUNG (huh?)
        Tourne_Droite 1
        SYNC_FRAME 1, sync15
        jmp     end_anim

a16:    cmp     frame_animation, 2130
        jl      end_anim
a17:    cmp     frame_animation, 2440
        jge     a18
        SYNC_FRAME 0, sync17
        sub     cam_y, 1500
        SYNC_FRAME 1, sync17
        jmp     end_anim

; new cul-de-sac

a18:    cmp     frame_animation, 2440
        jge     a19
        SYNC_FRAME 0, sync18
        add     cam_y, 20
        SYNC_FRAME 1, sync18
        jmp     end_anim

a19:    cmp     frame_animation, 2530
        jge     a20
        SYNC_FRAME 0, sync19
        add     cam_y, 60
        SYNC_FRAME 1, sync19
        jmp     end_anim

a20:    cmp     frame_animation, 2720
        jge     a21
        SYNC_FRAME 0, sync20
        add     cam_y, 200
        sub     cam_x, 3
        SYNC_FRAME 1, sync20
        jmp     end_anim

a21:    cmp     frame_animation, 2880
        jge     a22
        SYNC_FRAME 0, sync21
        Tourne_Gauche 1
        SYNC_FRAME 1, sync21
        jmp     end_anim

a22:    cmp     frame_animation, 3140
        jge     a23
        SYNC_FRAME 0, sync22
        cmp     cam_y, 780736              ; for correct centering
        jge     @F
        add     cam_y, 2200
@@:     SYNC_FRAME 1, sync22
        jmp     end_anim

; The last passage .................................... !

a23:    cmp     frame_animation, 3240
        jge     a24
        SYNC_FRAME 0, sync23
        cmp     cam_y, 884736              ; for correct centering
        jge     @F
        add     cam_y, 1170
@@:     sub     cam_x, 20
        Tourne_Gauche 1
        SYNC_FRAME 1, sync23
        jmp     end_anim
a24:    cmp     frame_animation, 3580
        jge      a25
        SYNC_FRAME 0, sync24
        sub     cam_x, 1500
        SYNC_FRAME 1, sync24
        jmp     end_anim

a25:

afin:

end_anim:

        CPU_TIME 0

;-------------- pfffff !!! I don't like my code !!!!!!!! :-) ---------
; ----------------- an animation vector is better ------------------

        ret

SUPER_MORFLAME ENDP

MRF_TEXT ENDS

END
