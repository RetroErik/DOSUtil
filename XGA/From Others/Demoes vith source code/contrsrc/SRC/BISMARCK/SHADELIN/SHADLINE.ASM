;**************************
;* Bismarck's shade lines *
;**************************
	INCLUDE  PDFIK.INC
	INCLUDE  VIDEO.INC
	INCLUDE  PLAYINFO.INC

;--------------------------------------------------------------------------
;                          Structure m‚moire ...
;--------------------------------------------------------------------------
.386
	DGROUP  GROUP _DATA,_BSS
	SHADE_TEXT SEGMENT DWORD PUBLIC USE16 'CODE'
		ASSUME CS:SHADE_TEXT, DS:SHADE_DATA ;, FS:DGROUP
	SHADE_TEXT ENDS
	_DATA   SEGMENT DWORD PUBLIC USE16 'DATA'
	_DATA   ENDS
	_BSS    SEGMENT DWORD PUBLIC USE16 'BSS'
	_BSS    ENDS
	SHADE_DATA SEGMENT DWORD PRIVATE USE16 'FAR_DATA'
	SHADE_DATA ENDS

;--------------------------------------------------------------------------

  Larg=320
  Haut=200
  Screen1 = 0
  Screen2 = (Larg*Haut/4)

;--------------------------------------------------------------------------

_DATA SEGMENT

;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD
Picname1   BYTE 'tfl&tdv.dat',0  ; nom pic ...
Picparam1  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname1,0,0,0,,,0>
Picname2   BYTE 'for.dat',0  ; nom pic ...
Picparam2  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname2,0,0,0,,,0>
Picname3   BYTE 'wired94.dat',0  ; nom pic ...
Picparam3  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname3,0,0,0,,,0>

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
	EXTRN _MP               : DWORD ; extern ModulePlayer * MB
	EXTRN _ReplayInfo       :  mpInformation
	EXTRN _MichFlag         : WORD

_BSS ENDS

;--------------------------------------------------------------------------
  red EQU 0
  green EQU 1
  blue EQU 2
  incr EQU 1
;--------------------------------------------------------------------------
SHADE_DATA SEGMENT

  RandSeed dd ?

  INCLUDE palnoir.pal
  INCLUDE randline.pal
  INCLUDE randlin2.pal
  INCLUDE randlin3.pal

  incr1 word ?
  incr2 word ?
  routine WORD ?
  handle WORD ?
  x1 word ?
  y1 word ?
  x2 word ?
  y2 word ?
  buf word ?
  img1 word ?
  img2 word ?
  img3 word ?
  ds2 word ?
  nbr dword ?

  DebSong  WORD ?
  FinSong  WORD ?

SHADE_DATA ENDS

;*****************************************************************************
SHADE_TEXT SEGMENT
	       PUBLIC _StartShade
	       EXTERN _SetVGA   : FAR
	       EXTERN _WaitVBL  : FAR
               EXTERN _GetRandom : FAR
;*****************************************************************************

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
         jmp     fin

ENDM


FillScreen MACRO color
; remplit l'‚cran avec une couleur donn‚e
           MPUSH   ax,cx,di,es

	   mov     ax,0A000h
	   mov     es,ax
	   xor     di,di
	   mov     al,color
	   mov     ah,color
	   mov     cx,32000
	   rep     stosw

           MPOP    ax,cx,di,es
ENDM

WAITVRT MACRO
    call _WaitVBL
ENDM
;----------------------------------------------------------------------


Load_imgpdfik MACRO
        MPUSH   eax,bx,es 

	mov     eax,fs:_OfsinDta      ; OFFSET in Datafile
	mov     fs:Picparam1.OfsInPdf,eax
	mov     ax,DGROUP             ; prepare for PDFIK call
	mov     es,ax
	mov     bx,OFFSET Picparam1
	pusha
	call    PDFIK_ASM             ; call function 2 (extract+alloc)
	popa
	mov     ax,fs:Picparam1.BufSeg ; where is the file in mem ?
	mov     img1,ax

	mov     eax,fs:_OfsinDta      ; OFFSET in Datafile
	mov     fs:Picparam2.OfsInPdf,eax
	mov     ax,DGROUP             ; prepare for PDFIK call
	mov     es,ax
	mov     bx,OFFSET Picparam2
	pusha
	call    PDFIK_ASM             ; call function 2 (extract+alloc)
	popa
	mov     ax,fs:Picparam2.BufSeg ; where is the file in mem ?
	mov     img2,ax

	mov     eax,fs:_OfsinDta      ; OFFSET in Datafile
	mov     fs:Picparam3.OfsInPdf,eax
	mov     ax,DGROUP             ; prepare for PDFIK call
	mov     es,ax
	mov     bx,OFFSET Picparam3
	pusha
	call    PDFIK_ASM             ; call function 2 (extract+alloc)
	popa
	mov     ax,fs:Picparam3.BufSeg ; where is the file in mem ?
	mov     img3,ax

        MPOP    eax,bx,es
ENDM

NEW MACRO nom, mem
  LOCAL suite, erreur2, fin, plusbas
  ; d‚clare et alloue mem byte … un pointeur
     MPUSH      ax,bx

     mov        ah, 48h
     mov        bx, mem
     shr        bx, 4
     inc        bx
     int        21h
     jnc        plusbas
plusbas:
     mov        nom, ax

fin: MPOP       ax,bx
ENDM
;--------------------------------------------------------------------------
  FREE MACRO nom
  ; LibŠre la m‚moire point‚e par nom
     MPUSH      ax,es
     mov        ax, nom
     mov        es, ax
     mov        ah, 49h
     int        21h
     MPOP       ax,es
  ENDM

;----------------------------------------------------------------------
LOAD_PAL MACRO PAL
         MPUSH ax,cx,dx,si

         mov   dx,3c8h
         xor   al,al
         out   dx,al
         mov   si,OFFSET PAL
         mov   cx,768
         inc   dl
         rep   outsb

         MPOP  ax,cx,dx,si

ENDM

LINE_INCR MACRO

LOCAL L01,L03,L04,L31,L32,VertLine13,HorizLine13,LoSlopeLine13,HiSlopeLine13,L11,L12,L21,L22,L23,Lexit,loophor;

                MPUSH    ax,bx,cx,si,di

		mov      si,320
		mov      cx,x2
		sub      cx,x1
		jz       VertLine13

		jns      L01
		neg      cx
		mov      bx,x2
		xchg     bx,x1
		mov      x2,bx
		mov      bx,y2
		xchg     bx,y1
		mov      y2,bx

L01:            mov      bx,y2
		sub      bx,y1
		jz       HorizLine13
		jns      L03
		neg      bx
		neg      si

L03:            push     si
		mov      routine,offset LoSlopeLine13
		cmp      bx,cx
		jle      L04
		mov      routine,offset HiSlopeLine13
		xchg     bx,cx


L04:            shl      bx,1
		mov      incr1,bx
		sub      bx,cx
		mov      si,bx
		sub      bx,cx
		mov      incr2,bx


		push     cx
		mov      ax,y1
		mov      bx,x1

		xchg        ah,al
		add         bx,ax
		shr         ax,1
		shr         ax,1
		add         bx,ax

		mov      di,bx
		pop      cx
		inc      cx
		pop      bx
		jmp      routine


VertLine13:     mov      ax,y1
		mov      bx,y2
		mov      cx,bx
		sub      cx,ax
		jge      L31
		neg      cx
		mov      ax,bx
L31:            inc      cx
		mov      bx,x1
		push     cx

		xchg        ah,al
		add         bx,ax
		shr         ax,1
		shr         ax,1
		add         bx,ax

		pop      cx
		mov      di,bx
		dec      si

L32:            mov      al,es:[di]
		inc      al
		stosb
		add      di,si
		mov      al,es:[di]                       
		add      al,incr
                dec      cx
                jnz      L32
		jmp      Lexit

HorizLine13:    push     cx
		mov      ax,y1
		mov      bx,x1

		xchg        ah,al
		add         bx,ax
		shr         ax,1
		shr         ax,1
		add         bx,ax

		mov      di,bx
		pop      cx
		inc      cx
loophor:        mov      al,es:[di]
		add      al,incr
		stosb
                dec      cx
                jnz      loophor
		jmp      Lexit

LoSlopeLine13:

L11:            mov      al,es:[di]
		add      al, incr
		stosb
		or       si,si
		jns      L12
		add      si,incr1
                dec      cx
                jnz      L11
		jmp      Lexit

L12:            add      si,incr2
		add      di,bx
                dec      cx
                jnz      L11
		jmp      Lexit


HiSlopeLine13:
L21:            mov         al,es:[di]
		add         al, incr
		stosb
		add         di,bx
L22:            or          si,si
		jns         L23
		add         si,incr1
		dec         di
                dec         cx
                jnz         L21
		jmp         Lexit

L23:            add         si,incr2
                dec         cx
                jnz         L21

Lexit:          MPOP        ax,bx,cx,si,di

ENDM

Randomax MACRO
                MPUSH    bx,cx,dx,si,di

		mov      cx,ax          ; save limit
		mov      ax,WORD PTR [RandSeed+2]
		mov      bx,WORD PTR [RandSeed]
		mov      si,ax
		mov      di,bx
		mov      dl,ah
		mov      ah,al
		mov      al,bh
		mov      bh,bl
		xor      bl,bl
		rcr      dl,1
		rcr      ax,1
		rcr      bx,1
		add      bx,di
		adc      ax,si
		add      bx,62e9h
		adc      ax,3619h
        	mov      WORD PTR [RandSeed],bx
		mov      WORD PTR [RandSeed+2],ax
		xor      dx,dx
		div      cx
		mov      ax,dx                  ; return modulus
        
                MPOP     bx,cx,dx,si,di
ENDM


PutBufToMemory MACRO
  MPUSH     ax,cx,si,di,ds,es
 
  xor       si,si
  xor       di,di
  mov       ax, 0A000h
  mov       es, ax
  mov       ax, buf
  mov       ds, ax
  mov       cx, 16000
  cld
  rep       movsd

  MPOP      ax,cx,si,di,ds,es
ENDM

PutImg2Buf MACRO image
  MPUSH     ax,cx,si,di,ds,es

  xor       si,si
  xor       di,di
  mov       ax, buf
  mov       es, ax
  mov       ax, image
  mov       ds, ax
  mov       cx, 16000
  cld
  rep       movsd

  MPOP      ax,cx,si,di,ds,es 
ENDM

Free_Keyboard MACRO
         MPUSH   ax,es
	 mov     ax,40h              ; !!! Vider buffer clavier !!! ;-)
	 mov     es,ax
	 mov     ax,es:[001ah]
	 mov     es:[001ch],ax
         MPOP    ax,es
ENDM

ClrBuf MACRO
  MPUSH   ax,cx,di,es

  xor     di,di
  mov     ax, buf
  mov     es, ax
  xor     eax, eax
  cld
  mov     cx, 16000
  rep     stosd

  MPOP    ax,cx,di,es
ENDM

FadeToSingle MACRO palet
local loopcx, loopdi, pluspetitrouge, plusgrandrouge, egalrouge, pluspetitvert
local plusgrandvert, egalvert, pluspetitbleu, plusgrandbleu, egalbleu

                MPUSH   ax,cx,dx,si,di

		mov     di,64             ; 64 fades ...

loopdi:         WAITVRT
                mov     si,OFFSET palet   ; better than palet[si] Bismarck :-)
 
		mov     dx, 3c8h          ;{ DAC set write m
	        xor     al,al
        	out     dx, al            ;{ set to write mode }
		inc     dl                ;{ address of DAC read data }
                mov     cx,256            ; 256 colors

loopcx:

		mov     al, palet[123*3]
		cmp     BYTE PTR[si],al
		jb      pluspetitrouge
		je      egalrouge
		ja      plusgrandrouge
pluspetitrouge:
        	inc     BYTE PTR[si]
	        jmp     egalrouge
plusgrandrouge:
	        dec     BYTE PTR[si]
	        jmp     egalrouge
egalrouge:
		mov     al, palet[123*3+1]
		cmp BYTE PTR[si+1],al
		jb  pluspetitvert
		je  egalvert
		ja  plusgrandvert
pluspetitvert:
	        inc     BYTE PTR[si+1]
	        jmp     egalvert
plusgrandvert:
	        dec     BYTE PTR[si+1]
	        jmp     egalvert
egalvert:

		mov     al, palet[123*3+2]
		cmp     BYTE PTR[si+2], al
		jb      pluspetitbleu
		je      egalbleu
		ja      plusgrandbleu
pluspetitbleu:
	        inc     BYTE PTR[si+2]
	        jmp     egalbleu
plusgrandbleu:
	        dec     BYTE PTR[si+2]
	        jmp     egalbleu
egalbleu:
	
		outsb                           ;{ set new red value }
		outsb                           ;{ set new green value }
		outsb                           ;{ set new blue value }

                dec     cx
                jnz     loopcx

                dec     di
                jnz     loopdi

                MPOP    ax,cx,dx,si,di
ENDM

FadeToBlack MACRO palet
local loopcx, loopdi, pluspetitrouge, plusgrandrouge, egalrouge, pluspetitvert
local plusgrandvert, egalvert, pluspetitbleu, plusgrandbleu, egalbleu

                MPUSH   ax,dx,cx,si,di

		mov     di,64
loopdi:         WAITVRT
                mov     si,OFFSET palet  ; !!!!!!
              
                mov     dx,3c8h
                xor     al,al
                out     dx,al
                inc     dl
               
                mov     cx,256
loopcx:

		cmp     BYTE PTR[si],0
		je      egalrouge
        	dec     BYTE PTR[si]
	        jmp     egalrouge
egalrouge:
		cmp     BYTE PTR[si+1],0
		je  egalvert
	        dec     BYTE PTR[si+1]
	        jmp     egalvert
egalvert:

		cmp     BYTE PTR[si+2], 0
		je      egalbleu
		dec     BYTE PTR[si+2]
		jmp     egalbleu
egalbleu:

		outsb                           ;{ set new red value }
		outsb                           ;{ set new green value }
		outsb                           ;{ set new blue value }

                dec     cx
		jnz     loopcx
   
                dec     di
		jnz     loopdi

                MPOP    ax,cx,dx,si,di
ENDM

FadeToWhite MACRO palet
local loopcx, loopdi, pluspetitrouge, plusgrandrouge, egalrouge, pluspetitvert
local plusgrandvert, egalvert, pluspetitbleu, plusgrandbleu, egalbleu

                MPUSH   ax,cx,dx,si,di

		mov     di,64
loopdi:         WAITVRT
                mov     si,OFFSET palet

                mov     dx,3c8h
                xor     al,al
                out     dx,al
                inc     dl
   
                mov     cx,256
                
loopcx:

		cmp     BYTE PTR[si],63
		je      egalrouge
		inc     BYTE PTR[si]
		jmp     egalrouge
egalrouge:
		cmp     BYTE PTR[si+1],63
		je      egalvert
		inc     BYTE PTR[si+1]
		jmp     egalvert
egalvert:

		cmp     BYTE PTR[si+2], 63
		je      egalbleu
		inc     BYTE PTR[si+2]
		jmp     egalbleu
egalbleu:

		outsb                           ;{ set new red value }
		outsb                           ;{ set new green value }
		outsb                           ;{ set new blue value }


		dec     cx
		jnz     loopcx

		dec     di
		jnz     loopdi
            
                MPOP    ax,cx,dx,si,di

ENDM


FadeTopal MACRO palet1, palet2
local loopcx2, loopdi2, pluspetitrouge2, plusgrandrouge2, egalrouge2, pluspetitvert2
local plusgrandvert2, egalvert2, pluspetitbleu2, plusgrandbleu2, egalbleu2

                MPUSH   ax,cx,dx,si,di

		mov     di,64

loopdi2:        WAITVRT
                mov     si,OFFSET palet1
                mov     bx,OFFSET palet2

                mov     dx,3c8h
                xor     al,al
                out     dx,al
                inc     dl

                mov     cx,256

loopcx2:

		mov     al, BYTE PTR[si]
		cmp     al, BYTE PTR[bx]
		jb      pluspetitrouge2
		je      egalrouge2
		ja      plusgrandrouge2
pluspetitrouge2:  
	        inc     BYTE PTR[si]
        	jmp     egalrouge2
plusgrandrouge2:
	        dec     BYTE PTR[si]
	        jmp     egalrouge2
egalrouge2:
		mov     al, BYTE PTR[si+1]
		cmp     al, BYTE PTR[bx+1]
		jb  pluspetitvert2
		je  egalvert2
		ja  plusgrandvert2
pluspetitvert2:
	        inc     BYTE PTR[si+1]
	        jmp     egalvert2
plusgrandvert2:
	        dec     BYTE PTR[si+1]
         	jmp     egalvert2
egalvert2:

		mov     al, BYTE PTR[si+2]
		cmp     al, BYTE PTR[bx+2]
		jb      pluspetitbleu2
		je      egalbleu2
		ja      plusgrandbleu2
pluspetitbleu2:
	        inc     BYTE PTR[si+2]
	        jmp     egalbleu2
plusgrandbleu2:
	        dec     BYTE PTR[si+2]
	        jmp     egalbleu2
egalbleu2:
		outsb                           ;{ set new red value }
		outsb                           ;{ set new green value }
		outsb                           ;{ set new blue value }

		add     bx,3

		dec     cx
		jnz     loopcx2

		dec     di
		jnz     loopdi2

                MPOP    ax,cx,dx,si,di

ENDM

MPUSH   MACRO reg1:REQ,reg2:VARARG   ; Vive Y.Roggeman/Greg & ses Macros
	push reg1                    ; recursives !!!!!!! yahouuuuu !!!
	IFNB <reg2>
	MPUSH reg2
	ENDIF
	ENDM

MPOP    MACRO reg1:REQ,reg2:VARARG   ; bis bis !!!
	IFNB <reg2>                  ; type brol = record....
	MPOP reg2                    ; donc ‡a fait 20 bytes !!!
	ENDIF                        ; donc 1 word ....
	pop reg1                     ; brol je dis struct !!!
	ENDM

;---------------------
; point d'entree ....
;---------------------

_StartShade PROC FAR
	push    bp
	mov     bp,sp

	pushad
	push    ds
	push    es
	push    fs
	push    gs

	mov     ax, DGROUP
	mov     fs, ax
	mov     ax,SHADE_DATA
	mov     ds,ax


;------- recuperer parametres sur le stack !!!! --------

         xor     eax,eax
	 mov     ax,WORD PTR ss:[bp+6]  ; debut pos
	 shl     eax,14
	 or      ax,WORD PTR ss:[bp+8]  ; debut row
	 or      ah,al
	 shr     eax,8
	 mov     [DebSong],ax
	 mov     ax,WORD PTR ss:[bp+10] ; fin pos
	 shl     eax,14
	 or      ax,WORD PTR ss:[bp+12] ; fin row
	 or      ah,al
	 shr     eax,8
	 mov     [FinSong],ax
	 xor     eax,eax
;-------------------------------------------------------
	mov     bx,WORD PTR fs:[_StartAdr]
	mov     WORD PTR fs:[bx],Screen1     ; _StartAdr->base = 0
	mov     bx,WORD PTR fs:[_WorkAdr]
	mov     WORD PTR fs:[bx],Screen2     ; _WorkAdr->base
	mov     WORD PTR fs:[bx+2],0         ; _WorkAdr->flag=false
	mov     WORD PTR fs:[_Triple],0      ; double buffering
	mov     WORD PTR fs:[_MichFlag], 1


	new     buf, 64000

	load_imgpdfik
	Putimg2Buf img1

;------------------------------------------------------------------------------
        push    m320x200x256c         ; mode 320x200 chain‚ 1 page (chouette)
        call    _SetVGA
        add     sp,2
	FillScreen 0
;------------------------------------------------------------------------------


;debut
;---- wait right position/row in tune ----

	pushad
	MPUSH   ds,es,fs,gs

	ASSUME  ds:DGROUP
	ASSUME  fs:SHADE_DATA
	mov     ax,DGROUP
	mov     ds,ax
	mov     ax,SHADE_DATA   ; XCHG DS,FS !!!!
	mov     fs,ax

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
	 ASSUME  ds:SHADE_DATA
	 ASSUME  fs:DGROUP
	 MPOP    ds,es,fs,gs
	 popad
	 nop

         mov     ax,DGROUP
         mov     fs,ax
         mov     ax,SHADE_DATA
         mov     ds,ax
;------------------------------------------
 
        mov    dx,3d4h      ; set video page to 0
        mov    ax,000ch
        out    dx,ax
        mov    ax,000dh
        out    dx,ax


	load_pal palnoir
	fadetowhite palnoir
	PutBufToMemory
	fadetopal palnoir, palrandline1
	call randomize
	mov     WORD PTR fs:[_FrameCounter],0

main_loop:
	xor     bx, bx
	xor     si, si
	xor     di, di

  loopbx:
	push    bx
	mov     ax, 180
	randomax
	mov     y1, ax

	add     ax, 100
	randomax
	add     ax, 150
	mov     x2, ax

	inc     ax
	randomax
	mov     x1, ax

	mov     ax,y1
	shr     ax,1
	inc     ax
	randomax
	mov     y2, ax

	mov     ax, buf
	mov     es, ax
	line_incr

	pop      bx
	inc      bx
	cmp      bx, 250
	jne      loopbx

	PutBufToMemory

	cmp     fs:[_FrameCounter],300 ;6*70 ;300
        jae     fin1

        LOOPUNTILKEY main_loop
fin1:

	fadetosingle palrandline1
	Putimg2Buf img2
	PutBufToMemory
	fadetopal palrandline1, palrandline2
	free_keyboard

	mov     WORD PTR fs:[_FrameCounter],0


main_loop2:
	xor     bx, bx
  loopbx2:
	push    bx

	mov     ax, 150
	randomax
	add     ax,110
	mov     x1, ax

	mov     ax,190
	randomax
	mov     y1, ax

	mov     ax,400
	inc     ax
	randomax
	mov     x2, ax

	mov     ax,190
	randomax
	mov     y2, ax

	mov     ax, buf
	mov     es, ax
	line_incr

	pop      bx
	inc      bx
	cmp      bx,1000
	jne      loopbx2

	PutBufToMemory

	cmp     fs:[_FrameCounter],300 ;6*70 ;300
        jae     fin2

        LOOPUNTILKEY main_loop2
fin2:

	fadetosingle palrandline2
	Putimg2Buf img3
	PutBufToMemory
	fadetopal palrandline2, palrandline3
	free_keyboard

	mov     WORD PTR fs:[_FrameCounter],0


main_loop3:
	xor     bx, bx
  loopbx3:
	push    bx

	mov     ax, 150
	randomax
;       add     ax,110
	mov     x1, ax

	mov     ax,190
	randomax
	mov     y1, ax

	mov     ax,400
	inc     ax
	randomax
	mov     x2, ax

	mov     ax,190
	randomax
	mov     y2, ax

	mov     ax, buf
	mov     es, ax
	line_incr

	pop      bx
	inc      bx
	cmp      bx,250
	jne      loopbx3

	PutBufToMemory

	cmp     fs:[_FrameCounter],300 ;7*70 ;300
        jae     fin

        LOOPUNTILKEY main_loop3


fin:

	Putimg2Buf img2
	fadetosingle palrandline3
	fadetoblack palrandline3
	free_keyboard

	free    buf
	free    img1
	free    img2
	free    img3


;------------------------------------------------------------------------------
; Lib‚ration des zones m‚moires

	mov     WORD PTR fs:[_FrameCounter],0
	mov     WORD PTR fs:[_MichFlag], 0

	pop          gs
	pop          fs
	pop          es
	pop          ds

	popad
	nop

	leave
	retf

_StartShade ENDP

;------- some procs --------

Randomize PROC NEAR
                pusha
                push     ds
		mov      ah,2Ch
		int      21h
                mov      ax,SHADE_DATA
                mov      ds,ax
		mov      WORD PTR [RandSeed],cx
		mov      WORD PTR [RandSeed+2],dx
                pop      ds
                popa
		ret
Randomize ENDP


SHADE_TEXT ENDS


    END
