;************************************************
;* StarWars Scroller by Bismarck / TFL-TDV 1994 *
;************************************************
	INCLUDE  PDFIK.INC
	INCLUDE  VIDEO.INC
	INCLUDE  PLAYINFO.INC

;--------------------------------------------------------------------------
;                          Structure m‚moire ...
;--------------------------------------------------------------------------
.386
	DGROUP  GROUP _DATA,_BSS
	STAR_TEXT SEGMENT DWORD PUBLIC USE16 'CODE'
		ASSUME CS:STAR_TEXT, DS:STAR_DATA;,FS:DGROUP
	STAR_TEXT ENDS
	_DATA   SEGMENT DWORD PUBLIC USE16 'DATA'
	_DATA   ENDS
	_BSS    SEGMENT DWORD PUBLIC USE16 'BSS'
	_BSS    ENDS
	STAR_DATA SEGMENT DWORD PUBLIC USE16 'FAR_DATA'
	STAR_DATA ENDS

;--------------------------------------------------------------------------

  Larg=320
  Haut=200
  Screen1 = 0
  Screen2 = (Larg*Haut/4)
  Screen3 = (Larg*Haut*2/4)


_DATA SEGMENT

;-- donnees pattern --
EXTRN _Datafile  : BYTE
EXTRN _OfsinDta  : DWORD

Picname1   BYTE 'source.cal',0  ; nom pic ...
Picparam1  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname1,0,0,0,,,0>
Picname2   BYTE 'dest.cal',0  ; nom pic ...
Picparam2  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname2,0,0,0,,,0>
Picname3   BYTE 'shade.cal',0  ; nom pic ...
Picparam3  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname3,0,0,0,,,0>
Picname4   BYTE 'font.tdv',0  ; nom pic ...
Picparam4  PARAM_STRUC<2,DGROUP,OFFSET _Datafile,OFFSET Picname4,0,0,0,,,0>

_DATA ENDS

;--------------------------------------------------------------------------

_BSS SEGMENT

	EXTRN _FrameCounter     : WORD
	EXTRN _ExitDemo         : WORD
        EXTRN _SpaceBar         : WORD
        EXTRN _FadeON           : WORD
	EXTRN _CPUtime          : WORD
	EXTRN _StartAdr         : WORD
	EXTRN _WorkAdr          : WORD
	EXTRN _NextAdr          : WORD
	EXTRN _Triple           : WORD
	EXTRN _SyncFlag         : WORD
	EXTRN _MichFlag         : WORD

        ;!!!!!!!!!! sync music !!!!!!!!!!
        EXTRN _MP               : DWORD ; extern ModulePlayer * MB
        EXTRN _ReplayInfo       : mpInformation


_BSS ENDS

;--------------------------------------------------------------------------
  red EQU 0
  green EQU 1
  blue EQU 2
;--------------------------------------------------------------------------
STAR_DATA SEGMENT
   ; variables … utiliser !
  filename1 byte "FONT.TDV",00h
  filename2 byte "SOURCE.CAL",00h
  filename3 byte "DEST.CAL",00h
  filename4 byte "SHADE.CAL",00h

cumul_step_lo DD 0
cumul_step_hi DD 0
cumul_old_lo  DD 0
cumul_old_hi  DD 0

;---- param pour synchro avec zizik ----
EVEN
DebSong  WORD ?
FinSong  WORD ?


  baseadress word 0
  Desti word 0
  curstep word 3
  handle word ?
  font1 word ?
  buf word ?
  buf2 word ?
  source word ?
  dest word ?
  shade word ?
  ds2 word ?
  y word 0
  tailley word ?
  tailleyd2 word ?
  bp2 word ?
  var word ?
  INCLUDE datafile.inc
  INCLUDE textefin.inc
STAR_DATA ENDS

;*****************************************************************************
STAR_TEXT SEGMENT
	       PUBLIC _StartStar
	       EXTERN _SetVGA   : FAR
	       EXTERN _WaitVBL  : FAR


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


FLUSH_KEYBUF MACRO
        MPUSH   ax,es

        mov     ax,40h                ; Flush keyboard buffer !!! ;-)
        mov     es,ax
        mov     ax,es:[001ah]
        mov     es:[001ch],ax  

        MPOP    ax,es
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
;        mov    ah,cl ; frame*256
     ;   mov    ax,384 ;307              ; 1.5*256 = factor
     ;   mul    cx
        mov    ax,128
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

        mov    fs:_FrameCounter,0

        MPOP   eax,ebx,ecx,edx
;--------------------------------------------

ENDM

COLOR MACRO col:REQ

      MPUSH ax,dx
      mov dx,3c8h
      xor al,al
      out dx,al
      mov al,col
      inc dl
      out dx,al
      out dx,al
      out dx,al
      MPOP ax,dx

ENDM

SHOWTIME MACRO col:REQ
        LOCAL lbl1
        test            fs:_CPUtime,1
        jz              lbl1
        COLOR           col
lbl1:

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
         jmp     fin

ENDM


;*****************************************************************************
Load_stretchpdfik MACRO
	mov     eax,fs:_OfsinDta      ; OFFSET in Datafile
	mov     fs:Picparam1.OfsInPdf,eax
	mov     ax,DGROUP             ; prepare for PDFIK call
	mov     es,ax
	mov     bx,OFFSET Picparam1
	pusha
	call    PDFIK_ASM             ; call function 2 (extract+alloc)
	popa
	mov     ax,fs:Picparam1.BufSeg ; where is the file in mem ?
	mov     source,ax

	mov     eax,fs:_OfsinDta      ; OFFSET in Datafile
	mov     fs:Picparam2.OfsInPdf,eax
	mov     ax,DGROUP             ; prepare for PDFIK call
	mov     es,ax
	mov     bx,OFFSET Picparam2
	pusha
	call    PDFIK_ASM             ; call function 2 (extract+alloc)
	popa
	mov     ax,fs:Picparam2.BufSeg ; where is the file in mem ?
	mov     dest,ax

	mov     eax,fs:_OfsinDta      ; OFFSET in Datafile
	mov     fs:Picparam3.OfsInPdf,eax
	mov     ax,DGROUP             ; prepare for PDFIK call
	mov     es,ax
	mov     bx,OFFSET Picparam3
	pusha
	call    PDFIK_ASM             ; call function 2 (extract+alloc)
	popa
	mov     ax,fs:Picparam3.BufSeg ; where is the file in mem ?
	mov     shade,ax
ENDM

WAITVRT MACRO
       call _WaitVBL
ENDM

NEW MACRO nom, mem
  LOCAL suite, erreur2, fin, plusbas
  ; d‚clare et alloue mem byte … un pointeur

     mov        ah, 48h
     mov        bx, mem
     shr        bx, 4
     inc        bx
     int        21h
     jnc        plusbas
     changezero 63
plusbas:
     mov        nom, ax
fin:
ENDM
;--------------------------------------------------------------------------
  FREE MACRO nom
  ; LibŠre la m‚moire point‚e par nom
     mov        ax, nom
     mov        es, ax
     mov        ah, 49h
     int        21h
  ENDM

;----------------------------------------------------------------------
Reset_Cursor MACRO
	mov     ah, 01h
	mov     cx, 0506h
	int     10h
ENDM
;----------------------------------------------------------------------
No_Cursor MACRO
	mov     ah, 01h
	mov     cx, 0FF00h
	int     10h
ENDM

;----------------------------------------------------------------------
LOAD_PAL MACRO PAL
local bcl
	mov     dx, 3C8h
	mov     ax, 0
	xor     si, si
bcl:    out     dx, al
	inc     dx
	push    ax
	mov     al, byte ptr &PAL&[si]
	out     dx, al
	mov     al, byte ptr &PAL&[si+1]
	out     dx, al
	mov     al, byte ptr &PAL&[si+2]
	out     dx, al
	pop     ax
	dec     dx
	add     si, 3
	inc     ax
	cmp     ax, 256
	jl      bcl
ENDM


;----------------------------------------------------------------------
LOAD_PAL MACRO PAL
local bcl
	mov     dx, 3C8h
	mov     ax, 0
	xor     si, si
bcl:    out     dx, al
	inc     dx
	push    ax
	mov     al, byte ptr &PAL&[si]
	out     dx, al
	mov     al, byte ptr &PAL&[si+1]
	out     dx, al
	mov     al, byte ptr &PAL&[si+2]
	out     dx, al
	pop     ax
	dec     dx
	add     si, 3
	inc     ax
	cmp     ax, 256
	jl      bcl
ENDM

Init13h MACRO
	mov ax,13h
	int 10h
ENDM
;----------------------------------------------------------------------
LOAD_FONT MACRO
	  push          ds
	  mov           dx, offset filename1
	  mov           ax, 3D00h
	  mov           cx, 0
	  int           21h
	  mov           handle, ax

	  mov           ax, 3F00h
	  mov           bx, handle
	  mov           cx, 22260
	  mov           dx, font1
	  mov           ds, dx
	  mov           dx, 0
	  int           21h
	  pop           ds

	  mov           ax, 3E00h
	  mov           bx, handle
	  int           21h
ENDM
;----------------------------------------------------------------------
LOAD_FONTPDFIK MACRO
	mov     eax,fs:_OfsinDta      ; OFFSET in Datafile
	mov     fs:Picparam4.OfsInPdf,eax
	mov     ax,DGROUP             ; prepare for PDFIK call
	mov     es,ax
	mov     bx,OFFSET Picparam4
	pusha
	call    PDFIK_ASM             ; call function 2 (extract+alloc)
	popa
	mov     ax,fs:Picparam4.BufSeg ; where is the file in mem ?
	mov     font1,ax

ENDM

changezero MACRO col
		mov     al, 0
		mov     dx, 3c8h                ;{ DAC set write mode }
						; mov     al, index
		out     dx, al                  ;{ set to write mode }
		mov     dx, 3c9h                ;{ address of DAC read data }
		mov     al, col                 ;
		out     dx, al                  ;{ set new red value }
		mov     al, 0                   ;
		out     dx, al                  ;{ set new green value }
		mov     al, 0                  ;
		out     dx, al                  ;{ set new blue value }
ENDM ;{DACRemapColour}

VGApalette MACRO
; INPUT al : index
;       ah : red
;       bh : green
;       bl : blue

;{ N.B. no wait for vertical retrace is done }
		mov     dx, 3c8h                ;{ DAC set write mode }
						; mov     al, index
		out     dx, al                  ;{ set to write mode }
		mov     dx, 3c9h                ;{ address of DAC read data }
		mov     al, ah                  ;
		out     dx, al                  ;{ set new red value }
		mov     al, bh                   ;
		out     dx, al                  ;{ set new green value }
		mov     al, bl                  ;
		out     dx, al                  ;{ set new blue value }
ENDM ;{DACRemapColour}

BUILD_PALETTE MACRO
LOCAL Loopal,endloopal,loop
;  for i:=0 to 11 do vgapalette(i,63-img^.palette[i,red],0,0);
		mov       cx,0
		mov       ax,_data
		mov       ds,ax
		mov       ax,0
		mov       bx,0
		xor       ax,ax
loop:           push      ax
loopal:         mov       bl,cl
		mov       al,cl
		inc       al
		mov       dl,byte ptr palette[bx]
		mov       ah,63
		sub       ah,dl
		mov       bl,1
		vgapalette
		inc       cl
		cmp       cl,13
endloopal:      jne       loopal
		pop       ax
		inc       ax
		cmp       ax,10
		jne       loop
ENDM

Copy_font MACRO ligne
  local loopy,loopx,loopdh,loopdl,endloopy,endloopx,endloopdh,endloopdl;
  shl   bx, 1
  shl   bx, 1
  shl   bx, 1
  shl   bx, 1
  xor   eax, eax
  xor   dx, dx
  xor   bp,bp
  loopdh:
    loopdl:       mov       al, byte ptr fs:[textes+bx]
		  mov       si, word ptr fs:[mul420+eax*2]
		  FOR       YY, <0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20>
		    mov       di, fs:[mul320+YY*2]
		    add       di, bp
		    mov       cx,5
		    rep movsd
		  ENDM
		  inc       bx
		  add       bp, 20
		  inc       dl
		  cmp       dl, 16
    endloopdl:    jne       loopdl
		  xor       dl, dl
		  add       bp, 6400
		  inc       dh
		  cmp       dh, 9
  endloopdh:      jne       loopdh
ENDM

CreateImg MACRO
local debut,fin
	xor     bx, bx
debut:  inc     bx
	mov     si, fs:[ebx*2]
	add     si, bp
	mov     ds, dx
	mov     al, byte ptr ds:[si]
	mov     ds, cx
	add     al, ds:[bx]
@@:     mov     di, gs:[ebx*2]
	stosb
	cmp     bx, 17860
fin:    jne debut
ENDM

PutBufToScr MACRO
	  mov        ax, 0102h               ; plan 0
	  mov        dx, 03C4h
	  out        dx, ax
	  add        di, 8000
	  mov        cx, 2000 ;3040
	  cld
	  rep        movsd

	  mov        si, 16000
	  mov        ax, 0202h               ; plan 1
	  mov        dx, 03C4h
	  out        dx, ax

	  sub        di, 8000 ;12160
	  mov        cx, 2000 ;3040
	  rep        movsd

	  mov        ax, 0402h               ; plan 2
	  mov        dx, 03C4h
	  out        dx, ax

	  mov        si, 32000
	  sub        di, 8000 ;12160
	  mov        cx, 2000 ;3040
	  rep        movsd

	  mov        ax, 0802h               ; plan 3
	  mov        dx, 03C4h
	  out        dx, ax

	  mov        si, 48000
	  sub        di, 8000 ;12160
	  mov        cx, 2000 ;3040
	  rep        movsd
ENDM

CLRBUF MACRO
	mov       ax, buf2
	mov       es, ax
	xor       di ,di

	mov       eax , 00h
	mov       cx, 16000
	rep       stosd
ENDM

SUPER_FX PROC NEAR

	  push	ds	

           add        bx, curstep

	    mov        ax, buf2
	    mov        es, ax

	    mov        dx, buf
	    mov        cx, shade


	    push       bx
	    push       fs
	    mov        bp, word ptr ds:[mul320+ebx*2]
	    mov        ax, source
	    mov        fs, ax

	    CreateImg

	    pop       fs
 	    pop       bx
	    pop       ds

	    mov        ax, 0A000h
	    mov        es, ax

	    push      ds
	    mov       di, baseadress
	    mov       ax, buf2
	    mov       ds, ax
	    xor       si, si

	    PutbufToScr


	    pop       ds

            ret
Super_fx ENDP

;---------------------
; point d'entree ....
;---------------------

_StartStar PROC FAR
	push    bp
	mov     bp,sp

	pushad
	push    ds
	push    es
	push    fs
	push    gs

        mov     ax,STAR_DATA
        mov     ds,ax

	mov     ax, DGROUP
	mov     fs, ax


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


	;mov     bx,WORD PTR fs:[_StartAdr]
	;mov     WORD PTR fs:[bx],Screen1     ; _StartAdr->base = 0
	;mov     bx,WORD PTR fs:[_WorkAdr]
	;mov     WORD PTR fs:[bx],Screen2     ; _WorkAdr->base
	;mov     WORD PTR fs:[bx+2],0         ; _WorkAdr->flag=false
	;mov     WORD PTR fs:[_Triple],0      ; double buffering
;        mov     word ptr fs:[_MichFlag],1

	mov     ax,STAR_DATA
	mov     ds,ax


	new     buf, 64000
	new     buf2, 64000

	new     font1, 22260

	push    m320x200x256p
	call    _SetVGA
	add     sp,2

	load_fontpdfik
	load_stretchpdfik
	clrbuf

	load_pal pal

;---- wait right position/row in tune ----

        pushad
        MPUSH   ds,es,fs,gs

        ASSUME  ds:DGROUP
;        ASSUME  fs:STAR_DATA
        mov     ax,DGROUP
        mov     ds,ax
        mov     ax,STAR_DATA   ; XCHG DS,FS !!!!
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
         ASSUME  ds:STAR_DATA
;         ASSUME  fs:DGROUP
         MPOP    ds,es,fs,gs
         popad
         nop 
;------------------------------------------


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

         WAITVRT


          mov     word ptr fs:[_FrameCounter],0 ; set counter to NULL
	  mov        ax, dest
	  mov        gs, ax
          mov        bx,21

;=================== 1 ere boucle !!!!! ======================

loopvar:  inc       var
	  push      fs
	  push      ds
	  push	bx
	  mov       bx, var
	  mov       ax, ds
	  mov       fs, ax
	  mov       ax, buf
	  mov       es, ax
	  mov       ax, font1
	  mov       ds, ax
	  copy_font
	  pop	    bx
	  pop        ds
	  pop        fs
;	  push       ds

          sub        bx,21
;          xor   bx,bx

;============== MAIN LOOP ==============

loopbx:

;***** 2nd page *****
Do_a_frame:
        mov             di,fs:_WorkAdr
        cmp             WORD PTR fs:[di+2],1 ; _WorkAdr->flag true (previous _NextAdr) ?
        je              NextFrame        ; then construct next frame

        mov             Desti,di               ; save pointer

        mov             si,Desti
        mov             ax,WORD PTR fs:[si]
        mov             baseadress,ax         ; offset

        NEXTSTEP                                ; calculate nextstep :-)

        SHOWTIME        32

            call Super_FX

        SHOWTIME        0

        mov    di,fs:_NextAdr         ; save adr of next buffer

        mov    si,Desti
        mov    WORD PTR fs:[si+2],1    ; _WorkAdr->flag = true

        cmp    bx,21
        jae    loop2

        jmp  Nexxxt


;******** 3rd page *********
NextFrame:
         mov  di,fs:_NextAdr
         cmp  WORD PTR fs:[di+2],1 ; _NextAdr true ?
         je   NextFrame
    
Nexxxt:

        mov  Desti,di               ; save pointer

        mov             si,Desti
        mov             ax,WORD PTR fs:[si]
        mov             baseadress,ax         ; OFFSET in video mem

        NEXTSTEP                                ; calculate nextstep :-)

        SHOWTIME        32

            call Super_FX

        SHOWTIME        0

        mov             si,Desti
        mov             WORD PTR fs:[si+2],1     ; _NextAdr->flag = true

        cmp  bx,21
        jae  loop2

        LOOPUNTILKEY loopbx                      ; exit if keypressed

loop2:

        cmp   var, 358
	jne   loopvar


fin:
        mov     fs:_FadeON,0             ; to be sure ....
        FLUSH_KEYBUF


;        mov     word ptr fs:[_MichFlag],0

	free font1
	free buf
	free buf2
	free source
	free dest
	free shade

;------------------------------------------------------------------------------
; Lib‚ration des zones m‚moires

error:
       ; writeln " þ Only for the WIRED'94 !!!"
;       Reset_Cursor

        mov     ax,0a000h           ; Clear screen
        mov     es,ax
        mov     dx,3c4h
        mov     ax,0f02h
        out     dx,ax
        xor     eax,eax
        xor     di,di
        mov     cx,65536/4
        rep     stosd


	pop          gs
	pop          fs
	pop          es
	pop          ds

	popad
	nop

	leave
	retf

_StartStar ENDP

STAR_TEXT ENDS


    END
