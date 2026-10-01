;----------------------------------------------------------------------
; Unit‚ MORGMAC : Macro Graphiques & autres
; Programmation : Morflame [TdV]
;------------------------------------------------------------------------------
SW_PAGES MACRO
LOCAL m1        
        cmp     byte ptr SW, 0
        jnz     @F
        SET_ACTIVE_PAGE 0
        SET_VISUAL_PAGE 1
        mov     byte ptr SW, 1
        jmp     m1
@@:     SET_ACTIVE_PAGE 1
        SET_VISUAL_PAGE 0
        mov     byte ptr SW, 0
m1:
ENDM
;------------------------------------------------------------------------------
CPU_TIME MACRO lum
LOCAL suite        
        cmp     cpu_flag, 1
        jnz     suite
        mov     dx, 3C8h
        xor     al, al
        out     dx, al
        inc     dl
        mov     al, lum
        out     dx, al
        out     dx, al
        out     dx, al
suite:
ENDM
;----------------------------------------------------------------------
MPUSH   MACRO reg1:REQ,reg2:VARARG   ; Vive Y.Roggeman/Greg & ses Macros
        push reg1                    ; recursives !!!!!!! yahouuuuu !!!
        IFNB <reg2>
        MPUSH reg2
        ENDIF
        ENDM
;----------------------------------------------------------------------
MPOP    MACRO reg1:REQ,reg2:VARARG   ; bis bis !!!
        IFNB <reg2>                  ; type brol = record....
        MPOP reg2                    ; donc ‡a fait 20 bytes !!!
        ENDIF                        ; donc 1 word ....
        pop reg1                     ; brol je dis struct !!!
        ENDM
;----------------------------------------------------------------------
ModeSave BYTE ?
Free_Keyboard MACRO         
         mov     ax,40h              ; !!! Vider buffer clavier !!! ;-)
         mov     es,ax
         mov     ax,es:[001ah]
         mov     es:[001ch],ax
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
ClearText MACRO color
        mov     ax, 0600h               ; Scroll screen service
        mov     bh, color               ; Menu display attribute
        sub     cx, cx                  ; From row 0, col 0
        mov     dh, 25                  ;   to bottom row,
        mov     dl, 79                  ;   rightmost column
        int     10h                     ; Clear entire screen
ENDM
;----------------------------------------------------------------------
Init13h MACRO
        mov ax,13h
        int 10h
ENDM
;----------------------------------------------------------------------
CloseVideo MACRO
        mov     ax, 3h
        int     10h
ENDM
;----------------------------------------------------------------------
FillScreen MACRO color
; remplit l'‚cran avec une couleur donn‚e 
           mov     ax,0A000h
           mov     es,ax
           xor     di,di
           mov     al,color
           mov     ah,color
           mov     cx,32000
           rep     stosw
           pop     ax
           pop     cx
           pop     es
ENDM
;----------------------------------------------------------------------
WAITVRT MACRO 
local wait_for_vbl
    
         push    fs
         
         LSFS    _DATA, ax
wait_for_VBL:                       ; wait for Sync Flag
         cmp     fs:_SyncFlag,1
         jne      wait_for_VBL
         mov     fs:_SyncFlag,0
         
         pop     fs    
ENDM
;----------------------------------------------------------------------
WAITHRT MACRO 
local vrt, novrt        
    mov     dx,3dah
VRT:
    in      al,dx
    test    al,1
    jnz     VRT         ; attend que le 'vertical retrace' d‚marre 
NOVRT:
    in      al,dx
    test    al,1
    jz      NOVRT       ; attend que le 'vertical retrace' s'arrˆte
ENDM
;----------------------------------------------------------------------
VGADETECT MACRO
_TEXT ENDS
_DATA2 SEGMENT
NoVga BYTE 'Sorry dude, you need a vga to run this ...',10,13,'$'
Vgaok BYTE 'VGA detected',10,13,'$'
_DATA2 ENDS
_TEXT SEGMENT
;-------- Routine de d‚tection ---------
          xor     bx,bx                ;- VGA Detect -
          mov     ax,01a00h
          int     10h
          cmp     bl,7
          jc      @F
          cmp     bl,00dh
          jc      VGA_Ok
@@:       lea     dx,NoVga             ; Sorry You've not...
          mov     ah,9
          int     21h
          @EXIT
VGA_Ok:   lea     dx,Vgaok
          mov     ah,9
          int     21h
ENDM
;----------------------------------------------------------------------
PC386DETECT MACRO
;- Processor Detect - (C) Bible PC
_TEXT ENDS
_DATA2 SEGMENT
No386 BYTE 'Sorry dude, you need a 386 to run this ',10,13,'$'
Pc386ok BYTE '386 or better detected','$'
_DATA2 ENDS
_TEXT SEGMENT
         xor     ax,ax                ; Fixer AX sur 0
         push    ax                   ; et placer sur la pile
         popf                         ; Retirer de la pile comme reg. de flags
         pushf                        ; Replacer sur la pile
         pop     ax                   ; et ramener dans AX
         and     ax,0f000h            ; Annuler tous les bits sauf les 4 sup.
         cmp     ax,0f000h            ; bits 12 … 15 sont-ils tous … 1 ?
         je      @F                   ; --> Beurk XT : EXIT
         mov     ax,07000h            ; 286 ou 386
         push    ax                   ; Placer la valeur 07000h sur la pile
         popf                         ; Retirer comme registre de flags
         pushf                        ; et replacer sur la pile
         pop     ax                   ; Ramener dans le registre AX
         and     ax,07000h            ; Masquer tous les bits sauf 12 … 14
         jne     pc386_Ok             ; --> Ok 386
@@:      lea     dx,No386             ; d‚sol‚....
         mov     ah,9
         int     21h
         @EXIT
pc386_Ok:lea     dx,Pc386ok
         mov     ah,9
         int     21h
ENDM
;----------------------------------------------------------------------
;Write MACRO text
; LOCAL C
;.DATA
;%C   BYTE &text&,"$"
;.CODE         
;         lea     dx, C
;         mov     ah, 9
;         int     21h
;ENDM
;----------------------------------------------------------------------
;Writeln MACRO text
; LOCAL C
;.DATA
;%C   BYTE &text&,10,13,"$"
;.CODE
;         lea     dx, C
;         mov     ah, 9
;         int     21h
;ENDM
;----------------------------------------------------------------------
GoodBye MACRO
_TEXT ENDS
_DATA2 SEGMENT
Bye BYTE 'Coding : Morflame [TDV] (100% asm) ',13,10
    BYTE 13,10,'C''you soon !!',13,10,'$'
_DATA2 ENDS
_TEXT SEGMENT
         lea     dx,Bye
         mov     ah,9
         int     21h
ENDM
;----------------------------------------------------------------------
ClearTextFast MACRO
; efface l'‚cran sans interruption         
         push   es
         mov    ax, 0B800h
         mov    es, ax
         mov    cx, 80*25*2
         mov    ax, 00h
         rep    stosb
         pop    es
ENDM
;----------------------------------------------------------------------
Clrscr MACRO
; efface l'‚cran et positionne le curseur en haut … gauche
 ClearText 0
         mov    ah, 2h
         mov    bh, 1
         xor    dx, dx
         int    10h
ENDM
;----------------------------------------------------------------------
Save_Mode MACRO
; sauve le mode actif         
         mov    ah, 0fh
         int    10h
         mov    ModeSave, al
ENDM
;----------------------------------------------------------------------
Restore_Mode MACRO
; restore le mode sauv‚ par Save_Mode
         mov    al, ModeSave
         xor    ah, ah
         int    10h
ENDM
;----------------------------------------------------------------------
LOAD_PALETTE MACRO PAL
        mov     cx, 0
        xor     si, si
bcl:    push    cx
        push    cx
        push    word ptr &PAL&[si]
        push    word ptr &PAL&[si+2]
        push    word ptr &PAL&[si+4]
        call    SET_DAC_REGISTER
        add     si, 6
        pop     cx
        inc     cx
        cmp     cx, 256
        jl      bcl
ENDM
;----------------------------------------------------------------------
LOAD_PAL MACRO PAL
LOCAL bcl        
        mov     dx, 3C8h
        mov     ax, 0
        xor     si, si
bcl:    out     dx, al
        inc     dl
        push    ax
        mov     al, byte ptr &PAL&[si]
        out     dx, al
        mov     al, byte ptr &PAL&[si+1]
        out     dx, al
        mov     al, byte ptr &PAL&[si+2]
        out     dx, al
        pop     ax
        dec     dl
        add     si, 3
        inc     ax
        cmp     ax, 256
        jl      bcl
ENDM
;----------------------------------------------------------------------
PALETTE_BLEUE MACRO
        mov     dx, 3C8h
        mov     ax, 0
        xor     si, si
bcl:    out     dx, al
        inc     dl
        mov     bx, ax
        shr     bx, 2
        push    ax
        mov     al, 0
        out     dx, al
        mov     al, 0
        out     dx, al
        mov     al, bl
        out     dx, al
        pop     ax
        dec     dl
        inc     ax
        cmp     ax, 257
        jl      bcl
ENDM
;----------------------------------------------------------------------
PALETTE_BLEUE2 MACRO
        mov     dx, 3C8h
        xor     ax, ax 

        xor     si, si
bcl:    
        out     dx, al
        inc     dl
        
        mov     bx, ax
        
        shr     bx, 3
        add     bx, 32                     
        
        push    ax
        
        mov     al, 0
        out     dx, al
        
        mov     al, 0
        out     dx, al
        
        mov     al, bl
        out     dx, al
        
        pop     ax
        
        dec     dl
        inc     ax
        cmp     ax, 257
        jl      bcl
ENDM
;----------------------------------------------------------------------
