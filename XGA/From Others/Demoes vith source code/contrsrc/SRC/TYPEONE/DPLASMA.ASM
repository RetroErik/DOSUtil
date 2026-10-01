
;*************************************************
; DOUBLE PLASMA (C) 1994 Type One / TFL-TDV Prod.
;*************************************************
                
INCLUDE PDFIK.INC ; DataFile Manager
INCLUDE VIDEO.INC ; Flamoot VGA SetUp
INCLUDE PLAYINFO.INC ; Player structures
INCLUDE KEYBOARD.INC ; keyboard macros 

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
DGROUP GROUP _DATA,_BSS
DPLASM_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
             ASSUME CS:DPLASM_TEXT,DS:DGROUP
DPLASM_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------


_DATA SEGMENT

; Quelques constantes bien utiles ......

Larg = 320       ; hauteur de l'‚cran en pixels
Haut = 800       ; largeur de l'‚cran en pixels
Windowx = 320    ; largeur fenetre
Windowy = 800    ; hauteur fenetre

Screen1 = 0
Screen2 = (Larg*Haut/2)/4

;---------------------------------------------

;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname   BYTE 'plasma.raw',0
Picname2  BYTE 'plasma2.raw',0
Picparam  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname,0,0,0,,,0>

EVEN
; plasma parameters
Yptr   WORD 0          ; pointeur sinus en y
Xptr   WORD 0          ; pointeur sinus en x
XSptr  WORD 0          ; pointeur sinus en x-scaling
Yptr2  WORD 0
Xptr2  WORD 0
XSptr2 WORD 0

cumul_step_lo DD 0
cumul_step_hi DD 0
cumul_old_lo  DD 0
cumul_old_hi  DD 0


EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE

_DATA ENDS

; donn‚es non initialis‚es
;--------------------------
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


EVEN
Picseg    WORD ?   ; ptr vers patterns segments
Picseg2   WORD ?

Timeleft  WORD ?        ; temps restant pour execution
FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?
Termine  WORD ?        ; flag pour terminer !!!

CurStep WORD ?         ; current step !!!


_BSS ENDS

DPLASM_TEXT SEGMENT
     PUBLIC _StartDouble
     EXTRN _AveragePAL: FAR


ALIGN
EVEN
; Point d'entr‚e de l'intro !!!!!
;---------------------------------
_StartDouble PROC FAR

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
         call    DPlasma             ; !!!!! plasma part !!!!!
;--------------------------------------

         mov     ax,0a000h           ; Clear screen
         mov     es,ax
         mov     dx,3c4h
         mov     ax,0f02h
         out     dx,ax
         xor     eax,eax
         xor     di,di
         mov     cx,65536/4
         rep     stosd
     
         MPOP ds,es,fs,gs
         popad
         nop

         leave                       ; restore stack
                                     ; mov sp,bp + pop bp
         retf

_StartDouble ENDP


;==============================================================================
;============================ Plasma part =====================================
;==============================================================================

DPlasma PROC NEAR

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

; charger 1Šre image

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

; charger 2Šme image

         mov     ax,DGROUP
         mov     es,ax
         mov     bx,OFFSET Picparam
         mov     Picparam.DtaOfsFil,OFFSET Picname2 ; name of pic 2
         pusha
         call    PDFIK_ASM
         popa
         mov     ax,Picparam.BufSeg
         mov     Picseg2,ax

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

         mov     bx,_StartAdr
         mov     WORD PTR[bx],Screen1         ; _StartAdr->base = 0
         mov     bx,_WorkAdr
         mov     WORD PTR[bx],Screen2         ; _WorkAdr->base
         mov     WORD PTR[bx+2],0             ; _WorkAdr->flag=false
         mov     _Triple,0                    ; double buffering

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

         mov     _SyncFlag,1
         VSYNC
EVEN
MainPlasma: ; -= VSYNC =-

wait_for_VBL:                       ; wait for Sync Flag
         cmp     _SyncFlag,1
         jne      wait_for_VBL
         mov     _SyncFlag,0

         NEXTSTEP                   ; new step !!!

         mov     cx,CurStep   ; nombre de VBLs perdues...
@@:                           ; (incrementer suivant le nb de VBLs)
         add     Yptr,6       ; pointeur sinus vertical (moving)
         and     Yptr,1023
         add     Xptr,4       ; pointeur sinus horizontal (moving)
         and     Xptr,1023
         add     XSptr,8      ; pointeur sinus horizontal (scaling)
         and     XSptr,1023
         add     Yptr2,4      ; pointeurs 2Šme plasma
         and     Yptr2,1023
         add     Xptr2,6
         and     Xptr2,1023
         add     XSptr2,6
         and     XSptr2,1023
         dec     cx           ; loop    @B
         jnz     @B


         cmp     FadeFlag,255
         jb      NewFade

         cmp     Termine,1    ; Terminer si dernier fade fini
         je      GoOutPlasma

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

         SHOWTIME 32

         call    DPlasma_It

         SHOWTIME 0

         mov    bx,_WorkAdr          ; New screen base
         mov    WORD PTR[bx+2],1     ; _WorkAdr->flag = true

         LOOP_UNTIL_KEY MainPlasma

GoOutPlasma:

        FLUSH_KEYBUF                  ; Flush keyboard buffer !!! ;-)

        mov     _FadeON,0             ; to be sure ....

;----- EXIT -----

        STARTUP

        mov     ax,Picseg2            ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

        mov     ax,Picseg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

        popad
        nop
        ret

DPlasma ENDP

;==============================================================================

ALIGN
EVEN
DPlasma_It PROC NEAR                  ; mouvement du plasma

YSINE TEXTEQU <1234h>

        push    ds


; ------- 1st plasma -------

; patcher sinus vertical (moving) !!!!
        mov     si,OFFSET _SinusTbl    ; base sinus !
        add     si,Yptr                ; + offset
        mov     di,OFFSET patch_it+2   ; 1er patch !
        xor     dx,dx
        mov     cx,40                  ; pour tous les mov al,[bx+...]
EVEN
@@:
        lodsw                          ; charger sinus*256
        sal     ax,6
        xor     al,al
        add     ax,dx
        inc     dx
        mov     cs:[di],ax             ; poker dans le code
        add     di,4                   ; patcher les offsets dans le code !
        lodsw
        sal     ax,6
        xor     al,al
        add     ax,dx
        inc     dx
        mov     cs:[di],ax
        add     di,5
        dec     cx                     ; loop    @B
        jnz     @B

; patcher sinus horizontal (scaling) !!!!
        mov     si,OFFSET _SinusTbl    ; base sinus !
        add     si,XSptr               ; + offset
        mov     di,OFFSET patch_it+2   ; 1er patch !
        mov     cx,40                  ; pour tous les mov al,[bx+...]
EVEN
@@:     lodsw                          ; charger sinus*256
        sar     ax,2
        add     cs:[di],ax             ; poker dans le code
        add     di,4                   ; patcher les offsets dans le code !
        lodsw
        sar     ax,2
        add     cs:[di],ax
        add     di,5
        dec     cx                     ; loop    @B
        jnz     @B

; ------- 2nd plasma --------

; patcher sinus vertical (moving) no 2 !!!!
        mov     si,OFFSET _SinusTbl    ; base sinus !
        add     si,Yptr2               ; + offset
        mov     di,OFFSET patch_it2+2  ; 1er patch !
        xor     dx,dx
        mov     cx,40                  ; pour tous les mov al,[bx+...]
EVEN
@@:
        lodsw                          ; charger sinus*256
        sal     ax,6
        xor     al,al
        add     ax,dx
        inc     dx
        mov     cs:[di],ax             ; poker dans le code
        add     di,4                   ; patcher les offsets dans le code !
        lodsw
        sal     ax,6
        xor     al,al
        add     ax,dx
        inc     dx
        mov     cs:[di],ax
        add     di,5
        dec     cx                     ; loop    @B
        jnz     @B

; patcher sinus horizontal (scaling) no 2 !!!!
        mov     si,OFFSET _SinusTbl    ; base sinus !
        add     si,XSptr2              ; + offset
        mov     di,OFFSET patch_it2+2  ; 1er patch !
        mov     cx,40                  ; pour tous les mov al,[bx+...]
EVEN
@@:     lodsw                          ; charger sinus*256
        sar     ax,2
        add     cs:[di],ax             ; poker dans le code
        add     di,4                   ; patcher les offsets dans le code !
        lodsw
        sar     ax,2
        add     cs:[di],ax
        add     di,5
        dec     cx                     ; loop    @B
        jnz     @B 

        push    fs

;------------ 1st plasma ---------------

; 2D plasming

        mov     ax,0a000h             ; Screen base
        mov     es,ax
        mov     di,_WorkAdr           ; offset 0
        mov     di,WORD PTR[di]       ; screen page
        add     di,50*80
        push    ds                    ; mov     ax,ds
        pop     gs                    ; mov     gs,ax
        mov     si,OFFSET _SinusTbl
        add     si,Xptr
        xor     bp,bp
        mov     ax,PicSeg             ; Picture base
        add     ax,(768+32) SHR 4     ; Skip Alchemy Header
        mov     ds,ax

        mov     cx,150                ; 200 lines
EVEN
Fill: ; 1st plasma

        mov    bx,gs:[si]             ; pointeur sur table sinus
        sar    bx,2
        add    si,2
        add    bx,bp                  ; nouveau X-sinus

; calcul d'une ligne ...
patch_it LABEL WORD
        REPT   40                     ; 320 pixels width
        mov    al,[bx+YSINE]          ; prendre valeur sur map
        mov    ah,[bx+YSINE]
        stosw
        ENDM

        add     bp,256                ; ligne suivante
        add     di,80

        dec     cx
        jnz     Fill

; ------------ 2nd plasma -------------

        mov     di,WORD PTR gs:[_WorkAdr] ; offset 0
        mov     di,WORD PTR gs:[di]       ; screen page
        add     di,50*80
        mov     si,OFFSET _SinusTbl
        add     si,WORD PTR gs:[Xptr2]
        xor     bp,bp
        mov     ax,gs:WORD PTR[PicSeg2]   ; Picture base no 2
        add     ax,(768+32) SHR 4         ; Skip Alchemy header  
        mov     ds,ax

        add     di,80
        mov     cx,150                 ; 200 lines
EVEN
Fill2: ; 2nd plasma

;select new trame

        mov    bx,gs:[si]             ; pointeur sur table sinus
        sar    bx,2
        add    si,2
        add    bx,bp                  ; nouveau X-sinus

; calcul d'une ligne ...
patch_it2 LABEL WORD
        REPT   40                     ; 320 pixels width
        mov    al,[bx+YSINE]          ; prendre valeur sur map
        mov    ah,[bx+YSINE]
        stosw
        ENDM

        add     bp,256                ; ligne suivante
        add     di,80

        dec     cx
        jnz     Fill2

        pop     fs

        pop     ds

        ret

DPlasma_It ENDP

;==============================================================================

DPLASM_TEXT ENDS

     END

