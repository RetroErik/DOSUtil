; =============================================================================
; XGA Demo - Step 1: Build & Run Pipeline Check
; -----------------------------------------------------------------------------
; Target : IBM PS/2 Model 55SX with IBM XGA-1 (tested in 86Box)
; Tool   : NASM (-f bin) -> DOS .COM
; Purpose: Verify the full edit -> NASM -> 86Box -> screenshot -> exit loop
;          BEFORE we touch any XGA-specific registers. This program uses only
;          BIOS INT 10h with plain VGA mode 13h (320x200x256). The XGA card
;          contains a fully VGA-compatible core, so mode 13h is guaranteed to
;          work on the 55SX+XGA-1 hardware and in 86Box.
;
; Behavior:
;   1. Save current video mode.
;   2. Set VGA mode 13h (320x200x256, linear at A000:0000).
;   3. Fill the screen with a vertical color gradient (entry 0..199 each row).
;   4. Draw a 16x16 white square in the top-left so we can confirm orientation.
;   5. Wait for ESC.
;   6. Restore original video mode and return cleanly to DOS.
;
; Build (VS Code task "Build COM (NASM)"):
;   nasm -f bin step1_pipeline.asm -o bin\step1_pipeline.COM -l bin\step1_pipeline.lst
; =============================================================================

        cpu     386                     ; 55SX is 386SX; harmless if downgraded
        bits    16
        org     0100h                   ; DOS .COM entry point

; -----------------------------------------------------------------------------
; Entry
; -----------------------------------------------------------------------------
start:
        ; --- save current video mode so we can restore on exit -----------
        mov     ah, 0Fh                 ; INT 10h / get current video state
        int     10h
        mov     [orig_mode], al         ; AL = current mode number

        ; --- set VGA mode 13h: 320x200x256, linear, A000:0000 ------------
        mov     ax, 0013h
        int     10h

        ; --- paint a vertical gradient (row N => color N) ----------------
        push    0A000h
        pop     es
        xor     di, di                  ; ES:DI = A000:0000
        xor     dh, dh                  ; DH = row index 0..199
.row_loop:
        mov     al, dh                  ; color = row index (cycles 0..255)
        mov     cx, 320                 ; 320 pixels per row
        rep stosb
        inc     dh
        cmp     dh, 200
        jb      .row_loop

        ; --- top-left 16x16 white reference square -----------------------
        xor     di, di
        mov     cx, 16                  ; 16 rows
.sq_row:
        push    cx
        push    di
        mov     al, 0Fh                 ; palette entry 15 (white in default DAC)
        mov     cx, 16                  ; 16 pixels
        rep stosb
        pop     di
        add     di, 320                 ; next scanline
        pop     cx
        loop    .sq_row

        ; --- wait for ESC ------------------------------------------------
.wait_esc:
        mov     ah, 00h                 ; INT 16h / read key (blocking)
        int     16h
        cmp     al, 1Bh                 ; ESC?
        jne     .wait_esc

        ; --- restore original video mode ---------------------------------
        mov     ah, 00h
        mov     al, [orig_mode]
        int     10h

        ; --- exit to DOS, errorlevel 0 -----------------------------------
        mov     ax, 4C00h
        int     21h

; -----------------------------------------------------------------------------
; Data
; -----------------------------------------------------------------------------
orig_mode:      db      03h             ; safe default if INT 10h/0F fails
