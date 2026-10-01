;*******************************************
; ANSI-PUT (C) 1994 Type One / TFL-TDV Prod.
;*******************************************

;-----------------------------------------
; D‚claration modŠle m‚moire
.386
ANS_TEXT  SEGMENT DWORD PUBLIC USE16 'CODE'
          ASSUME CS:ANS_TEXT,DS:ANS_DAT
ANS_TEXT  ENDS
ANS_DAT   SEGMENT DWORD PRIVATE USE16 'FAR_DATA'
ANS_DAT   ENDS
;-----------------------------------------

ANS_DAT SEGMENT 

       INCLUDE pa2.inc  ; ANSI P.A. BBS II

CoulSize EQU 375*4
CoulSeg WORD ?   ; ptr sur segment gradiant

ANS_DAT ENDS

ANS_TEXT SEGMENT

     EXTRN _WaitVBL: FAR
     EXTRN _WaitHBL: FAR
     PUBLIC _PutANSI

;---- MACROs ----

HSYNC MACRO
      call _WaitHBL
      ENDM

VSYNC MACRO
      call _WaitVbl
      ENDM

STARTUP MACRO
        mov ax,ANS_DAT
        mov ds,ax
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

;---------------------- INIT ------------------------------------------

_PutANSI PROC FAR

         push    bp
         mov     bp,sp
         pushad
         MPUSH   ds,es,fs,gs

         STARTUP

         cli

         mov     al,3                 ; Mode Texte 80x25
         xor     ah,ah
         int     10h
         mov     ax,1112h             ; fonte 8x8
         xor     bl,bl
         int     10h
         mov     ah,01h               ; D‚finit Curseur blanc...
         mov     cx,0ff00h
         int     10h

         mov     ah,48h                ; MALLOC
         mov     bx,(CoulSize SHR 4)+1 ; memory requested
         int     21h
         mov     CoulSeg,ax            ; Segment address returned

         call    InitAnsiCol           ; genere gradiant

         mov     cx,20                 ; pause
@@:      VSYNC 
         loop    @B

         mov     si,OFFSET IMAGEDATA  ; Put ANSI Screen
         mov     ax,0B800h
         mov     es,ax
         xor     di,di
         xor     eax,eax
         mov     cx,80*50/2           ; !!!!! Fuck TIME !!!!!
         rep     stosd                ; arf arf, bien fait SAM !!!
         xor     di,di
         mov     cx,IMAGEDATA_LENGTH
         call    UNCRUNCH

         push    ds
         mov     ax,CoulSeg          ; segment couleur
         mov     ds,ax

Ansi:    VSYNC
         xor     si,si               ; begin of gradiant
         mov     dx,3dah
         mov     cx,56-32
@@:      HSYNC                       ; on passe le logo.....
         dec     cx
         jnz     @B  
         mov     cx,343+32
@@:    ;  HSYNC                       ; d‚grad‚ sur coordonn‚es
         
; cf Wizard/IMPCDA :-)
         
         mov     dx,3dah
Wizard1: in      al,dx
         test    al,1
         jnz     Wizard1

         mov     dl,0c8h
         outsw
         inc     dl
         outsb                        ; don't poke the last component yet !!!!

         mov     dl,0dah
Wizard2: in      al,dx
         test    al,1
         jz      Wizard2  

         mov     dl,0c9h
         outsb                        ; last component !!!!! 
         dec     cx
         jnz     @B

         in      al,60h              ; EXIT ?
         cmp     al,39h              ; Space Bar ...
         je      @F
         cmp     al,1                ; Escape ...
         jne     Ansi

@@:      mov     ax,40h              ; !!! Vider buffer clavier !!! ;-)
         mov     es,ax
         mov     ax,es:[001ah]
         mov     es:[001ch],ax

         pop     ds

         sti

         mov     ax,CoulSeg            ; segment to free
         mov     es,ax
         mov     ah,49h                ; MFREE
         int     21h

         MPOP    ds,es,fs,gs
         popad
         nop
         leave

         retf

_PutANSI ENDP

InitAnsiCol PROC NEAR

       MPUSH     eax,cx,bx,di,es

       mov       ax,CoulSeg
       mov       es,ax

       xor       di,di
       xor       bl,bl

       mov       cx,62
@@:    mov       WORD PTR es:[di],2            ; i = 0
       mov       WORD PTR es:[di+4],2          ; REPT 62
       mov       WORD PTR es:[di+8],2          ; db 2,0,i/2,i
       mov       BYTE PTR es:[di+3],bl         ; db 2,0,i/2,i+1
       mov       BYTE PTR es:[di+11],bl        ; db 2,0,i/2,i
       mov       al,bl                         ; i=i+1
       inc       al                            ; ENDM
       mov       BYTE PTR es:[di+7],al
       mov       al,bl
       shr       al,1
       mov       BYTE PTR es:[di+2],al
       mov       BYTE PTR es:[di+6],al
       mov       BYTE PTR es:[di+10],al
       add       di,3*4
       inc       bl
       loop      @B

       xor       eax,eax                       ; i = 0
       mov       cx,63                         ; REPT 63
@@:    stosd                                   ; db 0,i,0,0
       add       eax,100h                      ; i=i+1
       loop      @B                            ; ENDM

       mov       DWORD PTR es:[di],0           ; i = 0
       mov       DWORD PTR es:[di+4],1 SHL 24  ; REPT 4
       mov       DWORD PTR es:[di+8],2 SHL 24  ; db 0,0,0,i
       mov       DWORD PTR es:[di+12],3 SHL 24 ; i=i+1
       add       di,4*4                        ; ENDM

       mov       eax,4 SHL 24                  ; REPT 12
       mov       cx,12                         ; db 0,0,0,i
@@:    stosd                                   ; db 0,0,0,i
       stosd                                   ; db 0,0,0,i+1
       add       eax,1 SHL 24                  ; i=i+2
       stosd                                   ; ENDM
       add       eax,1 SHL 24
       loop      @B

       mov       cx,35                         ; REPT 35
@@:    stosd                                   ; db 0,0,0,i
       stosd                                   ; db 0,0,0,i
       add       eax,1 SHL 24                  ; i=i+1
       loop      @B                            ; ENDM

       sub       eax,1 SHL 24                  ; i=i-1

       mov       cx,5                          ; REPT 5
@@:    stosd                                   ; db 0,0,0,i
       stosd                                   ; db 0,0,0,i
       stosd                                   ; db 0,0,0,i
       loop      @B                            ; ENDM

       xor       eax,eax                       ; db 0,0,0,0
       stosd

       MPOP      eax,cx,bx,di,es

       ret

InitAnsiCol ENDP

;THEDRAW IMAGE UNCRUNCHING ROUTINE
;-----------------------------------------------------------------------------
;Compatible with MASM (Microsoft) and TASM v1.0 (Borland).  Minor format
;changes may be required for other assemblers.
;-----------------------------------------------------------------------------
;
;This is the routine for displaying crunched TheDraw image files.  The
;crunched data format is a simple custom protocol for reproducing any image.
;The control codes below decimal 32 are reserved for this function.
;Characters 32 and above are written directly to the destination address.
;
;The following shows the format of a control code sequence.  Please note that
;not all functions use the optional bytes <x> or <y>.
;
;Data Structure:  <current byte>[<x>[<y>]]
;
;   0..15 = New Foreground Color
;  16..23 = New Background Color
;      24 = Go down to next line, return to same horizontal position as when
;           routine was started (akin to a c/r).
;      25 = Displays <x> number of spaces.
;      26 = Displays <x> number of <y>.  Also used to display ANY characters
;           below #32.  This function is the only way to do this although it
;           uses three bytes.  Otherwise the code would be interpreted as
;           another command.
;      27 = Toggles on/off the foreground attribute blink flag.
;  28..31 = reserved
;
;----------------------------------------------------------------------------
;
;To use the routine, call the uncrunch procedure with the DS:SI register pair
;pointing to the TheDraw output listing, the ES:DI register pair pointing to
;the destination display address, and the length of the crunched image data
;in the CX register.  All modified registers are restored upon exiting.
;
;Assume an output file of a 40 character by 10 line block.  The label
;'IMAGEDATA' has been added for referencing purposes. ie:
;
;
;     ;TheDraw Assembler Crunched Screen Image
;     IMAGEDATA_WIDTH EQU 40
;     IMAGEDATA_DEPTH EQU 10
;     IMAGEDATA_LENGTH EQU 467
;     IMAGEDATA LABEL BYTE
;                DB      ...list of image bytes here...
;
;
;The following assembly language code could then be used to display the
;40x10 block on the screen with:
;
;                MOV     SI,offset IMAGEDATA
;                MOV     AX,0B800h
;                MOV     ES,AX
;                MOV     DI,34*2 + 5*160-162
;                MOV     CX,IMAGEDATA_LENGTH
;                CALL    UNCRUNCH
;
;The data segment (DS register) is assumed to point at the segment ImageData
;resides in.   The ES:DI register pair points at position (34,5) on the color
;graphics adapter screen, calculated as an offset from the start of the screen.
;Monochrome card users, replace the 0B800h with 0B000h.
;
;The original horizontal starting offset is remembered by the uncrunch routine.
;The offset is restored upon moving down to the next line.  This permits a
;block to be displayed correctly anywhere on the screen.  ie:
;
;              ÚÄ horizontal starting offset
;              V
;  +-------------------------------------------------+
;  |                                                 |
;  |                                                 | <- Assume this
;  |                                                 |    is the video
;  |           ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿               |    display.
;  |           ³ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ³               |
;  |           ³ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ³               |
;  |           ³ÛÛ ImageData block ÛÛ³               |
;  |           ³ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ³               |
;  |           ³ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ³               |
;  |           ³ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ³               |
;  |           ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ               |
;  |                                                 |
;  |                                                 |
;  |                                                 |
;  +-------------------------------------------------+
;
;
;To display the block in the lower-right corner, change the DI assignment to:
;
;                MOV     DI,40*2 + 15*160-162
;
;The block is 40 characters wide by 10 lines deep.  To display on a 80 by 25
;screen, we must display the block at coordinates (40,15).  To display in
;the upper-left screen corner use:
;
;                MOV     SI,offset IMAGEDATA
;                MOV     AX,0B800H
;                MOV     ES,AX
;                MOV     DI,1*2 + 1*160-162       ;coordinates 1,1
;                MOV     CX,IMAGEDATA_LENGTH
;                CALL    UNCRUNCH
;
;Notice in both cases only the offset address changed.  Note the latter case
;is also used for displaying a full screen image (which in general are
;always displayed at coordinate 1,1).
;
;----------------------------------------------------------------------------
;
;That's it!  The routine was designed for easy use and understanding; however,
;for some people the best way is to experiment.  Create a program using the
;above examples, perhaps with a 40x10 block (or any size).  Good luck!
;

UNCRUNCH PROC NEAR
;
;Parameters Required:
;  DS:SI  Crunched image source pointer.
;  ES:DI  Display address pointer.
;  CX     Length of crunched image source data.
;
       PUSH    SI                      ;Save registers.
       PUSH    DI
       PUSH    AX
       PUSH    BX
       PUSH    CX
       PUSH    DX
       JCXZ    Done

       MOV     DX,DI                   ;Save X coordinate for later.
       XOR     AX,AX                   ;Set Current attributes.
       CLD

LOOPA: LODSB                           ;Get next character.
       CMP     AL,32                   ;If a control character, jump.
       JC      ForeGround
       STOSW                           ;Save letter on screen.
Next:  LOOP    LOOPA
       JMP     Short Done

ForeGround:
       CMP     AL,16                   ;If less than 16, then change the
       JNC     BackGround              ;foreground color.  Otherwise jump.
       AND     AH,0F0H                 ;Strip off old foreground.
       OR      AH,AL
       JMP     Next

BackGround:
       CMP     AL,24                   ;If less than 24, then change the
       JZ      NextLine                ;background color.  If exactly 24,
       JNC     FlashBitToggle          ;then jump down to next line.
       SUB     AL,16                   ;Otherwise jump to multiple output
       ADD     AL,AL                   ;routines.
       ADD     AL,AL
       ADD     AL,AL
       ADD     AL,AL
       AND     AH,8FH                  ;Strip off old background.
       OR      AH,AL
       JMP     Next

NextLine:
       ADD     DX,160                  ;If equal to 24,
       MOV     DI,DX                   ;then jump down to
       JMP     Next                    ;the next line.

FlashBitToggle:
       CMP     AL,27                   ;Does user want to toggle the blink
       JC      MultiOutput             ;attribute?
       JNZ     Next
       XOR     AH,128                  ;Done.
       JMP     Next

MultiOutput:
       CMP     AL,25                   ;Set Z flag if multi-space output.
       MOV     BX,CX                   ;Save main counter.
       LODSB                           ;Get count of number of times
       MOV     CL,AL                   ;to display character.
       MOV     AL,32
       JZ      StartOutput             ;Jump here if displaying spaces.
       LODSB                           ;Otherwise get character to use.
       DEC     BX                      ;Adjust main counter.

StartOutput:
       XOR     CH,CH
       INC     CX
       REP STOSW
       MOV     CX,BX
       DEC     CX                      ;Adjust main counter.
       LOOPNZ  LOOPA                   ;Loop if anything else to do...

Done:  POP     DX                      ;Restore registers.
       POP     CX
       POP     BX
       POP     AX
       POP     DI
       POP     SI
       RET

UNCRUNCH ENDP

ANS_TEXT ENDS

       END


