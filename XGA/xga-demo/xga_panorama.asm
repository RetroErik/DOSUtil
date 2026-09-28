; XGA Panorama Flight - IBM PS/2 MCA XGA-1 DOS .COM
; Build: python build_mode_table.py
;        nasm -f bin xga_panorama.asm -o bin\xga_panorama.COM -l bin\xga_panorama.lst
; Optional -DTEST_MODE=1: CPU mode test, -DTEST_MODE=2: 128x128 BitBLT test.
; Register/mode sources: XGAKIT.ASM, MINI/XGA.INC, NT xgaregs.h/xga.h.

cpu 386
bits 16
org 0x100

%ifndef TEST_MODE
%define TEST_MODE 3
%endif
%ifndef PAN_STYLE
%define PAN_STYLE 1                 ; 1 = scanout pan, 0 = full-frame BitBLT
%endif

SCREEN_W equ 640
SCREEN_H equ 480
SOURCE_W equ 800
SOURCE_H equ 800
SOURCE_BASE equ SCREEN_W * SCREEN_H       ; 0x4b000
BLT_OP equ 0xA8218000                    ; source map B -> dest A, SRC_COPY

start:
    push cs
    pop ds
    mov ah, 0x0f
    int 0x10
    mov [old_mode], al
    mov dx, log_boot_name
    call touch_file
    mov dx, msg_start
    call puts
    call detect_xga
    jc .no_xga
    mov dx, log_detect_name
    call touch_file
    cmp dword [aperture], 0
    je .no_aperture
    call set_xga_mode
    mov byte [mode_active], 1
    mov dx, log_mode_name
    call touch_file
%if TEST_MODE != 1
    call probe_vram
    jc .no_vram
%endif
    call set_palette
%if TEST_MODE = 1
    call fill_screen
    jmp .wait_key
%else
    call fill_source
    call setup_maps
%if TEST_MODE = 2
    mov word [es:0x60], 127
    mov word [es:0x62], 127
    mov word [es:0x70], 80
    mov word [es:0x72], 80
    mov word [es:0x78], 256
    mov word [es:0x7a], 176
    mov dword [es:0x7c], BLT_OP
    call wait_cp
    jc .cp_timeout
    jmp .wait_key
%else
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    call full_blit
    jc .cp_timeout
    call log_first_blit
%if PAN_STYLE = 1
    call configure_scanout
%endif
.frame:
%if PAN_STYLE = 0
    call wait_cp
    jc .cp_timeout
    mov ax, [pan_x]
    mov [es:0x70], ax
    mov ax, [pan_y]
    mov [es:0x72], ax
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov dword [es:0x7c], BLT_OP
%else
    call wait_tick
    call update_fps
    call restore_hud
    call set_view
    call show_hud
    call refresh_source_pages
%endif
    mov ah, 1
    int 0x16
    jz .animate
    xor ah, ah
    int 0x16
    cmp al, 27
    je .wait_key
.animate:
    mov ax, [pan_x]
    add ax, [step_x]
    cmp ax, 160
    jbe .x_ok
    neg word [step_x]
    add ax, [step_x]
    add ax, [step_x]
.x_ok:
    mov [pan_x], ax
    mov ax, [pan_y]
    add ax, [step_y]
    cmp ax, 320
    jbe .y_ok
    neg word [step_y]
    add ax, [step_y]
    add ax, [step_y]
.y_ok:
    mov [pan_y], ax
    jmp .frame
%endif
%endif
.wait_key:
%if TEST_MODE != 3
    xor ah, ah
    int 0x16
    cmp al, 27
    jne .wait_key
%endif
    call restore_mode
    mov ax, 0x4c00
    int 0x21
.cp_timeout:
    call restore_mode
    mov dx, log_cp_error
    call touch_file
    mov dx, msg_cp_timeout
    jmp .error
.no_vram:
    call restore_mode
    mov dx, log_vram_error
    call touch_file
    mov dx, msg_no_vram
    jmp .error
.no_aperture:
    mov dx, log_ap_error
    call touch_file
    mov dx, msg_no_aperture
    jmp .error
.no_xga:
    mov dx, log_xga_error
    call touch_file
    mov dx, msg_no_xga
.error:
    call puts
    mov ax, 0x4c01
    int 0x21

puts:
    mov ah, 9
    int 0x21
    ret

touch_file:
    mov ah, 0x3c
    xor cx, cx
    int 0x21
    jc .done
    mov bx, ax
    mov ah, 0x3e
    int 0x21
.done:
    ret

; BIOS MCA POS enumeration; slot 0 is motherboard, 1..8 are expansion slots.
detect_xga:
    mov ax, 0xc400
    int 0x15
    jc .fail
    mov [pos_base], dx
    xor cx, cx
.slot:
    push cx
    cli
    or cx, cx
    jnz .select_slot
    mov al, 0xdf
    out 0x94, al
    jmp .read_pos
.select_slot:
    mov bx, cx
    mov ax, 0xc401
    int 0x15
    jc .deselect
.read_pos:
    mov dx, [pos_base]
    in ax, dx
    mov [card_id], ax
    add dx, 2                      ; POS byte 1
    in al, dx
    mov [pos1], al
    add dx, 2                      ; POS byte 3 is at base + 4
    in al, dx
    mov [pos3], al
    inc dx                         ; POS byte 4 is at base + 5
    in al, dx
    and al, 0x0f
    mov [pos4], al
.deselect:
    pop cx
    or cx, cx
    jnz .normal_slot
    mov al, 0xff
    out 0x94, al
    jmp .compare
.normal_slot:
    push cx
    mov bx, cx
    mov ax, 0xc402
    int 0x15
    pop cx
.compare:
    sti
    cmp word [card_id], 0x8fdb
    je .found
    cmp word [card_id], 0x8fda
    je .found
    inc cx
    cmp cx, 9
    jbe .slot
.fail:
    stc
    ret
.found:
    ; io = 0x2100 + ((POS1 & 0x0e) << 3)
    xor ax, ax
    mov al, [pos1]
    and al, 0x0e
    shl ax, 3
    add ax, 0x2100
    mov [io_base], ax
    ; ROM = 0xc0000 + ((POS1 >> 4) * 0x2000).
    ; CP MMIO = ROM + 0x1c00 + (((POS1 & 0x0e)>>1) * 0x80).
    xor eax, eax
    mov al, [pos1]
    shr al, 4
    shl eax, 13
    add eax, 0xc1c00
    xor ebx, ebx
    mov bl, [pos1]
    and bl, 0x0e
    shl ebx, 6
    add eax, ebx
    shr eax, 4
    mov [cp_seg], ax
    ; 1 MB aperture physical address from POS4. Fall back to the 4 MB
    ; aperture from POS3 when the 1 MB aperture is disabled.
    xor eax, eax
    mov al, [pos4]
    shl eax, 20
    or eax, eax
    jnz .ap_ready
    test byte [pos3], 1
    jz .ap_ready
    mov al, [pos3]
    and al, 0xfe
    shl eax, 24
    xor ebx, ebx
    mov bl, [pos1]
    and bl, 0x0e
    shl ebx, 21
    add eax, ebx
.ap_ready:
    mov [aperture], eax
    ; 86Box's XGA coprocessor resolves VRAM pixel maps against the 4 MB
    ; aperture base, even when the CPU is using the banked 64 KB window.
    ; This is the address decoded from POS3 plus the XGA instance number.
    xor eax, eax
    mov al, [pos3]
    and al, 0xfe
    shl eax, 24
    xor ebx, ebx
    mov bl, [pos1]
    and bl, 0x0e
    shl ebx, 21
    add eax, ebx
    mov [cp_aperture], eax
    clc
    ret

set_xga_mode:
    mov dx, 0x3c3
    mov al, 1
    out dx, al
    mov si, mode_table
.next:
    lodsb
    cmp al, 0xff
    je .done
    mov bl, al
    xor ah, ah
    mov dx, [io_base]
    add dx, ax
    lodsb
    mov ah, [si]
    inc si
    cmp bl, 0x0a
    je .indexed
    mov al, ah
    out dx, al
    jmp .next
.indexed:
    out dx, ax
    jmp .next
.done:
    ret

; Probe two banks separated by 512 KB; a 512 KB card may mirror page 12.
probe_vram:
    mov dx, [io_base]
    add dx, 8
    mov ax, 0xa000
    mov es, ax
    mov al, 4
    out dx, al
    mov byte [es:0], 0x55
    mov al, 12
    out dx, al
    mov byte [es:0], 0xa5
    cmp byte [es:0], 0xa5
    jne .fail
    mov al, 4
    out dx, al
    cmp byte [es:0], 0x55
    jne .fail
    xor al, al
    out dx, al
    clc
    ret
.fail:
    xor al, al
    out dx, al
    stc
    ret

; XGA palette port: index at I/O+0x0a, RGB stream at I/O+0x0b.
set_palette:
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0x0064
    out dx, ax
    mov ax, 0x0066
    out dx, ax
    mov ax, 0x0060
    out dx, ax
    mov ax, 0x0061
    out dx, ax
    mov al, 0x65
    out dx, al
    inc dx
    xor bx, bx
.color:
    ; RRRGGGBB -> three 8-bit DAC components.
    mov ax, bx
    and al, 0xe0
    out dx, al
    mov ax, bx
    and al, 0x1c
    shl al, 3
    out dx, al
    mov ax, bx
    and al, 3
    shl al, 6
    out dx, al
    inc bx
    cmp bx, 256
    jb .color
    dec dx
    mov ax, 0xff64
    out dx, ax
    ret

; On stage 1, fill visible screen by CPU solely to verify mode and banking.
fill_screen:
    mov ax, 0xa000
    mov es, ax
    xor di, di
    xor bx, bx
    mov word [row], 0
.row:
    mov cx, SCREEN_W
    mov al, [row]
.pixel:
    mov [es:di], al
    inc di
    jnz .no_wrap
    inc bx
    call select_bank
.no_wrap:
    loop .pixel
    inc word [row]
    cmp word [row], SCREEN_H
    jb .row
    ret

; Source is 800*800 bytes at offset 307200 in 1 MB of VRAM.
; CPU loads the image once through the 64 KB banked A000 window.
fill_source:
    mov ax, 0xa000
    mov es, ax
    mov bx, 4
    call select_bank
    mov di, 0xb000
    mov word [row], 0
.row:
    mov word [col], 0
.pixel:
    mov ax, [row]
    cmp ax, 240
    jae .ground
    shr ax, 4
    and al, 0x1c
    or al, 3
    jmp .grid
.ground:
    mov ax, [col]
    and ax, 127
    shr ax, 1
    add ax, 240
    cmp [row], ax
    jb .mountain
    mov ax, [row]
    shr ax, 5
    and al, 0x1c
    or al, 0x84
    jmp .grid
.mountain:
    mov ax, [col]
    shr ax, 4
    and al, 0x1c
    or al, 0xa0
.grid:
    test word [col], 63
    jz .line
    test word [row], 63
    jnz .store
.line:
    mov al, 0xff
.store:
    mov [es:di], al
    inc di
    jnz .bank_ok
    inc bx
    call select_bank
.bank_ok:
    inc word [col]
    cmp word [col], SOURCE_W
    jb .pixel
    inc word [row]
    cmp word [row], SOURCE_H
    jb .row
    ret

select_bank:
    push ax
    push dx
    mov dx, [io_base]
    add dx, 8
    mov ax, bx
    out dx, al
    pop dx
    pop ax
    ret

setup_maps:
    mov ax, [cp_seg]
    mov es, ax
    mov byte [es:0x11], 0
    mov byte [es:0x12], 1            ; destination map A
    mov eax, [cp_aperture]
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 3
    mov byte [es:0x12], 2            ; off-screen source map B
    add eax, SOURCE_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SOURCE_W-1
    mov word [es:0x1a], SOURCE_H-1
    mov byte [es:0x1c], 3
    mov byte [es:0x4a], 4            ; color compare disabled
    mov dword [es:0x50], 0xff
    mov dword [es:0x54], 0xff
    mov byte [es:0x48], 3            ; XGA_S
    mov byte [es:0x49], 3
    ret

%if PAN_STYLE = 1
; Scan the 800-pixel-wide source image directly. XGA display start is in
; dwords, and display pitch is expressed in units of eight pixels.
configure_scanout:
    mov word [step_x], 4
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0x6443                  ; 800 / 8 pixels per scan line
    out dx, ax
    mov ax, 0x0044
    out dx, ax
    call set_view
    mov ah, 0
    int 0x1a
    mov [last_tick], dx
    ret

wait_tick:
    push ax
    push cx
    push dx
.again:
    mov ah, 0
    int 0x1a
    cmp dx, [last_tick]
    je .again
    mov [last_tick], dx
    pop dx
    pop cx
    pop ax
    ret

set_view:
    movzx eax, word [pan_y]
    imul eax, eax, SOURCE_W
    movzx ebx, word [pan_x]
    add eax, ebx
    add eax, SOURCE_BASE
    shr eax, 2
    mov ebx, eax
    mov dx, [io_base]
    add dx, 0x0a
    mov ah, bl
    mov al, 0x40
    out dx, ax
    shr ebx, 8
    mov ah, bl
    mov al, 0x41
    out dx, ax
    shr ebx, 8
    mov ah, bl
    mov al, 0x42                  ; latches start address in 86Box
    out dx, ax
    ret

; 86Box skips unmodified VRAM pages during scanout. Rewriting one unchanged
; byte per 4 KB page marks the source image for redraw after a start change.
refresh_source_pages:
    push ax
    push bx
    push si
    push bp
    push es
    mov ax, 0xa000
    mov es, ax
    mov bx, 4
    call select_bank
    mov si, 0xb000
    mov bp, 157                   ; pages 0x4b000 through 0xe7000
.page:
    mov al, [es:si]
    mov [es:si], al
    add si, 4096
    jnz .next
    inc bx
    call select_bank
.next:
    dec bp
    jnz .page
    pop es
    pop bp
    pop si
    pop bx
    pop ax
    ret

; Count completed panorama steps using the PS/2 real-time clock seconds.
; This measures the guest animation loop, not host-window presentation.
update_fps:
    push ax
    push cx
    push dx
    mov ah, 2
    int 0x1a
    jc .done
    cmp byte [hud_second], 0xff
    jne .compare
    mov [hud_second], dh
    jmp .count
.compare:
    cmp dh, [hud_second]
    je .count
    mov [hud_second], dh
    mov al, [hud_frames]
    cmp al, 99
    jbe .store
    mov al, 99
.store:
    mov [hud_fps], al
    mov byte [hud_frames], 0
.count:
    inc byte [hud_frames]
.done:
    pop dx
    pop cx
    pop ax
    ret

restore_hud:
    cmp byte [hud_active], 0
    je .done
    mov eax, [hud_old_addr]
    mov [hud_work_addr], eax
    mov si, hud_saved
    call copy_to_vram
.done:
    ret

show_hud:
    movzx eax, word [pan_y]
    add eax, 8
    imul eax, eax, SOURCE_W
    movzx ebx, word [pan_x]
    add eax, ebx
    add eax, SOURCE_BASE + 8
    mov [hud_old_addr], eax
    mov [hud_work_addr], eax
    mov si, hud_saved
    call copy_from_vram
    call render_hud
    mov eax, [hud_old_addr]
    mov [hud_work_addr], eax
    mov si, hud_canvas
    call copy_to_vram
    mov byte [hud_active], 1
    ret

; Rectangle copy: 48 x 10 bytes at hud_work_addr, with an 800-byte pitch.
; Recompute the bank for each row and also handle a row crossing a bank edge.
copy_from_vram:
    pushad
    push es
    mov ax, 0xa000
    mov es, ax
    mov bp, 10
.row:
    mov eax, [hud_work_addr]
    mov ebx, eax
    shr ebx, 16
    mov di, ax
    call select_bank
    mov cx, 48
.pixel:
    mov al, [es:di]
    mov [si], al
    inc si
    inc di
    jnz .same_bank
    inc bx
    call select_bank
.same_bank:
    loop .pixel
    add dword [hud_work_addr], SOURCE_W
    dec bp
    jnz .row
    pop es
    popad
    ret

copy_to_vram:
    pushad
    push es
    cld
    mov ax, 0xa000
    mov es, ax
    mov bp, 10
.row:
    mov eax, [hud_work_addr]
    mov ebx, eax
    shr ebx, 16
    mov di, ax
    call select_bank
    mov cx, 48
.pixel:
    lodsb
    mov [es:di], al
    inc di
    jnz .same_bank
    inc bx
    call select_bank
.same_bank:
    loop .pixel
    add dword [hud_work_addr], SOURCE_W
    dec bp
    jnz .row
    pop es
    popad
    ret

render_hud:
    pushad
    push es
    push ds
    pop es
    cld
    mov di, hud_canvas
    mov cx, 48 * 10
    xor al, al
    rep stosb
    mov al, [hud_fps]
    xor ah, ah
    mov bl, 10
    div bl
    add al, 4
    mov [hud_text+4], al
    mov al, ah
    add al, 4
    mov [hud_text+5], al
    mov word [hud_char_base], hud_canvas + 49
    xor bx, bx
.char:
    mov al, [hud_text+bx]
    mov cl, 7
    mul cl
    mov si, hud_glyphs
    add si, ax
    mov di, [hud_char_base]
    mov bp, 7
.row:
    mov dl, [si]
    mov cx, 5
.bit:
    test dl, 0x10
    jz .skip
    mov byte [di], 0xff
.skip:
    shl dl, 1
    inc di
    loop .bit
    inc si
    add di, 43
    dec bp
    jnz .row
    add word [hud_char_base], 6
    inc bx
    cmp bx, 6
    jb .char
    pop es
    popad
    ret
%endif

full_blit:
    call wait_cp
    jc .failed
    mov word [es:0x70], 0
    mov word [es:0x72], 0
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov dword [es:0x7c], BLT_OP
    call wait_cp
.failed:
    ret

; A small guest-written marker establishes that DOS reached a completed BLT.
; Visual correctness still requires an emulator screenshot or user inspection.
log_first_blit:
    mov ah, 0x3c
    xor cx, cx
    mov dx, log_name
    int 0x21
    jc .done
    mov bx, ax
    mov ah, 0x40
    mov cx, log_end-log_text
    mov dx, log_text
    int 0x21
    mov ah, 0x3e
    int 0x21
    mov ax, [cp_seg]
    mov es, ax
.done:
    ret

wait_cp:
    push cx
    push dx
    mov dx, 64
.outer:
    mov cx, 0xffff
.inner:
    cmp word [card_id], 0x8fda
    je .xga2
    test byte [es:0x11], 0x80
    jz .done
    jmp .retry
.xga2:
    test byte [es:0x09], 0x80
    jz .done
.retry:
    loop .inner
    dec dx
    jnz .outer
    pop dx
    pop cx
    stc
    ret
.done:
    pop dx
    pop cx
    clc
    ret

restore_mode:
    cmp byte [mode_active], 0
    je .done
    mov dx, [io_base]
    inc dx
    xor al, al
    out dx, al
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0xff64
    out dx, ax
    mov ax, 0x1550
    out dx, ax
    mov ax, 0x1450
    out dx, ax
    mov ax, 0x0051
    out dx, ax
    mov ax, 0x0454
    out dx, ax
    mov ax, 0x7f70
    out dx, ax
    mov ax, 0x202a
    out dx, ax
    mov dx, [io_base]
    mov al, 1
    out dx, al
    mov dx, 0x3c3
    out dx, al
    mov ax, 0x1202
    mov bl, 0x30
    int 0x10
    xor ah, ah
    mov al, [old_mode]
    int 0x10
.done:
    ret

old_mode db 3
mode_active db 0
pos_base dw 0
card_id dw 0
pos1 db 0
pos3 db 0
pos4 db 0
io_base dw 0
cp_seg dw 0
aperture dd 0
cp_aperture dd 0
row dw 0
col dw 0
pan_x dw 0
pan_y dw 0
step_x dw 1
step_y dw 1
last_tick dw 0
%if PAN_STYLE = 1
hud_second db 0xff
hud_frames db 0
hud_fps db 0
hud_active db 0
hud_old_addr dd 0
hud_work_addr dd 0
hud_char_base dw 0
hud_text db 0, 1, 2, 3, 4, 4      ; FPS:00
; Five-bit rows for F, P, S, colon, and digits 0..9.
hud_glyphs:
    db 0x1f,0x10,0x10,0x1e,0x10,0x10,0x10
    db 0x1e,0x11,0x11,0x1e,0x10,0x10,0x10
    db 0x0f,0x10,0x10,0x0e,0x01,0x01,0x1e
    db 0x00,0x04,0x04,0x00,0x04,0x04,0x00
    db 0x0e,0x11,0x13,0x15,0x19,0x11,0x0e
    db 0x04,0x0c,0x04,0x04,0x04,0x04,0x0e
    db 0x0e,0x11,0x01,0x02,0x04,0x08,0x1f
    db 0x1e,0x01,0x01,0x0e,0x01,0x01,0x1e
    db 0x02,0x06,0x0a,0x12,0x1f,0x02,0x02
    db 0x1f,0x10,0x10,0x1e,0x01,0x01,0x1e
    db 0x0e,0x10,0x10,0x1e,0x11,0x11,0x0e
    db 0x1f,0x01,0x02,0x04,0x08,0x08,0x08
    db 0x0e,0x11,0x11,0x0e,0x11,0x11,0x0e
    db 0x0e,0x11,0x11,0x0f,0x01,0x01,0x0e
hud_saved times 48 * 10 db 0
hud_canvas times 48 * 10 db 0
%endif
msg_start db 'XGA Panorama Flight', 13, 10, '$'
msg_no_xga db 'XGA-1/XGA-2 not found on MCA.', 13, 10, '$'
msg_no_aperture db 'No XGA 1 MB or 4 MB aperture in POS.', 13, 10, '$'
msg_no_vram db 'Panorama needs 1 MB XGA VRAM.', 13, 10, '$'
msg_cp_timeout db 'XGA coprocessor timeout.', 13, 10, '$'
log_name db 'XGAOK.TXT', 0
log_boot_name db 'XGABOOT.TXT', 0
log_detect_name db 'XGADET.TXT', 0
log_mode_name db 'XGAMODE.TXT', 0
log_xga_error db 'NOXGA.TXT', 0
log_ap_error db 'NOAPER.TXT', 0
log_vram_error db 'NOVRAM.TXT', 0
log_cp_error db 'NOCP.TXT', 0
log_text db 'XGA mode, maps, and first BLT command completed.', 13, 10
log_end:

%include "xga_mode_640.inc"
