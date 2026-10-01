;***************************************************
;* Multi-Fire effect / Type One 1994 TFL-TDV Prod. *
;***************************************************

INCLUDE VIDEO.INC ; Flamoot VGA SetUp
INCLUDE PLAYINFO.INC ; Player structures
INCLUDE KEYBOARD.INC ; Keyboard macros

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
DGROUP GROUP _DATA,_BSS
MFIRE_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
            ASSUME CS:MFIRE_TEXT,DS:DGROUP
MFIRE_TEXT  ENDS
_DATA  SEGMENT DWORD PUBLIC USE16 'DATA'
_DATA  ENDS
_BSS   SEGMENT DWORD PUBLIC USE16 'BSS'
_BSS   ENDS
;-----------------------------------------

_DATA SEGMENT

; qques constantes ...
Hght=40 
Wdth=80
Meche=2 
Larg=320
Haut=400
Debut=40

Screen1 = 0
Screen2 = (Larg*Haut/4)

Pal LABEL BYTE                ; fire pal
    i=0
    REPT 32
    DB i*2,i,0                ; red
    i=i+1
    ENDM
    i=0
    REPT 32
    DB 63,32+i,i*2
    i=i+1
    ENDM

    i=0
    REPT 32
    DB 0,i,i*2                ; blue
    i=i+1
    ENDM
    i=0
    REPT 32
    DB i*2,32+i,63
    i=i+1
    ENDM

    i=0
    REPT 32
    DB i,0,i*2                ; mauf
    i=i+1
    ENDM
    i=0
    REPT 32
    DB 32+i,i,63
    i=i+1
    ENDM

    i=0
    REPT 32
    DB 0,i*2,i                ; green
    i=i+1
    ENDM
    i=0
    REPT 32
    DB i,63,32+i
    i=i+1
    ENDM

EXTRN _BlackPal: BYTE
EXTRN _WhitePal: BYTE

_DATA ENDS

; donn‚es non initialis‚es
;--------------------------
_BSS SEGMENT

; externes
EXTRN _FrameCounter     : WORD
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


ALIGN 4
EVEN
; fire data
SizeBuf EQU (Hght+2+Meche)*Wdth
BufSeg WORD ?           ; seg of buffer for flames

;---- param pour synchro avec zizik ----
EVEN
DebSong  WORD ?
FinSong  WORD ?

Compteur WORD ?

EVEN
Timeleft WORD ?        ; temps restant pour execution
FadeFlag WORD ?        ; flag pour fading
FadePtr1 WORD 2 DUP(?) ; ptr sur palette a fader
FadePtr2 WORD 2 DUP(?)
Delai    WORD ?

_BSS ENDS

MFIRE_TEXT SEGMENT
      EXTRN _GetRandom : FAR 
      EXTRN _AveragePAL : FAR
      PUBLIC _StartMulFire


; Point d'entr‚e de l'intro !!!!!
;---------------------------------
ALIGN
EVEN
_StartMulFire PROC FAR

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
         call    Mulfire             ; !!!!! multi-fire part !!!!!
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

_StartMulFire ENDP

;*******************
;* Multi-fire part *
;*******************
ALIGN
EVEN
Mulfire PROC NEAR

;------------------------------------------------------------------------------

         pushad

         STARTUP

         mov     ah,48h                ; MALLOC
         mov     bx,(SizeBuf SHR 4)+1  ; memory requested
         int     21h
         mov     BufSeg,ax             ; Segment address returned

         mov     Timeleft,128          ; val bidon .....
         call    InitBuffer            ; clear flame buffer

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

     
         mov     _FadeON,0
         mov     FadeFlag,0
         mov     FadePtr1,OFFSET _BlackPal  ; Black to pic for the beginning !!!
         mov     ax,ds
         mov     FadePtr1+2,ax
         mov     FadePtr2,OFFSET Pal
         mov     ax,ds
         mov     FadePtr2+2,ax
;         mov     ax,_FrameCounter
;         mov     Delai,ax
         mov     _FrameCounter,0
         mov     Delai,0

         mov     bx,_StartAdr
         mov     WORD PTR[bx],Screen1       ; _StartAdr->base = 0
         mov     bx,_WorkAdr
         mov     WORD PTR[bx],Screen2       ; _WorkAdr->base
         mov     WORD PTR[bx+2],0           ; _WorkAdr->flag=false
         mov     _Triple,0                  ; double buffering

         mov     _SyncFlag,1
         VSYNC
EVEN
MainFire: ; -= VSYNC =-
wait_for_VBL:                       ; wait for Sync Flag
         cmp     _SyncFlag,1
         jne      wait_for_VBL
         mov     _SyncFlag,0
wait2frames:
         cmp     _FrameCounter,2    ; REM: assume DS=_DATA
         jb      wait2frames

         cmp     FadeFlag,255
         jb      NewFade
         mov     _FadeON,0          ; no more new PAL ....
         jmp     @F
NewFade: mov     ax,FadeFlag        ; average Black-MyPal
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
         mov     cx,_FrameCounter
         sub     cx,Delai             ; temps chargement
         mov     Delai,0              ; plus delai ....
         test    cx,cx
         jnz     Faddi
         inc     cx
Faddi:   add     FadeFlag,2           ; inc fade ..
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
         cmp     ax,WORD PTR[FinSong]   ; is it time ????
         jb      PasFin                 ; to stop the fire ????

         cmp     Timeleft,0
         je      @F 
         mov     Compteur,64            ; encore 64 pages a calculer ...
@@:  
         mov     Timeleft,0
         xor     eax,eax

         dec     Compteur                ; dec compteur de fin
         jz      GoOutFire

PasFin:
         mov     _FrameCounter,0 ; set counter to NULL
;--------------------------------------------------------------------

         SHOWTIME 48

         call    CalcBuffer          ; average the flame

         SHOWTIME 32
   
         call    PutBuffer           ; put it onto screen

         SHOWTIME 0

         mov    bx,_WorkAdr          ; New screen base
         mov    WORD PTR[bx+2],1     ; _WorkAdr->flag = true


         LOOP_UNTIL_KEY MainFire

GoOutFire:

        FLUSH_KEYBUF                  ; Flush keyboard buffer !!! ;-)

        mov     _FadeON,0             ; don't set _TmpPal !!!           

;----- EXIT -----

        mov     ax,BufSeg             ; segment to free
        mov     es,ax
        mov     ah,49h                ; MFREE
        int     21h

        popad
        nop
        ret

Mulfire ENDP

;-----------------------------

ALIGN
EVEN
InitBuffer PROC NEAR
   MPUSH cx,di,eax,es

   mov   cx,Hght*Wdth/4
   mov   ax,BufSeg
   mov   es,ax
   xor   di,di
   xor   eax,eax
   rep   stosd            ; clear flame buffer

   MPOP  cx,di,eax,es
   ret
InitBuffer ENDP

;********************************
; calculate flame averaging ....
;********************************
ALIGN
EVEN
CalcBuffer PROC NEAR                  ; do a flame into buffer

      MPUSH eax,ebx,cx,si,es,ds

      cmp   Timeleft,64
      ja    @F
      push  di
      mov   cx,(Wdth/4)*2             ; turn off the fire
      mov   di,Wdth*(Hght+Meche)
      mov   ax,BufSeg
      mov   es,ax
      xor   eax,eax 
      cld
      rep   stosd                     ; water !!! :-)
      pop   di
      jmp   JumpIt

@@:
      call  _GetRandom
      mov   bx,ax
      shr   bx,9

      mov   cx,Wdth                   ; calculate alea-lines
      mov   si,Wdth*(Hght+Meche)
      mov   ax,BufSeg
      mov   es,ax
EVEN
flam: call  _GetRandom 
      cmp   ax,10000
      ja    @F
      call  _GetRandom 
      mov   bx,ax
      shr   bx,9                      
@@:   mov   BYTE PTR es:[si],bl
      mov   BYTE PTR es:[si+Wdth],bl
      inc   si
      dec   cx                        ; loop  flam
      jnz   flam 


JumpIt:

      push  es
      pop   ds
                                      ; calculate averages
      mov   si,Wdth
      mov   ebx,03f3f3f3fh            ; mask pour parasites
      mov   cx,(Wdth*(Hght+Meche))/4
EVEN
avr:
      lodsd
      add   eax,DWORD PTR[si-1-4]     ; procede by 4 pixels in 1 time
      add   eax,DWORD PTR[si+1-4]
      add   eax,DWORD PTR[si+Wdth-4]
      shr   eax,2                     ; average
      and   eax,ebx
      test  al,al                     ; fade
      jz    @F
      dec   al
@@:   test  ah,ah
      jz    @F
      dec   ah
@@:   ror   eax,16
      test  al,al
      jz    @F
      dec   al
@@:   test  ah,ah
      jz    @F
      dec   ah
@@:   ror   eax,16
  
      mov   DWORD PTR[si-Wdth-4],eax  ; higher !!!
      dec   cx                        ; loop  avr
      jnz   avr

      MPOP  eax,ebx,cx,si,es,ds
      ret

CalcBuffer ENDP

;************************************
;* Put the flame buffer onto screen *
;************************************
ALIGN
EVEN
PutBuffer PROC NEAR

      MPUSH eax,bx,cx,dx,ebp,si,di,ds,es,fs

      mov   ax,0a000h                 ; put buffer onto screen
      mov   es,ax

; *** first part ***

      mov   dx,03c4h
      mov   ax,0a02h
      out   dx,ax                     ; bitplanes 3+1

      push  ds
      pop   fs

      mov   ax,BufSeg
      mov   ds,ax
      xor   si,si
      mov   di,fs:[_WorkAdr]
      mov   di,WORD PTR fs:[di]       ; screen page
      add   di,Debut*Larg/4 +Wdth*(Hght*2) 
      mov   bx,di
      add   bx,Wdth*(Hght*2)*4-Wdth -Wdth*(Hght*2)*2

      mov   ebp,40404040h             ; 4x64
      mov   cx,(Hght*2)/2             ; Flame up/down
EVEN
lbl1:
      mov   dx,cx
      mov   cx,Wdth/4
EVEN
lbl2:
      lodsd
      mov   es:[di+Wdth*2],eax        ; up
      mov   es:[di+Wdth*4],eax
      stosd
      add   eax,ebp                   ; color +64
      mov   es:[bx],eax
      mov   es:[bx-Wdth*2],eax        ; down 
      mov   es:[bx-Wdth*4],eax
      add   bx,4
      dec   cx                        ; loop  lbl2
      jnz   lbl2
      add   di,Wdth*5 
      sub   bx,Wdth*7 

      mov   cx,dx
      dec   cx                        ; loop  lbl1
      jnz   lbl1

; *** second part ***
 
      mov   dx,3c4h
      mov   ax,502h                   ; bitplanes 2+0 
      out   dx,ax

      mov   di,fs:[_WorkAdr]
      mov   di,WORD PTR fs:[di]       ; screen page
      add   di,Debut*Larg/4 +Wdth/2
      mov   bx,di
      sub   bx,2 
      xor   si,si
      mov   cx,(Hght*2)               ; Flames left/right 
EVEN
lbl4:
      mov   dx,cx
      mov   cx,Wdth/2/2
EVEN
lbl5:
      mov   al,ds:[si]
      mov   ah,ds:[si+Wdth]
      add   ax,8080h                  ; col+128
      mov   es:[di+Wdth*2],ax         ; left
      stosw
      add   ax,4040h                  ; col+128+64
      xchg  al,ah
      mov   es:[bx],ax
      mov   es:[bx+Wdth*2],ax         ; right
      sub   bx,2
      add   si,Wdth*2
      dec   cx                        ; loop  lbl5
      jnz   lbl5
 
      add   di,Wdth*3 +Wdth/2
      add   bx,Wdth*5 -Wdth/2

      mov   cx,dx
      sub   si,Wdth*Wdth/2-1 
      dec   cx                        ; loop  lbl4
      jnz   lbl4

      MPOP  eax,bx,cx,dx,ebp,si,di,ds,es,fs
      ret

PutBuffer ENDP

MFIRE_TEXT ENDS

      END
