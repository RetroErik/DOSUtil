; ------------------------------------------------------
; Module Graphique (Mode X) 320x200 256 couleurs (60Hz)
; programmation : Morflame (Septembre 1994)
; Utilise le gourou mode de Type One [Tfl]
; ------------------------------------------------------
                              
; ===  - Valeurs registres VGA -  ===
                              
VGA_Segment     EQU     0A000h                ; Segment m‚moire vga
ATTRIB_Ctrl     EQU     03C0h                 ; Contr“leur d'attribut VGA 
GC_Index        EQU     03CEh                 ; Contr“leur graphique VGA 
SC_Index        EQU     03C4h                 ; Contr“leur s‚quenceur VGA
SC_Data         EQU     03C5h                 ; Port de donn‚es s‚q. VGA
CRTC_Index      EQU     03D4h                 ; Contr“leur crt VGA
CRTC_Data       EQU     03D5h                 ; Contr“leur donn‚es crt VGA
MISC_OUTPUT     EQU     03C2h                 ; Registre VGA divers
INPUT_1         EQU     03DAh                 ; Registre statut d'input #1
                              
DAC_WRITE_ADDR  EQU     03C8h                 ; Reg addr ‚criture DAVGA
DAC_READ_ADDR   EQU     03C7h                 ; Reg addr lecture DAVGA
PEL_DATA_REG    EQU     03C9h                 ; Reg donn‚es R/W DAC/PEL VGA
PIXEL_PAN_REG   EQU     033h                  ; Index attr: Reg pixel pan
MAP_MASK        EQU     002h                  ; Index seq : write map mask
READ_MAP        EQU     004h                  ; Reg lect map GIndex
START_DISP_HI   EQU     00Ch                  ; CRTIndex: display start hi
START_DISP_LO   EQU     00Dh                  ; CRTIndex: display start lo
                              
MAP_MASK_PLANE1 EQU     00102h                ; Map Register + Plane 1 
MAP_MASK_PLANE2 EQU     01102h                ; Map Register + Plane 2
ALL_PLANES_ON   EQU     00F02h                ; Map Register + All Bit Planes

PLANE1_ON       EQU     0102h                              
PLANE2_ON       EQU     0202h                              
PLANE3_ON       EQU     0402h
PLANE4_ON       EQU     0802h

CHAIN4_OFF      EQU     00604h                ; Chain 4 mode Off
ASYNC_RESET     EQU     00100h                ; (A)synchronous Reset
SEQU_RESTART    EQU     00300h                ; Sequencer Restart
                              
LATCHES_ON      EQU     00008h                ; Bit Mask + Data from Latches
LATCHES_OFF     EQU     0FF08h                ; Bit Mask + Data from CPU 
                                                                  
VERT_RETRACE    EQU     08h                   ; INPUT_1: Vertical Retrace Bit
PLANE_BITS      EQU     03h                   ; Bits 0-1 of Xpos = Plane #
ALL_PLANES      EQU     0Fh                   ; All Bit Planes Selected
CHAR_BITS       EQU     0Fh                   ; Bits 0-3 of Character Data
                              
GET_CHAR_PTR    EQU     01130h                ; VGA BIOS Func: Get Char Set 
ROM_8x8_Lo      EQU     03h                   ; ROM 8x8 Char Set Lo Pointer 
ROM_8x8_Hi      EQU     04h                   ; ROM 8x8 Char Set Hi Pointer 
                              
; ===  - Constantes propres … l'unit‚ -  ===
                              
FALSE           EQU     0
TRUE            EQU     -1
nil             EQU     0
                              
SCREEN_WIDTH    EQU     80                    ; largeur en bytes
SCREEN_HEIGHT   EQU     200                   ; hauteur en pixels
LAST_PAGE       EQU     4                     ; # de pages
PAGE_SIZE       EQU     16000                 ; taille d'une page en bytes
                              
; ===  - Variables propres … l'unit‚ -  ===
MRF_TEXT ENDS
_DATA2 SEGMENT
                              
;PAGE_ADDR       DW      0, 16000, 32000, 48000 ; offsets de chaque page
;VISUAL_PAGE     DW      0                      ; page affich‚e
;ACTIVE_PAGE     DW      0                      ; page active
;CURRENT_PAGE    DW      0                      ; offset page courante
CURRENT_SEGMENT DW      0                      ; segment m‚moire VGA
CURRENT_XOFFSET DW      0                      ; offset x actuel (display)
CURRENT_YOFFSET DW      0                      ; offset y actuel (display)
CURRENT_MOFFSET DW      0                      ; offset d‚part actuel
                                               
MAX_XOFFSET     DW      0                      ; maximum x offset (display)
MAX_YOFFSET     DW      0                      ; maximum y offset (display)
                                               
CHARSET_LOW     DW      0, 0                   ; Far Ptr to Char Set:0-127
CHARSET_HI      DW      0, 0                   ; Far Ptr to Char Set:128-255
                                               
; ===  - variables mises dans le code segment pour accŠs plus facile -  ===
                              
_DATA2 ENDS
MRF_TEXT SEGMENT
                              
Left_Clip_Mask  DB 0Fh, 0Eh, 0Ch, 08h
Right_Clip_Mask DB 01h, 03h, 07h, 0Fh
                              
; ===  - Code macros -  ===
                              
OUT_16 MACRO Register, Value
; Macro to OUT a 16 bit value to an I/O port
IFDIFI <Register>, <DX>               ; If DX not setup
    MOV             DX, Register  ; then Select Register
ENDIF
IFDIFI <Value>, <AX>                  ; If AX not setup 
    MOV             AX, Value     ; then Get Data Value
ENDIF
    OUT             DX, AX        ; Set I/O Register(s)
ENDM
                              
OUT_8 MACRO Register, Value
; Macro to OUT a 8 bit value to an I/O Port
IFDIFI <Register>, <DX>               ; If DX not setup
        MOV             DX, Register  ; then Select Register
ENDIF
IFDIFI <Value>, <AL>                  ; If AL not Setup
        MOV             AL, Value     ; then Get Data Value
ENDIF
        OUT             DX, AL        ; Set I/O Register
ENDM
                              
PUSHx MACRO R1, R2, R3, R4, R5, R6, R7, R8
; macros to PUSH and POP multiple registers
IFNB <R1>
        PUSH    R1                    ; Save R1
        PUSHx   R2, R3, R4, R5, R6, R7, R8
ENDIF
ENDM
                              
POPx MACRO R1, R2, R3, R4, R5, R6, R7, R8
        IFNB <R1>
                POP             R1            ; Restore R1
                POPx    R2, R3, R4, R5, R6, R7, R8
        ENDIF
ENDM
                              
CLR MACRO Register
; Macro to Clear a Register to 0
        XOR             Register, Register    ; Set Register = 0
ENDM
                              
SET_320x200 MACRO
; 320x200x256, 4 pages max

        mov     ax, mode <1,2,4,0,0>
        push    ax
        call    _SETVGA

ENDM
                              
;PIX MACRO x, y, color
;        push    es
;        mov     ax, 0A000h
;        mov     es, ax
;        mov     di, current_page
;        mov     ax, y
;        shl     ax, 4                   ; * 80
;        mov     bx, ax
;        shl     ax, 2
;        add     ax, bx
;                                      
;        mov     bx, x
;        mov     cx, bx
;        shr     bx, 2
;        add     bx, ax                  ; offset = width*ypos + xpos/4
;        mov     ax, MAP_MASK_PLANE1
;        and     cl, PLANE_BITS
;        shl     ah, cl
;        OUT_16  SC_Index, ax            ; s‚lection plan
;        mov     al, color
;        mov     es:[di+bx], al          ; inscrit le pixel
;        pop     es
;ENDM
                              
SET_POINT PROC
        push    bp
        mov     bp, sp
        push    fs
        LSFS    _DATA, ax
        push    es
        mov     ax, 0A000h
        mov     es, ax
        mov     di, Dest                ;current_page
        mov     di, word ptr fs:[di]
        mov     ax, [bp+6]
        shl     ax, 4                   ; * 80
        mov     bx, ax
        shl     ax, 2
        add     ax, bx
                                      
        mov     bx, [bp+8]
        mov     cx, bx
        shr     bx, 2
        add     bx, ax                  ; offset = width*ypos + xpos/4
        mov     ax, MAP_MASK_PLANE1
        and     cl, PLANE_BITS
        shl     ah, cl
        OUT_16  SC_Index, ax            ; s‚lection plan
        mov     al, byte ptr [bp+4]
        mov     es:[di+bx], al          ; inscrit le pixel
        pop     es
        pop     fs                      
        leave
        ret 6
SET_POINT ENDP
                              
;SET_ACTIVE_PAGE MACRO num
;        mov     ax, PAGE_ADDR[num*2]
;        mov     current_page, ax
;ENDM
                              
;SET_VISUAL_PAGE MACRO num
;LOCAL WAIT0, WAITV        
;        
;wait0:                       ; wait for Sync Flag
;         cmp     _SyncFlag,1
;         jne      wait0
;         mov     _SyncFlag,0
;
;; set start display address to the new page
;                              
;        mov     dx, CRTC_Index          ; on modifie le s‚quenceur vga
;        mov     cx, PAGE_ADDR[num*2]
;                                      
;        mov     al, START_DISP_LO       ; display start low reg
;        mov     ah, cl                  ; low 8 bits of start addr
;        out     dx, ax                  ; set display addr low
;                                      
;        mov     al, START_DISP_HI       ; display start high reg
;        mov     ah, ch                  ; high 8 bits of start addr
;        out     dx, ax                  ; set display addr high
;                              
;ENDM
COMMENT^                              
HORIZONTAL_LINE PROC
; x1 / x2 / y / color        
        push    bp
        mov     bp, sp
        cld
        OUT_8   SC_INDEX, MAP_MASK
        mov     si, [bp+10]
        mov     di, [bp+8]
        mov     ax, [bp+6]
        shl     ax, 4                   ; * 80
        mov     dx, ax
        shl     ax, 2
        add     dx, ax
        mov     ax, si
        and     si, PLANE_BITS
        mov     bl, Left_Clip_Mask[si]
        mov     cx, di
        and     di, PLANE_BITS
        mov     bh, Right_Clip_Mask[di]
        shr     ax, 2
        shr     cx, 2
        mov     di, 0A000h
        mov     es, di
        mov     di, current_page
        add     di, dx
        add     di, ax
        sub     cx, ax
        jnz     dl_longn
        and     bl, bh
dl_longn:
        OUT_8   SC_Data, bl
        mov     al, byte ptr[bp+4]
        mov     bl, al
        stosb
        jcxz    fin
        dec     cx
        jz      dl_xrseg
                                      
; draw middle segments
                              
        OUT_8   dx, ALL_PLANES
        mov     al, bl
        rep     stosb
dl_xrseg:
        OUT_8   dx, bh
        mov     al, bl
        stosb
fin:
        leave
        ret 8
HORIZONTAL_LINE ENDP
^                              
HLINE MACRO x1, x2, y, color
; suppose es charg‚ … 0A000h !
        push    fs
        LSFS    _DATA, ax
        cld
        OUT_8   SC_INDEX, MAP_MASK
        mov     si, &x1
        mov     di, &x2
        xor     eax, eax
        mov     ax, &y
        
        mov     dx, word ptr[Taby+eax*2]

        mov     ax, si
        and     si, PLANE_BITS
        mov     bl, Left_Clip_Mask[si]
        mov     cx, di
        and     di, PLANE_BITS
        mov     bh, Right_Clip_Mask[di]
        shr     ax, 2
        shr     cx, 2
        
        mov     di, Dest            ;current_page
        mov     di, word ptr fs:[di]
        
        add     di, dx
        add     di, ax
        sub     cx, ax
        jnz     dl_longn
        and     bl, bh
dl_longn:
        OUT_8   SC_DATA, bl
        mov     al, color
        mov     bl, al
        stosb
        jcxz    fin
        dec    cx
        jz      dl_xrseg
                                      
; draw middle segments
                              
        OUT_8   dx, ALL_PLANES
        mov     al, bl
        rep     stosb
dl_xrseg:
        OUT_8   dx, bh
        mov     al, bl
        stosb
fin:    pop     fs
ENDM
                              
CLEAR_VGA_SCREEN MACRO
        push    fs        
        LSFS    _DATA, ax

        mov     ax, 0A000h
        mov     es, ax
        OUT_16  SC_Index, All_Planes_On
        mov     di, Dest            ;current_page
        mov     di, word ptr fs:[di]
        sub     eax, eax
        cld
        mov     cx, PAGE_SIZE/4
        rep     stosd

        pop     fs
ENDM

FILL_VGA_SCREEN MACRO color
        push    fs
        LSFS    _DATA, ax

        mov     ax, 0A000h
        mov     es, ax
        OUT_16  SC_Index, All_Planes_On
        mov     di, Dest ;current_page
        mov     di, word ptr fs:[di]
        mov     al, color
        mov     ah, color
        shl     eax, 16
        mov     al, color
        mov     ah, color
        cld
        mov     cx, PAGE_SIZE/4
        rep     stosd

        pop     fs
ENDM
