
;**************************************************
; TRANSFORMATION (C) 1994 Type One / TFL-TDV Prod.
;**************************************************

INCLUDE PDFIK.INC ; DataFile Manager
INCLUDE VIDEO.INC ; Flamoot VGA SetUp
INCLUDE PLAYINFO.INC ; Player structures
INCLUDE KEYBOARD.INC ; Keyboard macros

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
DGROUP GROUP _DATA,_BSS
TRANS_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
       ASSUME CS:TRANS_TEXT,DS:DGROUP
TRANS_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------

_DATA SEGMENT

; Quelques constantes bien utiles ......

Larg = 160       ; hauteur de l'‚cran en pixels
Haut = 67        ; largeur de l'‚cran en pixels
Windowx = 160    ; largeur fenetre
Windowy = 67     ; hauteur fenetre

Screen1 = 0
Screen2 = (Larg*Haut/4)
Screen3 = (Larg*Haut/4)*2

;---------------------------------------------


;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'magic05.raw',0
Picparam  PARAM_STRUC<2,_DATA,OFFSET _Datafile,OFFSET Picname,0,0,0,,,0>

EVEN
; transformation parameters
Yptr   WORD 0          ; pointeur sinus en y
Xptr   WORD 0          ; pointeur sinus en x
XSptr  WORD 0          ; pointeur sinus en x-scaling

cumul_step_lo DD 0
cumul_step_hi DD 0
cumul_old_lo  DD 0
cumul_old_hi  DD 0


EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE

_DATA    ENDS

;donn‚es non initialis‚es
_BSS SEGMENT

EXTRN _FrameCounter     : WORD
EXTRN _SinusTbl         : WORD ; table sinus*256 pour transformation
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

;---- param pour synchro avec zizik ----
EVEN
DebSong  WORD ?
FinSong  WORD ?


EVEN
Picseg    WORD ?        ; ptr vers segment pattern
TabSeg    WORD ?        ; ptr vers segment curves table
Timeleft  WORD ?        ; temps restant pour execution

Dest DW ?

FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?

Termine  WORD ?        ; flag pour terminer !!!

CurStep WORD ?         ; current step !!!


_BSS ENDS

TRANS_TEXT SEGMENT
     PUBLIC _StartTransf
     EXTRN _AveragePAL : FAR


; Point d'entr‚e de l'intro !!!!!
;---------------------------------
ALIGN
EVEN
_StartTransf PROC FAR

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
         push    m160x67x256c        ; set 7-mode if full VGA compatible
         jmp     FullVGA
@@:      push    m320x67x256c
FullVGA: call    _SetVGA
         add     sp,2

         STARTUP
;--------------------------------------
         call    Transf              ; !!!!! Transformation part !!!!!
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

_StartTransf ENDP


;==============================================================================
;============================ Transf part =====================================
;==============================================================================
ALIGN
EVEN
Transf PROC NEAR

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


;---------------

         mov     ah,48h                ; MALLOC
         mov     bx,(65535 SHR 4)+1    ; memory requested
         int     21h
         mov     TabSeg,ax             ; Segment address returned

; do precalculations   (calculer table des courbes !!!)

         mov     ax,TabSeg             ; my table
         mov     es,ax
         xor     di,di
         mov     bx,-256               ; amplitude de base
         mov     cx,256                ; 256 courbes (curves)
EVEN        
looper:
         mov     si,OFFSET _SinusTbl   ; Sine table
         push    cx
         mov     cx,256                ; 256 valeurs/courbe
@@:
         lodsw
         imul    bx                    ; * amplitude
         mov     al,ah                 ; normaliser
         sal     al,1
         stosb                         ; sauver valeur
         dec     cx                    ; loop    @B
         jnz     @B
         pop     cx
         add     bx,2                  ; calculer amplitude suivante
         dec     cx                    ; loop    looper
         jnz     looper

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
         mov     FadePtr1,OFFSET _WhitePal ;_BlackPal  ; Black to pic for the beginning !!!
         mov     ax,ds
         mov     FadePtr1+2,ax
         mov     FadePtr2,32
         mov     ax,Picseg
         mov     FadePtr2+2,ax
;         mov     ax,_FrameCounter
;         mov     Delai,ax
         mov     _FrameCounter,0
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
MainTransf: ; -= VSYNC =-

;***** 2nd page *****
Do_a_frame:
         mov  di,_WorkAdr
         cmp  WORD PTR[di+2],1 ; _WorkAdr->flag true (previous _NextAdr) ?
         je   NextFrame        ; then construct next frame

         mov  Dest,di          ; save pointer

         NEXTSTEP              ; new step !!!

         mov     cx,CurStep    ; nombre de VBLs perdues...
@@:                            ; (incrementer suivant le nb de VBLs)
         add     Yptr,6        ; pointeur sinus vertical (moving)
         and     Yptr,1023
         add     Xptr,4        ; pointeur sinus horizontal (moving)
         and     Xptr,1023
         add     XSptr,8       ; pointeur sinus horizontal (scaling)
         and     XSptr,1023
         inc     cs:[Patchon+1]
         and     cs:[Patchon+1],255

         dec     cx            ; loop    @B
         jnz     @B

         cmp     FadeFlag,255
         jb      NewFade

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      GoOutTransf

         mov     _FadeON,0    ; don't set _TmpPal anymore ...
         jmp     @F
NewFade: mov     ax,FadeFlag  ; average Black-MyPal
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
         mov     _FadeON,1            ; set new PAL during next VR !!!!
         mov     cx,CurStep
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     Faddi
         inc     cx
Faddi:   add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     Faddi
@@:

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

         SHOWTIME 48

         SHOWTIME 32

         call    Transf_It   ; map the MAP !!!

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

         NEXTSTEP              ; new step !!!!

         mov     cx,CurStep    ; nombre de VBLs perdues...
@@:                            ; (incrementer suivant le nb de VBLs)
         add     Yptr,6        ; pointeur sinus vertical (moving)
         and     Yptr,1023
         add     Xptr,4        ; pointeur sinus horizontal (moving)
         and     Xptr,1023
         add     XSptr,8       ; pointeur sinus horizontal (scaling)
         and     XSptr,1023
         inc     cs:[Patchon+1]
         and     cs:[Patchon+1],255

         dec     cx            ; loop    @B
         jnz     @B

         cmp     FadeFlag,255
         jb      NewFade2

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      GoOutTransf

         mov     _FadeON,0    ; don't set _TmpPal anymore ...
         jmp     @F
NewFade2:mov     ax,FadeFlag  ; average Black-MyPal
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
         mov     _FadeON,1            ; set new PAL during next VR !!!!
         mov     cx,CurStep
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     Faddi2
         inc     cx
Faddi2:  add     FadeFlag,4           ; inc fade ..
         dec     cx
         jnz     Faddi2
@@:

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

         SHOWTIME 48

         SHOWTIME 32

         call    Transf_It   ; map the MAP

         mov    bx,Dest
         mov    WORD PTR[bx+2],1     ; _WorkAdr->flag = true

         SHOWTIME 0

         LOOP_UNTIL_KEY MainTransf

         jmp     GoOutTransf

;===============================================================

;===================== No VGA compatible code ==================

NoCompatible:  ; works in standard 320 width --> software pixel doubling (slow)

         mov     bx,_StartAdr
         mov     WORD PTR[bx],Screen1   ; _StartAdr->base = 0
         mov     bx,_WorkAdr
         mov     WORD PTR[bx],Screen2*2 ; _WorkAdr->base
         mov     WORD PTR[bx+2],0       ; _WorkAdr->flag = false
         mov     _Triple,0              ; triple buffering
         mov     _SyncFlag,1
         VSYNC

EVEN
BMainTransf: ; -= VSYNC =-

wait_for_VBL:                       ; wait for Sync Flag
         cmp     _SyncFlag,1
         jne      wait_for_VBL
         mov     _SyncFlag,0

         NEXTSTEP                   ; new step !!!

         mov     cx,CurStep         ; nombre de VBLs perdues...
@@:                           ; (incrementer suivant le nb de VBLs)
         add     Yptr,6       ; pointeur sinus vertical (moving)
         and     Yptr,1023
         add     Xptr,4       ; pointeur sinus horizontal (moving)
         and     Xptr,1023
         add     XSptr,8      ; pointeur sinus horizontal (scaling)
         and     XSptr,1023
         inc     cs:[BPatchon+1]
         and     cs:[BPatchon+1],255

         dec     cx           ; loop    @B
         jnz     @B

         cmp     FadeFlag,255
         jb      BNewFade

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      GoOutTransf

         mov     _FadeON,0    ; don't set _TmpPal anymore ...
         jmp     @F
BNewFade:mov     ax,FadeFlag  ; average Black-MyPal
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
         mov     _FadeON,1            ; set new PAL during next VR !!!!
         mov     cx,CurStep
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

         SHOWTIME 48

         SHOWTIME 32

         mov    di,_WorkAdr
         mov    Dest,di

         call   BTransf_It          ; map the MAP !!!

         mov    bx,_WorkAdr
         mov    WORD PTR[bx+2],1     ; _WorkAdr->flag = true

         SHOWTIME 0

         LOOP_UNTIL_KEY BMainTransf

;===============================================================



GoOutTransf:

        FLUSH_KEYBUF                  ; Flush keyboard buffer !!! ;-)

        mov     _FadeON,0             ; to be sure ....

;----- EXIT -----

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

Transf ENDP


;==============================================================================

;----------------- 7-mode algorithm --> hardware pixel doubling ---------------

ALIGN
EVEN
Transf_It PROC NEAR                   ; mouvement transformation

YSINE TEXTEQU <1234h>

        push    ds

; patcher sinus vertical (moving) !!!!
        mov     si,OFFSET _SinusTbl    ; base sinus !
        add     si,Yptr                ; + offset
        mov     di,OFFSET patchmoi+8   ; 1er patch !
        xor     dx,dx
        mov     cx,Windowx/2           ; pour tous les mov al,[bx+...]
EVEN
@@:
        lodsw                          ; charger sinus*256
        sal     ax,8
        xor     al,al
        add     ax,dx
        inc     dx
        mov     cs:[di],ax             ; poker dans le code
        add     di,9
        lodsw
        sal     ax,8
        xor     al,al
        add     ax,dx
        inc     dx
        mov     cs:[di],ax
        add     di,11                  ; patcher les offsets dans le code !
        dec     cx                     ; loop    @B
        jnz     @B

; patcher sinus horizontal (scaling) !!!!
        mov     si,OFFSET _SinusTbl    ; base sinus !
        add     si,XSptr               ; + offset
        mov     di,OFFSET patchmoi+8   ; 1er patch !
        mov     cx,Windowx/2           ; pour tous les mov al,[bx+...]
EVEN
@@:     lodsw                          ; charger sinus*256
        sar     ax,1
        add     cs:[di],ax             ; poker dans le code
        add     di,9
        lodsw
        sar     ax,1
        add     cs:[di],ax
        add     di,11                  ; patcher les offsets dans le code !
        dec     cx                     ; loop    @B
        jnz     @B

; 2D plasming

        mov     ax,0a000h             ; Screen base
        mov     es,ax
        mov     di,Dest               ; offset 0 (Screen)
        mov     di,WORD PTR[di]
        shl     di,2                  ; *4
        mov     ax,PicSeg             ; Picture base
        add     ax,(768+32) SHR 4     ; Skip Alchemy header
        mov     gs,ax
        mov     ax,TabSeg             ; Curves table segment
        mov     ds,ax
    

        mov     cx,Windowy            ; 67 lines
Patchon LABEL WORD
        mov     si,0000h
        add     si,256*(256-Windowy)/4

EVEN
Fill:
Patchmoi LABEL WORD
        REPT   Windowx/2
        lodsw
        mov    bh,al
        mov    bl,bh
        mov    al,gs:[bx+YSINE]
        mov    bh,ah
        mov    bl,bh
        mov    ah,gs:[bx+YSINE]
        stosw
        ENDM

        IF (Larg-Windowx) NE 0
           add di,Larg-Windowx
        ENDIF

        add    si,256-Windowx

        dec    cx
        jnz    Fill

        pop     ds

        ret

Transf_It ENDP

;----------- No VGA compatible algorithm --> software pixel doubling -----------

ALIGN
EVEN
BTransf_It PROC NEAR                   ; mouvement transformation

YSINE TEXTEQU <1234h>

        push    ds

; patcher sinus vertical (moving) !!!!
        mov     si,OFFSET _SinusTbl    ; base sinus !
        add     si,Yptr                ; + offset
        mov     di,OFFSET Bpatchmoi+8  ; 1er patch !
        xor     dx,dx
        mov     cx,Windowx             ; pour tous les mov al,[bx+...]
EVEN
@@:
        lodsw                          ; charger sinus*256
        sal     ax,8
        xor     al,al
        add     ax,dx
        inc     dx
        mov     cs:[di],ax             ; poker dans le code
        add     di,13
        dec     cx
        jnz     @B

; patcher sinus horizontal (scaling) !!!!
        mov     si,OFFSET _SinusTbl    ; base sinus !
        add     si,XSptr               ; + offset
        mov     di,OFFSET Bpatchmoi+8  ; 1er patch !
        mov     cx,Windowx             ; pour tous les mov al,[bx+...]
EVEN
@@:     lodsw                          ; charger sinus*256
        sar     ax,1
        add     cs:[di],ax             ; poker dans le code
        add     di,13
        dec     cx
        jnz     @B

; 2D plasming

        mov     ax,0a000h             ; Screen base
        mov     es,ax
        mov     di,Dest               ; offset 0 (Screen)
        mov     di,WORD PTR[di]
        shl     di,2                  ; *4
        mov     ax,PicSeg             ; Picture base
        add     ax,(768+32) SHR 4     ; Skip Alchemy header
        mov     gs,ax
        mov     ax,TabSeg             ; Curves table segment
        mov     ds,ax
    

        mov     cx,Windowy            ; 70 lines
BPatchon LABEL WORD
        mov     si,0000h
        add     si,256*(256-Windowy)/4

EVEN
BFill:
BPatchmoi LABEL WORD
        REPT   Windowx
        lodsb
        mov    bh,al
        mov    bl,bh
        mov    al,gs:[bx+YSINE]
        mov    ah,al
        stosw
        ENDM

        IF (Larg-Windowx) NE 0
           add di,(Larg-Windowx)*2
        ENDIF

        add    si,256-Windowx

        dec    cx
        jnz    BFill

        pop     ds

        ret

BTransf_It ENDP


;==============================================================================

TRANS_TEXT ENDS

     END

