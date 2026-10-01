;*****************************************************************************
OUT_16 MACRO Register, Value
    push            ax
    push            dx 
; Macro to OUT a 16 bit value to an I/O port
IFDIFI <Register>, <DX>               ; If DX not setup
    MOV             DX, Register  ; then Select Register
ENDIF
IFDIFI <Value>, <AX>                  ; If AX not setup
    MOV             AX, Value     ; then Get Data Value
ENDIF
    OUT             DX, AX        ; Set I/O Register(s)
    pop             dx
    pop             ax
ENDM
;*****************************************************************************
SETPIX  macro
        push    es

        mov     ax,DGROUP    ; set segment for DGROUP
        mov     fs,ax

        mov     di,fs: _WorkAdr    ;current_pag
        mov     di, word ptr fs:[di]

        mov     ax, y
        shl     ax, 4                   ; * 80
        mov     bx, ax
        shl     ax, 2
        add     ax, bx

        mov     bx, x
        mov     cx, bx
        shr     bx, 2
        add     bx, ax                  ; offset = width*ypos + xpos/4
        mov     ax, MAP_MASK_PLANE1
        and     cl, PLANE_BITS
        shl     ah, cl
        OUT_16  SC_Index, ax            ; s‚lection plan
        mov     al, byte ptr couleur
        mov     es:[di+bx], al          ; inscrit le pixel
        pop     es
endm
;*****************************************************************************
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
;*****************************************************************************
CPU_TIME MACRO lum
LOCAL suite
        cmp     cpu_flag, 1
        jnz     suite
        push    dx
        push    ax
        mov     dx, 3C8h
        xor     al, al
        out     dx, al
        inc     dl
        mov     al, lum
        out     dx, al
        out     dx, al
        out     dx, al
        pop     ax
        pop     dx
suite:
ENDM
;*****************************************************************************
SET_ACTIVE_PAGE MACRO num
        mov     ax, PAGE_ADDR[num*2]
        mov     current_page, ax
ENDM
;*****************************************************************************
SET_VISUAL_PAGE MACRO num
LOCAL WAIT0, WAITV
        mov     dx, INPUT_1             ; voir si on est dans un retrace
WAIT0:
        in      al, dx
        and     al, VERT_RETRACE
        jnz     WAIT0

; set start display address to the new page

        mov     dx, CRTC_Index          ; on modifie le s‚quenceur vga
        mov     cx, PAGE_ADDR[num*2]

        mov     al, START_DISP_LO       ; display start low reg
        mov     ah, cl                  ; low 8 bits of start addr
        out     dx, ax                  ; set display addr low

        mov     al, START_DISP_HI       ; display start high reg
        mov     ah, ch                  ; high 8 bits of start addr
        out     dx, ax                  ; set display addr high

; wait vrt
        mov     dx, INPUT_1
waitv:
        in      al, dx
        and     al, VERT_RETRACE
        jz      waitv

ENDM
;*****************************************************************************
CLEAR_VGA_SCREEN MACRO
        push    eax
        push    fs
        push    es
        push    di
        push    cx

        mov     ax,DGROUP    ; set segment for DGROUP
        mov     fs,ax


        mov     ax, 0A000h
        mov     es, ax
        OUT_16  SC_Index, All_Planes_On
        mov     di,fs:_WorkAdr ;current_page
        mov     di, word ptr fs:[di]
        xor     eax, eax
        cld
        mov     cx, PAGE_SIZE/4
        rep     stosd

        pop     cx
        pop     di
        pop     es
        pop     fs
        pop     eax
ENDM
;*****************************************************************************
