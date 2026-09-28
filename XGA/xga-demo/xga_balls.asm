; XGA Balls: orbit, sine snake and adjustable BitBLT stress test.
; By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
; Build: python make_balls_assets.py
;        nasm -f bin xga_balls.asm -o bin/v2/XBALLS.COM
cpu 386
bits 16
org 0x100

SCREEN_W equ 640
SCREEN_H equ 480
BALL_SIZE equ 48
BALL_BASE equ SCREEN_W * SCREEN_H
MASK_BASE equ BALL_BASE + BALL_SIZE * BALL_SIZE
BLT_B_TO_A equ 0xA8218000
BLT_MASKED equ 0xA8213000       ; source B, pattern C, destination A
SOLID_A equ 0x08118000

start:
    push cs
    pop ds
    mov ah, 0x0f
    int 0x10
    mov [old_mode], al
    mov dx, msg_start
    call puts
    call detect_xga
    jc .no_xga
    cmp dword [aperture], 0
    je .no_aperture
    call set_xga_mode
    mov byte [mode_active], 1
    call probe_vram
    jc .no_vram
    call set_palette
    call load_assets
    call setup_maps
    call setup_sprite_hud
.frame:
    call clear_screen
    jc .cp_timeout
    cmp byte [effect], 0
    jne .not_orbit
    call draw_orbit
    jmp .frame_done
.not_orbit:
    cmp byte [effect], 1
    jne .stress
    call draw_snake
    jmp .frame_done
.stress:
    call draw_stress
.frame_done:
    jc .cp_timeout
    call wait_cp
    jc .cp_timeout
    cmp byte [vsync_enabled], 0
    je .no_sync
    call wait_vsync
.no_sync:
    call update_fps
    call update_sprite_hud
    mov ah, 1
    int 0x16
    jz .next
    xor ah, ah
    int 0x16
    cmp al, 27
    je .quit
    cmp al, '1'
    jne .key2
    mov byte [effect], 0
    mov word [visible_balls], 7
    call reset_fps
    jmp .next
.key2:
    cmp al, '2'
    jne .key3
    mov byte [effect], 1
    mov word [visible_balls], 13
    call reset_fps
    jmp .next
.key3:
    cmp al, '3'
    jne .key_plus
    mov byte [effect], 2
    mov ax, [stress_count]
    mov [visible_balls], ax
    mov byte [mask_enabled], 1
    call reset_fps
    jmp .next
.key_plus:
    cmp al, '+'
    je .increase
    cmp al, '='
    jne .key_minus
.increase:
    cmp byte [effect], 2
    jne .next
    cmp word [stress_count], 2048
    jae .next
    shl word [stress_count], 1
    mov ax, [stress_count]
    mov [visible_balls], ax
    call reset_fps
    jmp .next
.key_minus:
    cmp al, '-'
    jne .key_space
    cmp byte [effect], 2
    jne .next
    cmp word [stress_count], 16
    jbe .next
    shr word [stress_count], 1
    mov ax, [stress_count]
    mov [visible_balls], ax
    call reset_fps
    jmp .next
.key_space:
    cmp al, ' '
    jne .key_v
    inc byte [effect]
    cmp byte [effect], 3
    jb .space_ready
    mov byte [effect], 0
.space_ready:
    cmp byte [effect], 0
    jne .space_not_orbit
    mov word [visible_balls], 7
    jmp .space_done
.space_not_orbit:
    cmp byte [effect], 1
    jne .space_stress
    mov word [visible_balls], 13
    jmp .space_done
.space_stress:
    mov ax, [stress_count]
    mov [visible_balls], ax
    mov byte [mask_enabled], 1
.space_done:
    call reset_fps
    jmp .next
.key_v:
    cmp al, 'v'
    je .toggle_vsync
    cmp al, 'V'
    jne .key_g
.toggle_vsync:
    xor byte [vsync_enabled], 1
    call reset_fps
    jmp .next
.key_g:
    cmp al, 'g'
    je .toggle_background
    cmp al, 'G'
    jne .key_t
.toggle_background:
    xor byte [background_mode], 1
    call reset_fps
    jmp .next
.key_t:
    cmp al, 't'
    je .toggle_mask
    cmp al, 'T'
    jne .next
.toggle_mask:
    xor byte [mask_enabled], 1
    call reset_fps
.next:
    add byte [phase], 2
    jmp .frame
.quit:
    call restore_mode
    mov ax, 0x4c00
    int 0x21
.cp_timeout:
    call restore_mode
    mov dx, msg_cp_timeout
    jmp .error
.no_vram:
    call restore_mode
    mov dx, msg_no_vram
    jmp .error
.no_aperture:
    mov dx, msg_no_aperture
    jmp .error
.no_xga:
    mov dx, msg_no_xga
.error:
    call puts
    mov ax, 0x4c01
    int 0x21

puts:
    mov ah, 9
    int 0x21
    ret

; Configure ball colors 0..15 and dark background colors 16..31.
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
    mov si, ball_palette
    mov cx, 96
.color:
    lodsb
    out dx, al
    loop .color
    dec dx
    mov ax, 0xff64
    out dx, ax
    ret

; Both assets fit in bank 4 directly after the 307,200-byte display map.
load_assets:
    mov ax, 0xa000
    mov es, ax
    mov bx, 4
    call select_bank
    mov di, 0xb000
    mov si, ball_pixels
    mov cx, BALL_SIZE * BALL_SIZE / 2
    cld
    rep movsw
    mov si, ball_mask
    mov cx, BALL_SIZE * BALL_SIZE / 16
    rep movsw
    ret

setup_maps:
    mov ax, [cp_seg]
    mov es, ax
    mov byte [es:0x11], 0
    mov byte [es:0x12], 1        ; display map A
    mov eax, [cp_aperture]
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 3
    mov byte [es:0x12], 2        ; ball bitmap map B
    add eax, BALL_BASE
    mov [es:0x14], eax
    mov word [es:0x18], BALL_SIZE-1
    mov word [es:0x1a], BALL_SIZE-1
    mov byte [es:0x1c], 3
    mov byte [es:0x12], 3        ; one-bit pattern map C
    mov eax, [cp_aperture]
    add eax, MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], BALL_SIZE-1
    mov word [es:0x1a], BALL_SIZE-1
    mov byte [es:0x1c], 0       ; Intel order, one bit per pixel
    mov byte [es:0x48], 3        ; pattern 1 copies source B
    mov byte [es:0x49], 5        ; pattern 0 preserves destination
    mov byte [es:0x4a], 4        ; destination color compare disabled
    mov dword [es:0x50], 0xff
    mov dword [es:0x54], 0xff
    mov dword [es:0x58], 0       ; fill color
    mov dword [es:0x5c], 0
    mov word [es:0x70], 0
    mov word [es:0x72], 0
    mov word [es:0x74], 0
    mov word [es:0x76], 0
    ret

clear_screen:
    call wait_cp
    jc .done
    cmp byte [background_mode], 0
    jne .gradient
    mov dword [es:0x58], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    jc .done
    jmp .size_ready
.gradient:
    xor si, si
.band:
    movzx eax, si
    add eax, 16
    mov [es:0x58], eax
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], 29
    mov word [es:0x78], 0
    mov ax, si
    imul ax, 30
    mov [es:0x7a], ax
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    jc .done
    inc si
    cmp si, 16
    jb .band
.size_ready:
    mov word [es:0x60], BALL_SIZE-1
    mov word [es:0x62], BALL_SIZE-1
.done:
    ret

; AX = left, DX = top. Pattern C selects source copy or destination keep.
draw_ball:
    push ax
    push dx
    call wait_cp
    jc .done
    pop dx
    pop ax
    mov [es:0x78], ax
    mov [es:0x7a], dx
    mov eax, BLT_B_TO_A
    cmp byte [mask_enabled], 0
    je .opaque
    mov eax, BLT_MASKED
.opaque:
    mov [es:0x7c], eax
    clc
    ret
.done:
    pop dx
    pop ax
    stc
    ret

; Seven balls: a fixed center and six satellites on an elliptical orbit.
draw_orbit:
    mov ax, 296
    mov dx, 216
    call draw_ball
    jc .done
    xor si, si
.satellite:
    mov al, [phase]
    add al, [orbit_offsets+si]
    mov bl, al
    xor bh, bh
    movsx ax, byte [sine_table+bx+64]
    imul ax, 180
    sar ax, 7
    add ax, 296
    mov [ball_x], ax
    mov al, [phase]
    add al, [orbit_offsets+si]
    mov bl, al
    xor bh, bh
    movsx ax, byte [sine_table+bx]
    imul ax, 130
    sar ax, 7
    add ax, 216
    mov dx, ax
    mov ax, [ball_x]
    call draw_ball
    jc .done
    inc si
    cmp si, 6
    jb .satellite
.done:
    ret

; Thirteen 48x48 bitmaps, each at a different phase of the same sine wave.
draw_snake:
    xor si, si
.ball:
    mov al, [phase]
    sub al, [snake_offsets+si]
    mov bl, al
    xor bh, bh
    movsx ax, byte [sine_table+bx]
    imul ax, 105
    sar ax, 7
    add ax, 216
    mov dx, ax
    mov ax, si
    imul ax, 48
    add ax, 8
    call draw_ball
    jc .done
    inc si
    cmp si, 13
    jb .ball
.done:
    ret

; Up to 2048 copies per frame. The 16x16 grid repeats after 256 copies.
; One shared sine displacement keeps CPU coordinate work small.
draw_stress:
    mov al, [phase]
    xor ah, ah
    mov bx, ax
    movsx ax, byte [sine_table+bx+64]
    sar ax, 4
    add ax, 10
    mov [stress_x0], ax
    movsx ax, byte [sine_table+bx]
    sar ax, 4
    add ax, 10
    mov [stress_y0], ax
    xor si, si
    mov bp, [stress_y0]
.row:
    mov bx, [stress_x0]
    mov di, 16
.ball:
    mov ax, bx
    mov dx, bp
    call draw_ball
    jc .done
    inc si
    cmp si, [stress_count]
    jae .done
    add bx, 38
    dec di
    jnz .ball
    add bp, 27
    test si, 255
    jnz .row
    mov bp, [stress_y0]
    jmp .row
.done:
    ret

; Bounded retrace wait; an unavailable status bit cannot freeze the demo.
wait_vsync:
    push ax
    push cx
    push dx
    mov dx, 0x3da
    mov cx, 0xffff
.leave:
    in al, dx
    test al, 8
    jz .rise_start
    loop .leave
    jmp .done
.rise_start:
    mov cx, 0xffff
.rise:
    in al, dx
    test al, 8
    jnz .done
    loop .rise
.done:
    pop dx
    pop cx
    pop ax
    ret

%include "xga_balls_hud.inc"
%include "xga_balls_runtime.inc"

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
effect db 0
mask_enabled db 0               ; T selects masked pattern BitBLT
vsync_enabled db 1
background_mode db 0
phase db 0
ball_x dw 0
ball_y dw 0
stress_x0 dw 0
stress_y0 dw 0
stress_count dw 16
visible_balls dw 7
orbit_offsets db 0,43,85,128,171,213
snake_offsets db 0,14,28,42,56,70,84,98,112,126,140,154,168
ball_palette:
    db 0,0,0, 24,8,24, 44,12,48, 68,16,72
    db 88,20,96, 112,28,116, 136,40,140, 160,56,164
    db 184,76,180, 204,100,196, 220,128,208, 232,156,220
    db 240,184,232, 248,208,240, 252,232,248, 255,255,255
    db 6,8,24, 8,11,28, 10,14,32, 12,17,36
    db 14,20,40, 16,23,44, 18,26,48, 20,29,52
    db 22,32,56, 24,35,60, 26,38,64, 28,41,68
    db 30,44,72, 32,47,76, 34,50,80, 36,53,84
ball_pixels: incbin "assets/xga_ball48.bin"
ball_mask: incbin "assets/xga_ball48_mask.bin"
%include "xga_balls_sine.inc"
msg_start db 'XGA Balls: 1 orbit, 2 snake, 3 stress, +/- count, V sync, G bg, T mask, Esc',13,10,'$'
msg_no_xga db 'XGA-1/XGA-2 not found on MCA.',13,10,'$'
msg_no_aperture db 'No XGA memory aperture in POS.',13,10,'$'
msg_no_vram db 'XGA Balls needs 1 MB VRAM.',13,10,'$'
msg_cp_timeout db 'XGA coprocessor timeout.',13,10,'$'
%include "xga_mode_640.inc"
