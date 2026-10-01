;*******************************************
;* Unlimited Sprites by SAM / TFL-TDV 1994 *
;*******************************************

include video.inc ; pour les modes video
include pdfik.inc ; pour decompacter l'img ...
include playinfo.inc ; player
include keyboard.inc


.386


DGROUP GROUP _DATA, _BSS

unlimit SEGMENT DWORD PUBLIC USE16 'CODE'
        ASSUME CS:unlimit,DS:_SAMDATA,FS:DGROUP
unlimit ENDS

_DATA SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA ENDS

_BSS SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS ENDS

_SAMDATA SEGMENT DWORD PRIVATE USE16 'FAR_DATA'
_SAMDATA ENDS


_BSS SEGMENT

EXTRN _FrameCounter     : WORD
EXTRN _SpaceBar         : WORD
EXTRN _MichFlag         : WORD
EXTRN _ExitDemo         : WORD
EXTRN _CPUtime          : WORD
EXTRN _StartAdr         : WORD
EXTRN _WorkAdr          : WORD
EXTRN _NextAdr          : WORD
EXTRN _Triple           : WORD
EXTRN _SyncFlag         : WORD
EXTRN _ShiftOfs         : WORD
;!!!!!!!!!! synchro avec music !!!!!!!!!!!!
EXTRN _MP               : DWORD ; extern ModulePlayer * MB
EXTRN _ReplayInfo       : mpInformation

EXTRN _TmpPal           : BYTE
EXTRN _FadeON           : WORD


;---- param pour synchro avec zizik ----
EVEN
DebSong  WORD ?
FinSong  WORD ?

_BSS ENDS


_DATA SEGMENT

EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picture BYTE 'rip2_img.raw',0
Pictureparam PARAM_STRUC <2,DGROUP,OFFSET _Datafile,OFFSET Picture,0,0,0,,,0>

EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE


_DATA ENDS


_SAMDATA SEGMENT

Palette LABEL BYTE
INCLUDE cac_4848.pal

Cacodemon00 LABEL BYTE
INCLUDE cac_4848.nd0 ; data non nul !!!

Cacodemon10 LABEL BYTE
INCLUDE cac_4848.nd1 ; data non nul !!!

Cacodemon20 LABEL BYTE
INCLUDE cac_4848.nd2 ; data non nul !!!

Cacodemon30 LABEL BYTE
INCLUDE cac_4848.nd3 ; data non nul !!!



Cacodemon01 LABEL BYTE
INCLUDE cac_4948.nd0 ; data non nul !!!

Cacodemon11 LABEL BYTE
INCLUDE cac_4948.nd1 ; data non nul !!!

Cacodemon21 LABEL BYTE
INCLUDE cac_4948.nd2 ; data non nul !!!

Cacodemon31 LABEL BYTE
INCLUDE cac_4948.nd3 ; data non nul !!!




Cacodemon02 LABEL BYTE
INCLUDE cac_5048.nd0 ; data non nul !!!

Cacodemon12 LABEL BYTE
INCLUDE cac_5048.nd1 ; data non nul !!!

Cacodemon22 LABEL BYTE
INCLUDE cac_5048.nd2 ; data non nul !!!

Cacodemon32 LABEL BYTE
INCLUDE cac_5048.nd3 ; data non nul !!!




Cacodemon03 LABEL BYTE
INCLUDE cac_5148.nd0 ; data non nul !!!

Cacodemon13 LABEL BYTE
INCLUDE cac_5148.nd1 ; data non nul !!!

Cacodemon23 LABEL BYTE
INCLUDE cac_5148.nd2 ; data non nul !!!

Cacodemon33 LABEL BYTE
INCLUDE cac_5148.nd3 ; data non nul !!!

Lissajou LABEL WORD
INCLUDE lissajo3.dat

Coord DW Lissajou
MaxCoord EQU $-2 ; adr derniere donnee !!!

ActPage DW 0
SmallTable DW 0A000h,0A400h,0A800h,0AC00h ;; sont-ce les adr des pages ??? suspense !

PictureSeg DW ? ; enfin une donne non init !!!

Timeleft  WORD ?        ; temps restant pour execution
FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?
Termine DW 0

ProcTbl LABEL WORD
DW PutSprite0
DW PutSprite1
DW PutSprite2
DW PutSprite3

_SAMDATA ENDS


MPUSH   MACRO reg1:REQ,reg2:VARARG   ;; Vive Y.Roggeman/Greg & ses Macros
        push reg1                    ;; recursives !!!!!!! yahouuuuu !!!
        IFNB <reg2>
        MPUSH reg2
        ENDIF
        ENDM

MPOP    MACRO reg1:REQ,reg2:VARARG   ;; bis bis !!!
        IFNB <reg2>                  ;; type brol = record....
        MPOP reg2                    ;; donc ‡a fait 20 bytes !!!
        ENDIF                        ;; donc 1 word ....
        pop reg1                     ;; brol je dis struct !!!
        ENDM


SetPage       MACRO

              MOV DX,3D4h
              MOV AX,actpage ;; 0,1,2 ou 3 cnf bible v3220pa.asm
              MOV CL,2
              ROR AL,CL
              MOV AH,0Ch ;; offset high
              XCHG AL,AH ;; ou AH,AL :)
              OUT DX,AX
ENDM

SHOWTIME MACRO col
        LOCAL lbl1
        test            fs:_CPUtime,1
        jz              lbl1
        COLOR           col
lbl1:

ENDM


unlimit SEGMENT
PUBLIC _MyPart
EXTRN _WaitVBL:FAR
EXTRN _AveragePAL:FAR


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

;; avant appel macro on a DS = _samdata ; ES = page ecran ; FS = DGROUP
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
Faddi:   add     FadeFlag,6 ;4           ; inc fade ..
         dec     cx
         jnz     Faddi
         MPOP    ax,cx
lbl1:

;;;;;;; plante pas !!!!!!

;==============================================================
ENDM


_MyPart PROC FAR ; en entree debpos,debrow,finpos,finrow

              PUSH BP ; cadre de pile
              MOV BP,SP

              PUSHAD ; save all reg
              MPUSH GS,FS,ES,DS

              MOV AX,DGROUP
              MOV FS,AX ; init FS !!!

              MOV AX,_SAMDATA
              MOV DS,AX

              MOV WORD PTR FS:_MichFlag,1 ; TRUE
              MOV FadeFlag,255
              MOV WORD PTR _FadeOn,0

              mov dx,3d4h
              mov ax,000ch
              out dx,ax
              mov ax,000dh   ; set page to 0
              out dx,ax 

         mov     FadePtr1,OFFSET _BlackPal  ; Black to pic for the beginning !!!
         mov     ax,fs
         mov     FadePtr1+2,ax
         mov     FadePtr2,OFFSET palette
         MOV     AX,DS
         MOV     FadePtr2+2,AX

; ------------------------------------------
; recup les param sur le stack ... debut-fin
; ------------------------------------------

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

; -----------------
; wait the begining
; -----------------

; XCHG FS,DS

        pushad
        MPUSH   ds,es,fs,gs

        ASSUME  ds:DGROUP
        ASSUME  fs:_SAMDATA
        mov     ax,DGROUP
        mov     ds,ax
        mov     ax,_SAMDATA   ; XCHG DS,FS !!!!
        mov     fs,ax

WaitPos:     mov     _ReplayInfo.numChannels,4 ; 4 voices

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

         ASSUME  ds:_SAMDATA
         ASSUME  fs:DGROUP
         MPOP    ds,es,fs,gs
         popad
         nop

; set video mode

      push ds
      push m320x200x256p
      call _SetVga
      add sp,2
      pop ds

; clear video memory

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,00001111b
              out dx,al

       mov   ax,0A000h                 ;Remplit les quatre plans de bits
                                       ;avec le code couleur 00h et efface
       mov   es,ax                                        ;ainsi l'‚cran
       xor   ax,ax
       mov   cx,8000h
       rep   stosw


; poker la palette

              MOV DX,3C8h
              XOR AL,AL
              OUT DX,AL
              INC DX
              MOV SI,OFFSET Palette ; attention … DS
              CLD
              MOV CX,256*3
              REP OUTSB

; decruncher img ...

         PUSH DS

         mov     eax,DWORD PTR FS:[_OfsinDta]         ; OFFSET in Datafile
         mov     DWORD PTR FS:[Pictureparam.OfsInPdf],eax
         mov     ax,DGROUP             ; prepare for PDFIK call

         mov     es,ax
         mov     bx,OFFSET Pictureparam
         pusha
         call    PDFIK_ASM             ; call function 2 (extract+alloc)
         popa

         POP DS

         MOV BP,OFFSET SmallTable ; via ds

         mov     ax,FS:Pictureparam.BufSeg ; where is the file in mem ?
         MOV     PictureSeg,AX

; poker le fond ...
              CALL _WaitVBL
; plan 0
              push ds
              pop gs ; copie DS pour acceder smalltable

              mov ax,PictureSeg
              mov DS,ax

              mov dx,3C4h ; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,1 ; only plan 0
              out dx,al

              MOV CX,4
              MOV BX,BP

FillAllPage0: XOR SI,SI
              XOR DI,DI
              MOV AX,GS:[BX] ; BX ptr vers smalltable
              MOV ES,AX

              PUSH CX
              MOV CX,16000

FillPlan0:    MOVSB
              ADD SI,3
              LOOP FillPlan0

              POP CX
              ADD BX,2 ; pas 1 :) table de word
              LOOP FillAllPage0

              CALL _WaitVBL
; plan 1
              mov dx,3C4h ; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,2 ; only plan 1
              out dx,al

              MOV CX,4
              MOV BX,BP

FillAllPage1: MOV SI,1
              XOR DI,DI
              MOV AX,GS:[BX]
              MOV ES,AX

              PUSH CX
              MOV CX,16000

FillPlan1:    MOVSB
              ADD SI,3
              LOOP FillPlan1

              POP CX
              ADD BX,2 ; pas 1 :) table de word
              LOOP FillAllPage1

              CALL _WaitVBL
; plan 2
              mov dx,3C4h ; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,4 ; only plan 2
              out dx,al

              MOV CX,4
              MOV BX,BP

FillAllPage2: MOV SI,2
              XOR DI,DI
              MOV AX,GS:[BX]
              MOV ES,AX

              PUSH CX
              MOV CX,16000

FillPlan2:    MOVSB
              ADD SI,3
              LOOP FillPlan2

              POP CX
              ADD BX,2 ; pas 1 :) table de word
              LOOP FillAllPage2

              CALL _WaitVBL
; plan 3
              mov dx,3C4h ; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,8 ; only plan 3
              out dx,al

              MOV CX,4
              MOV BX,BP ; grrrr

FillAllPage3: MOV SI,3
              XOR DI,DI
              MOV AX,GS:[BX]
              MOV ES,AX

              PUSH CX
              MOV CX,16000

FillPlan3:    MOVSB
              ADD SI,3
              LOOP FillPlan3

              POP CX
              ADD BX,2 ; pas 1 :) table de word
              LOOP FillAllPage3

              PUSH GS
              POP DS ; recupere ds

; affiche le sprite !!!

Demo:         MOV BX,Coord ; Coord = adr !!!
              MOV DI,[BX]
              ADD BX,2
              CMP BX,MaxCoord
              JB Okkk
              MOV Coord,OFFSET Lissajou
              JMP Newpage
Okkk:         MOV Coord,BX

Newpage:      MOV BX,ActPage
              SHL BX,1 ; bugggggggggggggggggg stupiiiiiiiiiiiiiiiiiiiiide
              MOV ES,[BX+SmallTable]
              INC ActPage
              AND ActPage,3 ; 000...00011b

              SetPage
              
Cool:         CMP WORD PTR FS:_FrameCounter,3
              JB Cool
              MOV WORD PTR FS:_FrameCounter,0

              MOV BX,DI
              SHR DI,1
              SHR DI,1
              AND BX,3 ; 000...00011b
              SHL BX,1

              SHOWTIME 32
              CALL [BX+ProcTbl]
              SHOWTIME 0


;; ici DS = _samdata ; ES = page ecran ; FS = DGROUP

              FadePal

         pushad
         MPUSH    ds,es,fs,gs

;==============================================
         mov      ax,DGROUP
         mov      ds,ax                   ; xchg FS,DS
         mov      ax,_SAMDATA
         mov      fs,ax

         ASSUME   ds:DGROUP,fs:_SAMDATA

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
         cmp     ax,WORD PTR [FinSong] ; is it time ????
         jb      @F                      ; to fade off ???

         mov     word ptr fs:Termine,1

         cmp     FadePtr2,OFFSET _BlackPal
         je      @F
         mov     fs:FadeFlag,0
         mov     eax,DWORD PTR fs:[FadePtr2]
         mov     DWORD PTR fs:[FadePtr1],eax   ; fade to black !!!!
         mov     ax,ds
         mov     fs:FadePtr2+2,ax
         mov     fs:FadePtr2,OFFSET _BlackPal

@@:      
         ASSUME  ds:_SAMDATA, fs:DGROUP

         MPOP    ds,es,fs,gs
         popad
         nop

         LOOPUNTILKEY Demo


Fin:

        mov     ax,40h                ; Flush keyboard buffer !!! ;-)
        mov     es,ax
        mov     ax,es:[001ah]
        mov     es:[001ch],ax

        mov     ax,Pictureseg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

              MOV WORD PTR FS:_MichFlag,0 ; FALSE

        mov     dx,3c4h
        mov     ax,0f02h
        out     dx,ax
        xor     di,di
        mov     ax,0a000h
        mov     es,ax
        xor     eax,eax
        cld
        mov     cx,16384   
        rep     stosd

              MPOP GS,FS,ES,DS
              POPAD
              NOP

              mov sp,bp
              pop bp

              retf
_MyPart ENDP


PutSprite0     PROC ;; on entry : ES:DI = OFFSET WHERE TO PUT THE SPRITE !!!

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,1 ;; only plan 0
              out dx,al

              MOV SI,OFFSET Cacodemon00
              include cac_4848.as0
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,2 ;; only plan 1
              out dx,al

              MOV SI,OFFSET Cacodemon10
              include cac_4848.as1
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,4 ;; only plan 2
              out dx,al

              MOV SI,OFFSET Cacodemon20
              include cac_4848.as2
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,8 ;; only plan 3
              out dx,al

              MOV SI,OFFSET Cacodemon30
              include cac_4848.as3

              RET
PutSprite0 ENDP


PutSprite1     PROC ;; on entry : ES:DI = OFFSET WHERE TO PUT THE SPRITE !!!

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,1
              out dx,al

              MOV SI,OFFSET Cacodemon01
              include cac_4948.as0
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,2
              out dx,al

              MOV SI,OFFSET Cacodemon11
              include cac_4948.as1
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,4
              out dx,al

              MOV SI,OFFSET Cacodemon21
              include cac_4948.as2
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,8
              out dx,al

              MOV SI,OFFSET Cacodemon31
              include cac_4948.as3

              RET
PutSprite1 ENDP

PutSprite2     PROC ;; on entry : ES:DI = OFFSET WHERE TO PUT THE SPRITE !!!

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,1
              out dx,al

              MOV SI,OFFSET Cacodemon02
              include cac_5048.as0
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,2
              out dx,al

              MOV SI,OFFSET Cacodemon12
              include cac_5048.as1
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,4
              out dx,al

              MOV SI,OFFSET Cacodemon22
              include cac_5048.as2
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,8
              out dx,al

              MOV SI,OFFSET Cacodemon32
              include cac_5048.as3

              RET
PutSprite2 ENDP

PutSprite3     PROC ;; on entry : ES:DI = OFFSET WHERE TO PUT THE SPRITE !!!

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,1
              out dx,al

              MOV SI,OFFSET Cacodemon03
              include cac_5148.as0
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,2
              out dx,al

              MOV SI,OFFSET Cacodemon13
              include cac_5148.as1
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,4
              out dx,al

              MOV SI,OFFSET Cacodemon23
              include cac_5148.as2
              SUB DI,48*80

              mov dx,3C4h ;; sequenceur
              mov al,2
              out dx,al
              inc dx
              mov al,8
              out dx,al

              MOV SI,OFFSET Cacodemon33
              include cac_5148.as3

              RET
PutSprite3 ENDP

unlimit       ENDS
              END
