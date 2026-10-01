; Dreams XGA panorama and throughput comparison - IBM PS/2 MCA XGA-1.
; Build: python prepare_dreams.py, then NASM with PAN_STYLE 1/0/2.
; TEST_MODE=1/2 retain the original gradient and small BitBLT diagnostics.
; Register/mode sources: XGAKIT.ASM, MINI/XGA.INC, NT xgaregs.h/xga.h.

cpu 386
bits 16
org 0x100

%ifndef TEST_MODE
%define TEST_MODE 3
%endif
%ifndef PAN_STYLE
%define PAN_STYLE 1                 ; 1 = scanout, 0 = BitBLT, 2 = CPU copy
%endif

SCREEN_W equ 640
SCREEN_H equ 480
SOURCE_W equ 960
SOURCE_H equ 640
SOURCE_BASE equ SCREEN_W * SCREEN_H       ; 0x4b000
SOURCE_PAGES equ SOURCE_W * SOURCE_H / 4096
PAN_MAX_X equ SOURCE_W - SCREEN_W
PAN_MAX_Y equ SOURCE_H - SCREEN_H
PAN_X_AMPLITUDE equ 96
PAN_Y_AMPLITUDE equ 48
BLT_OP equ 0xA8218000                    ; source map B -> dest A, SRC_COPY
%if TEST_MODE = 3
%include "dreams_asset.inc"
PROGRESS_BASE equ 236 * SCREEN_W + 168 - 2 * 65536
%else
PROGRESS_COLOR equ 255
%endif

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
%if TEST_MODE != 1 && TEST_MODE != 3
    call probe_vram
    jc .no_vram
%endif
    call set_palette
%if TEST_MODE = 1
    call fill_screen
    jmp .wait_key
%else
%if TEST_MODE = 3
    call check_image_cache
    jnc .image_ready
    call probe_vram
    jc .no_vram
    call progress_init
    call open_image
    jc .image_error
    call load_image
    jc .image_error
    call mark_image_cache
.image_ready:
%else
    call fill_source
%endif
    call init_motion
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
%if PAN_STYLE = 2
    call cpu_blit
%else
    call full_blit
    jc .cp_timeout
    call log_first_blit
%endif
%if PAN_STYLE = 1
    call configure_scanout
%endif
    call setup_sprite_hud
.frame:
%if PAN_STYLE = 0
    ; The previous iteration waited for completion after its BitBLT.
    cmp byte [vsync_enabled], 0
    je .copy_now
    call wait_vsync
    jc .sync_failed
    call advance_motion             ; one sine step per observed refresh
    jmp .copy_now
.sync_failed:
    mov byte [vsync_enabled], 0    ; status bit did not toggle
    mov word [hud_last_fps], 0xffff
    call update_sprite_hud
.copy_now:
    mov ax, [pan_x]
    mov [es:0x70], ax
    mov ax, [pan_y]
    mov [es:0x72], ax
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov dword [es:0x7c], BLT_OP
    call wait_cp
    jc .cp_timeout
    call update_fps
%elif PAN_STYLE = 2
    call cpu_blit
    call update_fps
%else
    call set_view
    call update_fps
    call refresh_source_pages
%endif
%if PAN_STYLE != 2
    inc byte [key_poll_div]
    test byte [key_poll_div], 7     ; BIOS keyboard call every eighth fast frame
    jnz .animate
%endif
    mov ah, 1
    int 0x16
    jz .animate
    xor ah, ah
    int 0x16
    cmp al, 27
    je .wait_key
%if PAN_STYLE = 0
    cmp al, 's'
    je .toggle_sync
    cmp al, 'S'
    jne .animate
.toggle_sync:
    xor byte [vsync_enabled], 1
    mov byte [fps_started], 0
    mov byte [fps_measured], 0
    mov word [hud_frames], 0
    mov word [hud_fps10], 0
    mov word [hud_last_fps], 0xffff
    mov word [motion_frame_count], 0
    mov word [motion_step_frames], 128
    call update_sprite_hud
%endif
.animate:
    call update_motion
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
.image_error:
    call restore_mode
    mov dx, msg_image_error
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
%if TEST_MODE = 3
open_image:
    mov ax, 0x3d00
    mov dx, image_name
    int 0x21
    jc .fail
    mov [image_handle], ax
    mov bx, ax
    mov ax, 0x4200                 ; palette is embedded in the COM
    xor cx, cx
    mov dx, 768
    int 0x21
    jc .close_fail
    clc
    ret
.close_fail:
    mov bx, [image_handle]
    mov ah, 0x3e
    int 0x21
.fail:
    stc
    ret

; Read up to 32 KB at a time, then copy aligned 4 KB pages to banked VRAM.
; This reduces DOS file reads from 150 to 19 without changing disk format.
load_image:
    mov word [load_bank], 4
    mov word [load_offset], 0xb000
    mov word [loaded_pages], 0
    mov bp, SOURCE_PAGES
.read_chunk:
    mov ax, bp
    cmp ax, 8
    jbe .chunk_size_ready
    mov ax, 8
.chunk_size_ready:
    mov [chunk_pages], ax
    shl ax, 12
    mov [chunk_bytes], ax
    mov bx, [image_handle]
    mov ah, 0x3f
    mov cx, [chunk_bytes]
    mov dx, image_page
    int 0x21
    jc .fail
    cmp ax, [chunk_bytes]
    jne .fail
    mov si, image_page
.page:
    mov ax, 0xa000
    mov es, ax
    mov bx, [load_bank]
    call select_bank
    mov di, [load_offset]
    mov cx, 2048
    cld
    rep movsw
    add word [load_offset], 4096
    jnz .next
    inc word [load_bank]
.next:
    inc word [loaded_pages]
    call progress_update
    dec bp
    dec word [chunk_pages]
    jnz .page
    or bp, bp
    jnz .read_chunk
    mov bx, [image_handle]
    mov ah, 0x3e
    int 0x21
    clc
    ret
.fail:
    mov bx, [image_handle]
    mov ah, 0x3e
    int 0x21
    stc
    ret

; Unused VRAM starts at 0xe1000. The marker is written only after a
; complete load, and identifies the exact quantized source image.
check_image_cache:
    mov ax, 0xa000
    mov es, ax
    mov bx, 14
    call select_bank
    cmp dword [es:0x2000], 0x42475844  ; "DXGB", loader/sprite revision
    jne .miss
    cmp dword [es:0x2004], IMAGE_CRC
    jne .miss
    cmp byte [es:0x0fff], IMAGE_LAST
    jne .miss
    mov bx, 9
    call select_bank
    cmp byte [es:0x6000], IMAGE_MIDDLE
    jne .miss
    mov bx, 4
    call select_bank
    cmp byte [es:0xb000], IMAGE_FIRST
    jne .miss
    clc
    ret
.miss:
    stc
    ret

mark_image_cache:
    mov ax, 0xa000
    mov es, ax
    mov bx, 14
    call select_bank
    mov dword [es:0x2000], 0x42475844
    mov dword [es:0x2004], IMAGE_CRC
    ret

; Draw a PC1-BMP-inspired loading indicator in the XGA framebuffer.
; The advancing strip represents 150 transferred 4 KB source pages.
progress_init:
    mov ax, 0xa000
    mov es, ax
    cld
    xor bx, bx
    mov bp, 4
    xor ax, ax
.bank:
    call select_bank
    xor di, di
    mov cx, 32768
    rep stosw
    inc bx
    dec bp
    jnz .bank
    call select_bank               ; bank 4, only display bytes
    xor di, di
    mov cx, (SCREEN_W * SCREEN_H - 4 * 65536) / 2
    rep stosw
    mov bx, 2
    call select_bank
    mov al, PROGRESS_COLOR
    mov di, PROGRESS_BASE
    mov cx, 304
    rep stosb
    mov di, PROGRESS_BASE + 11 * SCREEN_W
    mov cx, 304
    rep stosb
    mov di, PROGRESS_BASE + SCREEN_W
    mov cx, 10
.sides:
    mov [es:di], al
    mov [es:di+303], al
    add di, SCREEN_W
    loop .sides
    ret

progress_update:
    push ax
    push bx
    push cx
    push di
    push es
    mov ax, 0xa000
    mov es, ax
    mov bx, 2
    call select_bank
    mov ax, [loaded_pages]
    dec ax
    shl ax, 1
    add ax, PROGRESS_BASE + 2 * SCREEN_W + 2
    mov di, ax
    mov ax, PROGRESS_COLOR * 257
    mov cx, 8
.row:
    mov [es:di], ax
    add di, SCREEN_W
    loop .row
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret
%endif

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
%if TEST_MODE = 3
    mov si, image_palette
    mov cx, 768
.color:
    lodsb
    out dx, al
    loop .color
%else
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
%endif
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
; Scan the 960-pixel-wide source image directly. XGA display start is in
; dwords, and display pitch is expressed in units of eight pixels.
configure_scanout:
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0x7843                  ; 960 / 8 pixels per scan line
    out dx, ax
    mov ax, 0x0044
    out dx, ax
    call set_view
    ret

%endif

; XGA's 64x64 hardware sprite is independent of the scanned framebuffer.
; These register values and sprite-data writes reproduce DREAMS.COM from
; dreams_xga_20260926_193007.img, the version the user verified in 86Box.
setup_sprite_hud:
    pushad
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0x0830                  ; sprite X = 8
    out dx, ax
    mov ax, 0x0031
    out dx, ax
    mov ax, 0x0032                  ; X hotspot = 0
    out dx, ax
    mov ax, 0x0833                  ; sprite Y = 8
    out dx, ax
    mov ax, 0x0034
    out dx, ax
    mov ax, 0x0035                  ; Y hotspot = 0
    out dx, ax
    mov ax, 0x0038                  ; sprite color 0 = black
    out dx, ax
    mov ax, 0x0039
    out dx, ax
    mov ax, 0x003a
    out dx, ax
    mov ax, 0xff3b                  ; sprite color 1 = white
    out dx, ax
    mov ax, 0xff3c
    out dx, ax
    mov ax, 0xff3d
    out dx, ax
    mov ax, 0x0060                  ; sprite data position = 0
    out dx, ax
    mov ax, 0x0061
    out dx, ax
    mov al, 0x6a                  ; sprite data stream register
    out dx, al
    inc dx
    mov al, 0xaa                  ; four transparent 2-bit pixels
    mov cx, 1024
.clear:
    out dx, al
    loop .clear
    mov word [hud_last_fps], 0xffff
    call update_sprite_hud
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0x0136                  ; enable hardware sprite
    out dx, ax
    popad
    ret

update_sprite_hud:
    pushad
    mov ax, [hud_fps10]
    cmp ax, [hud_last_fps]
    je .done
    mov [hud_last_fps], ax
    call render_hud
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0x0060
    out dx, ax
    mov ax, 0x0061
    out dx, ax
    mov al, 0x6a
    out dx, al
    inc dx
    mov si, hud_canvas
    mov bp, 64 * 10 / 4
.group:
    mov al, 0xaa
    cmp byte [si], 0
    je .pixel1
    xor al, 0x03
.pixel1:
    cmp byte [si+1], 0
    je .pixel2
    xor al, 0x0c
.pixel2:
    cmp byte [si+2], 0
    je .pixel3
    xor al, 0x30
.pixel3:
    cmp byte [si+3], 0
    je .write
    xor al, 0xc0
.write:
    out dx, al
    add si, 4
    dec bp
    jnz .group
.done:
    popad
    ret

%if PAN_STYLE = 1
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
    mov bp, SOURCE_PAGES          ; pages 0x4b000 through 0xe0000
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
%endif

; Follow demo5a.asm's two-axis sine/Lissajous path. Fast unsynchronized modes
; divide their completed frames by the measured rate for about 60 motion steps
; per second. This never waits for retrace or throttles the BitBLT benchmark.
; S mode advances after its explicit retrace wait. Slow DCPU uses BIOS ticks.
init_motion:
    pushad
    push es
    xor ah, ah
    int 0x1a
    mov [motion_origin], dx
    mov [fps_now], dx
    mov byte [motion_phase], 0
    mov word [motion_frame_count], 0
    pop es
    popad
    call compute_motion
    ret

update_motion:
    pushad
%if PAN_STYLE = 2
    mov ax, [fps_now]
    sub ax, [motion_origin]
    mov bx, 3                       ; ~55 sine steps/s from 18.2 Hz ticks
    mul bx
    cmp al, [motion_phase]
    je .done
    mov [motion_phase], al
    call compute_motion
%else
%if PAN_STYLE = 0
    cmp byte [vsync_enabled], 0
    jne .done                       ; wait_vsync already advanced this frame
%endif
    inc word [motion_frame_count]
    mov ax, [motion_frame_count]
    cmp ax, [motion_step_frames]
    jb .done
    mov word [motion_frame_count], 0
    call advance_motion
%endif
.done:
    popad
    ret

advance_motion:
    inc byte [motion_phase]
    call compute_motion
    ret

compute_motion:
    pushad
    mov al, [motion_phase]
    movzx si, al
    mov al, [sine_table + si]
    sub al, 50
    cbw
    mov bx, PAN_X_AMPLITUDE
    imul bx
    mov bx, 50
    idiv bx
    add ax, PAN_MAX_X / 2
    mov [pan_x], ax

    mov al, [motion_phase]
    shl al, 1
    add al, 64                     ; quarter-cycle Y offset
    movzx si, al
    mov al, [sine_table + si]
    sub al, 50
    cbw
    mov bx, PAN_Y_AMPLITUDE
    imul bx
    mov bx, 50
    idiv bx
    add ax, PAN_MAX_Y / 2
    mov [pan_y], ax
    popad
    ret

%if PAN_STYLE = 0
; Start each BitBLT at a new vertical retrace when S mode is enabled.
; Input Status 1 bit 3 is also driven by 86Box's XGA scanout. Bounded
; polling keeps the demo responsive if a machine does not expose the bit.
wait_vsync:
    push ax
    push cx
    push dx
    mov dx, 0x3da
    mov cx, 0xffff
.leave_retrace:
    in al, dx
    test al, 8
    jz .wait_retrace
    loop .leave_retrace
    jmp .timeout
.wait_retrace:
    mov cx, 0xffff
.rise:
    in al, dx
    test al, 8
    jnz .synced
    loop .rise
.timeout:
    stc
    jmp .done
.synced:
    clc
.done:
    pop dx
    pop cx
    pop ax
    ret
%endif

; Count completed panorama steps over at least 36 BIOS clock ticks (~2 s).
; A slow frame can span several seconds; tick subtraction preserves that time.
; This measures the guest animation loop, not host-window presentation.
update_fps:
    pushad
    push fs
    mov ax, 0x40
    mov fs, ax
    mov eax, [fs:0x6c]            ; BIOS tick count, without INT 1Ah per frame
    pop fs
    mov [fps_now], eax
    cmp byte [fps_started], 0
    jne .elapsed
    mov [fps_start], eax
    mov byte [fps_started], 1
    jmp .done                      ; this completed frame precedes the timer
.elapsed:
    inc word [hud_frames]
    mov ebx, eax
    sub ebx, [fps_start]
    jnc .delta_ready
    add ebx, 0x1800b0             ; BIOS midnight rollover
.delta_ready:
%if PAN_STYLE != 2
    cmp byte [fps_measured], 0
    jne .normal_window
    cmp ebx, 9                     ; show the first reading sooner
    jb .done
    jmp .calculate
.normal_window:
%endif
    cmp ebx, 36
    jb .done
.calculate:
    movzx eax, word [hud_frames]
    mov ecx, 182                  ; 18.2 ticks/s * 10 for tenths
    mul ecx
    xor edx, edx
    div ebx
%if PAN_STYLE != 2
    mov [fps_raw10], eax
    add eax, 300
    mov ecx, 600                   ; frames per ~1/60 s motion step
    xor edx, edx
    div ecx
    test eax, eax
    jnz .step_nonzero
    inc eax
.step_nonzero:
    cmp eax, 0xffff
    jbe .step_ready
    mov eax, 0xffff
.step_ready:
    mov [motion_step_frames], ax
    mov eax, [fps_raw10]
%endif
%if PAN_STYLE = 0
    add eax, 5
    mov ecx, 10
    xor edx, edx
    div ecx                         ; DBLIT shows whole copies/s, up to 9999
%endif
    cmp eax, 9999
    jbe .store
.cap:
    mov ax, 9999
.store:
    mov [hud_fps10], ax
%if PAN_STYLE != 2
    mov byte [fps_measured], 1
%endif
    call update_sprite_hud
    mov eax, [fps_now]
    mov [fps_start], eax
    mov word [hud_frames], 0
.done:
    popad
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
%if PAN_STYLE = 1
    ; Legacy VRAM text path is retained so the verified 193007 DREAMS
    ; binary remains reproducible. The active FPS path is the sprite above.
    movzx eax, word [pan_y]
    add eax, 8
    imul eax, eax, SOURCE_W
    movzx ebx, word [pan_x]
    add eax, ebx
    add eax, SOURCE_BASE + 8
    mov [hud_old_addr], eax
    mov [hud_work_addr], eax
    mov word [hud_pitch], SOURCE_W
%else
    mov dword [hud_old_addr], 2 * SCREEN_W + 8
    mov eax, [hud_old_addr]
    mov [hud_work_addr], eax
    mov word [hud_pitch], SCREEN_W
%endif
    mov si, hud_saved
    call copy_from_vram
    call render_hud
    mov eax, [hud_old_addr]
    mov [hud_work_addr], eax
    mov si, hud_canvas
    call copy_to_vram
    mov byte [hud_active], 1
    ret

; Rectangle copy: 64 x 10 bytes at hud_work_addr.
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
    mov cx, 64
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
    movzx eax, word [hud_pitch]
    add [hud_work_addr], eax
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
    mov cx, 64
.pixel:
    lodsb
    mov [es:di], al
    inc di
    jnz .same_bank
    inc bx
    call select_bank
.same_bank:
    loop .pixel
    movzx eax, word [hud_pitch]
    add [hud_work_addr], eax
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
    mov cx, 64 * 10
    xor al, al
    rep stosb
    mov ax, [hud_fps10]
    mov bx, 10
%if PAN_STYLE = 0
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text+7], dl          ; ones
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text+6], dl          ; tens
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text+5], dl          ; hundreds
    add al, 4
    mov [hud_text+4], al          ; thousands
    mov byte [hud_text+8], 15     ; blank when running without VSYNC wait
    cmp byte [vsync_enabled], 0
    je .mode_ready
    mov byte [hud_text+8], 2      ; S marks synchronized BitBLT
.mode_ready:
%else
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text+8], dl          ; tenths
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text+6], dl          ; ones
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text+5], dl          ; tens
    add al, 4
    mov [hud_text+4], al          ; hundreds
%endif
    mov word [hud_char_base], hud_canvas + 65
    xor bx, bx
.char:
%if PAN_STYLE = 0
    cmp bx, 8
    jne .glyph
    add word [hud_char_base], 3    ; visible gap before the optional S
.glyph:
%endif
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
    mov byte [di], PROGRESS_COLOR
.skip:
    shl dl, 1
    inc di
    loop .bit
    inc si
    add di, 59
    dec bp
    jnz .row
    add word [hud_char_base], 6
    inc bx
%if PAN_STYLE = 0
    cmp bx, 9
%else
    cmp bx, 9
%endif
    jb .char
    pop es
    popad
    ret

%if PAN_STYLE = 2
; CPU-only comparison: read each 640-byte row through the banked A000
; window into conventional RAM, switch banks, then write the display row.
cpu_blit:
    pushad
    push es
    movzx eax, word [pan_y]
    imul eax, eax, SOURCE_W
    movzx ebx, word [pan_x]
    add eax, ebx
    add eax, SOURCE_BASE
    mov [cpu_src_addr], eax
    mov dword [cpu_dst_addr], 0
    mov bp, SCREEN_H
.row:
    mov ax, 0xa000
    mov es, ax
    mov eax, [cpu_src_addr]
    mov ebx, eax
    shr ebx, 16
    mov di, ax
    call select_bank
    mov si, image_page
    mov cx, SCREEN_W
.read:
    mov al, [es:di]
    mov [si], al
    inc si
    inc di
    jnz .read_same_bank
    inc bx
    call select_bank
.read_same_bank:
    loop .read

    mov eax, [cpu_dst_addr]
    mov ebx, eax
    shr ebx, 16
    mov di, ax
    call select_bank
    mov si, image_page
    mov cx, SCREEN_W
    cld
.write:
    lodsb
    mov [es:di], al
    inc di
    jnz .write_same_bank
    inc bx
    call select_bank
.write_same_bank:
    loop .write
    add dword [cpu_src_addr], SOURCE_W
    add dword [cpu_dst_addr], SCREEN_W
    dec bp
    jnz .row
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
    add dx, 0x0a
    mov ax, 0x0036                  ; disable hardware sprite
    out dx, ax
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
motion_origin dw 0
motion_phase db 0
motion_frame_count dw 0
motion_step_frames dw 128
%if PAN_STYLE != 2
fps_raw10 dd 0
%endif
key_poll_div db 0
%if PAN_STYLE = 0
vsync_enabled db 0
%endif
%if PAN_STYLE != 2
fps_measured db 0
%endif
hud_last_fps dw 0xffff
fps_started db 0
fps_start dd 0
fps_now dd 0
hud_frames dw 0
hud_fps10 dw 0
hud_active db 0
hud_old_addr dd 0
hud_work_addr dd 0
hud_pitch dw SOURCE_W
hud_char_base dw 0
%if PAN_STYLE = 0
hud_text db 0, 1, 2, 3, 4, 4, 4, 4, 15 ; FPS:0000 [S]
%else
hud_text db 0, 1, 2, 3, 4, 4, 4, 14, 4 ; FPS:000.0
%endif
; Five-bit rows for F, P, S, colon, digits 0..9, and dot.
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
    db 0x00,0x00,0x00,0x00,0x00,0x04,0x04
%if PAN_STYLE = 0
    times 7 db 0                      ; blank glyph 15
%endif
; Exact 256-step, 0..100 sine curve from PC1-Labs demo5a.asm.
sine_table:
    db 50, 51, 52, 53, 55, 56, 57, 58, 59, 61, 62, 63, 64, 65, 66, 68
    db 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84
    db 84, 85, 86, 87, 87, 88, 89, 89, 90, 90, 91, 91, 92, 92, 93, 93
    db 94, 94, 94, 95, 95, 95, 96, 96, 96, 96, 97, 97, 97, 97, 97, 97
    db 97, 97, 97, 97, 97, 97, 97, 97, 96, 96, 96, 96, 95, 95, 95, 94
    db 94, 94, 93, 93, 92, 92, 91, 91, 90, 90, 89, 89, 88, 87, 87, 86
    db 85, 84, 84, 83, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 72, 71
    db 70, 69, 68, 66, 65, 64, 63, 62, 61, 59, 58, 57, 56, 55, 53, 52
    db 50, 49, 48, 47, 45, 44, 43, 42, 41, 39, 38, 37, 36, 35, 34, 32
    db 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16
    db 16, 15, 14, 13, 13, 12, 11, 11, 10, 10,  9,  9,  8,  8,  7,  7
    db  6,  6,  6,  5,  5,  5,  4,  4,  4,  4,  3,  3,  3,  3,  3,  3
    db  3,  3,  3,  3,  3,  3,  3,  3,  4,  4,  4,  4,  5,  5,  5,  6
    db  6,  6,  7,  7,  8,  8,  9,  9, 10, 10, 11, 11, 12, 13, 13, 14
    db 15, 16, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29
    db 30, 31, 32, 34, 35, 36, 37, 38, 39, 41, 42, 43, 44, 45, 47, 48
hud_saved times 64 * 10 db 0
hud_canvas times 64 * 10 db 0
%if TEST_MODE = 3
image_name db 'DREAMS.DAT', 0
image_handle dw 0
load_bank dw 4
load_offset dw 0xb000
loaded_pages dw 0
chunk_pages dw 0
chunk_bytes dw 0
image_palette incbin "bin/DREAMS.DAT", 0, 768
align 2
image_page times 32768 db 0
%endif
%if PAN_STYLE = 2
cpu_src_addr dd 0
cpu_dst_addr dd 0
%endif
msg_start db 'Dreams XGA Flight', 13, 10, '$'
msg_no_xga db 'XGA-1/XGA-2 not found on MCA.', 13, 10, '$'
msg_no_aperture db 'No XGA 1 MB or 4 MB aperture in POS.', 13, 10, '$'
msg_no_vram db 'Panorama needs 1 MB XGA VRAM.', 13, 10, '$'
msg_image_error db 'DREAMS.DAT missing or incomplete.', 13, 10, '$'
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
