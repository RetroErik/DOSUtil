; XGA Balls: orbit, sine snakes and adjustable BitBLT stress test.
; By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
; Build: python make_balls_assets.py
;        nasm -f bin xga_balls.asm -o bin/v2/XBALLS.COM
cpu 386
bits 16
org 0x100

SCREEN_W equ 640
SCREEN_H equ 480
SCREEN_BYTES equ SCREEN_W * SCREEN_H
BACK_BASE equ SCREEN_BYTES
BALL_SIZE equ 48
BALL_BASE equ 2 * SCREEN_BYTES
MASK_BASE equ BALL_BASE + BALL_SIZE * BALL_SIZE
SMALL_SIZE equ 24
SMALL_BASE equ MASK_BASE + BALL_SIZE * BALL_SIZE / 8
SMALL_MASK_BASE equ SMALL_BASE + SMALL_SIZE * SMALL_SIZE * 4
ORBIT_MASK_BASE equ SMALL_MASK_BASE + SMALL_SIZE * SMALL_SIZE / 8
ORBIT_MASK_BYTES equ (80*80+88*88+96*96+104*104+112*112+120*120+128*128+136*136+144*144+152*152+160*160+168*168+176*176+184*184)/8
FLAG_SIZE equ 16
FLAG_BASE equ 10 * 65536
FLAG_MASK_BASE equ FLAG_BASE + 3 * FLAG_SIZE * FLAG_SIZE
MORPH_MASK_BASE equ FLAG_MASK_BASE + FLAG_SIZE * FLAG_SIZE / 8
MORPH_COUNT equ 96
MORPH_STRIDE equ MORPH_COUNT * 3
FLAG_COUNT equ 33 * 24
BLT_B_TO_A equ 0xA8218000
BLT_MASKED equ 0xA8213000       ; source B, pattern C, destination A
SOLID_A equ 0x08118000
BLT_FLAT_MASKED equ 0x08113000 ; fixed foreground, pattern C, dest A

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
    jnc .vram_ready
    call set_xga_mode
    call probe_vram
    jc .no_vram
.vram_ready:
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
    jne .not_snake
    call draw_snake
    jmp .frame_done
.not_snake:
    cmp byte [effect], 3
    jne .not_dense
    call draw_dense_snakes
    jmp .frame_done
.not_dense:
    cmp byte [effect], 4
    jne .not_orbit3d
    call draw_orbit3d
    jmp .frame_done
.not_orbit3d:
    cmp byte [effect], 5
    jne .not_flag
    call draw_flag
    jmp .frame_done
.not_flag:
    cmp byte [effect], 6
    jne .stress
    call draw_morph
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
    cmp byte [effect], 4
    jb .presented
    call present_back_frame
    jc .cp_timeout
.presented:
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
    call leave_back_buffer
    mov byte [effect], 0
    mov word [visible_balls], 7
    call select_large_maps
    call reset_fps
    jmp .next
.key2:
    cmp al, '2'
    jne .key3
    call leave_back_buffer
    mov byte [effect], 1
    mov word [visible_balls], 13
    call select_large_maps
    call reset_fps
    jmp .next
.key3:
    cmp al, '3'
    jne .key_plus
    call leave_back_buffer
    mov byte [effect], 2
    mov ax, [stress_count]
    mov [visible_balls], ax
    mov byte [mask_enabled], 1
    call select_large_maps
    call reset_fps
    jmp .next
.key_plus:
    cmp al, '4'
    jne .key5
    call leave_back_buffer
    mov byte [effect], 3
    mov ax, [dense_count]
    mov [visible_balls], ax
    mov byte [mask_enabled], 1
    call select_small_maps
    call reset_fps
    jmp .next
.key5:
    cmp al, '5'
    jne .key6
    cmp byte [effect], 4
    je .orbit_selected
    mov byte [effect], 4
    call enter_back_buffer
.orbit_selected:
    movzx ax, byte [orbit_speed]
    mov [visible_balls], ax
    call reset_fps
    jmp .next
.key6:
    cmp al, '6'
    jne .key7
    mov byte [effect], 5
    mov word [visible_balls], FLAG_COUNT
    call enter_back_buffer
    call select_flag_maps
    call reset_fps
    jmp .next
.key7:
    cmp al, '7'
    jne .key_plus_check
    mov byte [effect], 6
    mov byte [morph_shape], 0
    mov byte [morph_tick], 0
    mov word [visible_balls], MORPH_COUNT
    call enter_back_buffer
    call select_morph_maps
    call reset_fps
    jmp .next
.key_plus_check:
    cmp al, '+'
    je .increase
    cmp al, '='
    jne .key_minus
.increase:
    cmp byte [effect], 4
    jne .not_orbit_increase
    cmp byte [orbit_speed], 6
    jae .next
    inc byte [orbit_speed]
    shl word [orbit_step], 1
    movzx ax, byte [orbit_speed]
    mov [visible_balls], ax
    call reset_fps
    jmp .next
.not_orbit_increase:
    cmp byte [effect], 3
    jne .stress_increase
    cmp word [dense_count], 256
    jae .next
    shl word [dense_count], 1
    mov ax, [dense_count]
    mov [visible_balls], ax
    call reset_fps
    jmp .next
.stress_increase:
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
    cmp byte [effect], 4
    jne .not_orbit_decrease
    cmp byte [orbit_speed], 1
    jbe .next
    dec byte [orbit_speed]
    shr word [orbit_step], 1
    movzx ax, byte [orbit_speed]
    mov [visible_balls], ax
    call reset_fps
    jmp .next
.not_orbit_decrease:
    cmp byte [effect], 3
    jne .stress_decrease
    cmp word [dense_count], 32
    jbe .next
    shr word [dense_count], 1
    mov ax, [dense_count]
    mov [visible_balls], ax
    call reset_fps
    jmp .next
.stress_decrease:
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
    cmp byte [effect], 7
    jb .space_ready
    mov byte [effect], 0
.space_ready:
    cmp byte [effect], 4
    jne .space_not_3d
    movzx ax, byte [orbit_speed]
    mov [visible_balls], ax
    call enter_back_buffer
    jmp .space_done
.space_not_3d:
    cmp byte [effect], 5
    jne .space_not_flag
    mov word [visible_balls], FLAG_COUNT
    call enter_back_buffer
    call select_flag_maps
    jmp .space_done
.space_not_flag:
    cmp byte [effect], 6
    jne .space_not_morph
    mov byte [morph_shape], 0
    mov byte [morph_tick], 0
    mov word [visible_balls], MORPH_COUNT
    call enter_back_buffer
    call select_morph_maps
    jmp .space_done
.space_not_morph:
    call leave_back_buffer
    cmp byte [effect], 3
    jne .space_large
    mov ax, [dense_count]
    mov [visible_balls], ax
    mov byte [mask_enabled], 1
    call select_small_maps
    jmp .space_done
.space_large:
    call select_large_maps
.space_original:
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
    cmp byte [effect], 4
    jne .not_orbit_step
    mov ax, [orbit_step]
    add [orbit_phase], ax
    and word [orbit_phase], 8191
    jmp .frame
.not_orbit_step:
    cmp byte [effect], 5
    jne .not_flag_step
    inc byte [flag_phase]
    jmp .frame
.not_flag_step:
    cmp byte [effect], 6
    jne .normal_step
    inc byte [morph_tick]
    cmp byte [morph_tick], 192
    jb .frame
    mov byte [morph_tick], 0
    inc byte [morph_shape]
    cmp byte [morph_shape], 5
    jb .frame
    mov byte [morph_shape], 0
    jmp .frame
.normal_step:
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
    mov cx, 408
.color:
    lodsb
    out dx, al
    loop .color
    dec dx
    mov ax, 0xff64
    out dx, ax
    ret

; Two 640x480 pages occupy banks 0..9; all art then fits in bank 9.
load_assets:
    mov ax, 0xa000
    mov es, ax
    mov bx, 9
    call select_bank
    mov di, 0x6000
    mov si, ball_pixels
    mov cx, BALL_SIZE * BALL_SIZE / 2
    cld
    rep movsw
    mov si, ball_mask
    mov cx, BALL_SIZE * BALL_SIZE / 16
    rep movsw
    mov si, small_pixels
    mov cx, SMALL_SIZE * SMALL_SIZE * 4 / 2
    rep movsw
    mov si, small_mask
    mov cx, SMALL_SIZE * SMALL_SIZE / 16
    rep movsw
    mov si, orbit_masks
    mov cx, ORBIT_MASK_BYTES / 2
    rep movsw
    mov bx, 10
    call select_bank
    xor di, di
    mov si, flag_pixels
    mov cx, 3 * FLAG_SIZE * FLAG_SIZE / 2
    rep movsw
    mov si, flag_mask
    mov cx, FLAG_SIZE * FLAG_SIZE / 16
    rep movsw
    mov si, morph_masks
    mov cx, 4 * 32 * 32 / 16
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

; Change the two VRAM source maps only when the effect changes.
select_large_maps:
    mov byte [active_ball_size], BALL_SIZE
    mov byte [es:0x12], 2
    mov eax, [cp_aperture]
    add eax, BALL_BASE
    mov [es:0x14], eax
    mov word [es:0x18], BALL_SIZE-1
    mov word [es:0x1a], BALL_SIZE-1
    mov byte [es:0x12], 3
    mov eax, [cp_aperture]
    add eax, MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], BALL_SIZE-1
    mov word [es:0x1a], BALL_SIZE-1
    mov word [es:0x72], 0
    mov word [es:0x76], 0
    ret

select_small_maps:
    mov byte [active_ball_size], SMALL_SIZE
    mov byte [es:0x12], 2
    mov eax, [cp_aperture]
    add eax, SMALL_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SMALL_SIZE-1
    mov word [es:0x1a], SMALL_SIZE*4-1
    mov byte [es:0x12], 3
    mov eax, [cp_aperture]
    add eax, SMALL_MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SMALL_SIZE-1
    mov word [es:0x1a], SMALL_SIZE-1
    mov word [es:0x72], 0
    mov word [es:0x76], 0
    ret

select_flag_maps:
    mov byte [active_ball_size], FLAG_SIZE
    mov byte [es:0x12], 2
    mov eax, [cp_aperture]
    add eax, FLAG_BASE
    mov [es:0x14], eax
    mov word [es:0x18], FLAG_SIZE-1
    mov word [es:0x1a], 3*FLAG_SIZE-1
    mov byte [es:0x12], 3
    mov eax, [cp_aperture]
    add eax, FLAG_MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], FLAG_SIZE-1
    mov word [es:0x1a], FLAG_SIZE-1
    mov word [es:0x70], 0
    mov word [es:0x76], 0
    ret

select_morph_maps:
    mov byte [es:0x12], 3
    mov eax, [cp_aperture]
    add eax, MORPH_MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], 31
    mov word [es:0x1a], 127
    mov word [es:0x74], 0
    ret

; Modes 5 through 7 draw in a hidden 640x480 page.
enter_back_buffer:
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
    ret

leave_back_buffer:
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    mov [es:0x14], eax
    ret

; One full-page VRAM-to-VRAM BitBLT presents the finished hidden frame.
; Keeping the scanout start at zero also avoids hardware/emulator offset
; granularity differences between XGA implementations.
present_back_frame:
    mov byte [es:0x12], 2
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov word [es:0x70], 0
    mov word [es:0x72], 0
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    mov [es:0x14], eax
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov dword [es:0x7c], BLT_B_TO_A
    call wait_cp
    jc .done
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
    cmp byte [effect], 5
    jne .not_flag
    call select_flag_maps
    jmp .success
.not_flag:
    cmp byte [effect], 6
    jne .success
    call select_morph_maps
.success:
    clc                     ; effect comparison must not signal CP timeout
.done:
    ret

clear_screen:
    call wait_cp
    jc .done
    cmp byte [background_mode], 0
    jne .gradient
    xor eax, eax
    cmp byte [effect], 4
    jb .solid_color
    mov eax, 103           ; teal backdrop for the flat 3D circles
.solid_color:
    mov [es:0x58], eax
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
    movzx ax, byte [active_ball_size]
    dec ax
    mov [es:0x60], ax
    mov [es:0x62], ax
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

; 32 balls per lane, 1/2/4/8 lanes. Smaller artwork keeps each wave legible.
draw_dense_snakes:
    mov ax, [dense_count]
    shr ax, 5
    mov [dense_lanes], ax
    cmp ax, 1
    jne .two
    mov word [dense_center], 240
    mov word [dense_step], 0
    mov word [dense_amp], 100
    jmp .configured
.two:
    cmp ax, 2
    jne .four
    mov word [dense_center], 120
    mov word [dense_step], 240
    mov word [dense_amp], 70
    jmp .configured
.four:
    cmp ax, 4
    jne .eight
    mov word [dense_center], 60
    mov word [dense_step], 120
    mov word [dense_amp], 31
    jmp .configured
.eight:
    mov word [dense_center], 30
    mov word [dense_step], 60
    mov word [dense_amp], 12
.configured:
    mov bp, [dense_center]
    xor di, di
.lane:
    mov ax, di
    and ax, 3
    imul ax, SMALL_SIZE
    mov [es:0x72], ax       ; source Y selects one of four color variants
    mov ax, di
    imul ax, 47
    add al, [phase]
    mov [dense_sample], al
    mov word [dense_x], 12
    xor si, si
.ball:
    movzx bx, byte [dense_sample]
    movsx ax, byte [sine_table+bx]
    imul ax, [dense_amp]
    sar ax, 7
    add ax, bp
    sub ax, SMALL_SIZE/2
    mov dx, ax
    mov ax, [dense_x]
    call draw_ball
    jc .done
    add word [dense_x], 19
    sub byte [dense_sample], 11
    inc si
    cmp si, 32
    jb .ball
    add bp, [dense_step]
    inc di
    cmp di, [dense_lanes]
    jb .lane
.done:
    ret

; A 33x24 matrix of 16x16 colored balls. The left edge stays nearly fixed;
; the sine wave's displacement grows toward the free end of the flag.
draw_flag:
    xor di, di
.column:
    mov ax, di
    imul ax, 7
    add al, [flag_phase]
    movzx bx, al
    movsx ax, byte [sine_table+bx]
    imul ax, di
    sar ax, 7
    mov [flag_wave_y], ax
    movsx ax, byte [sine_table+bx+64]
    imul ax, di
    sar ax, 8
    mov bx, di
    imul bx, 14
    add ax, bx
    add ax, 80
    mov [flag_x], ax
    mov si, di
    xor bp, bp
.row:
    movzx ax, byte [flag_colors+si]
    shl ax, 4
    mov [es:0x72], ax       ; red, white, blue source rows
    mov ax, bp
    imul ax, 14
    add ax, [flag_wave_y]
    add ax, 65
    mov dx, ax
    mov ax, [flag_x]
    call draw_flag_ball
    jc .done
    add si, 33
    inc bp
    cmp bp, 24
    jb .row
    inc di
    cmp di, 33
    jb .column
    clc
.done:
    ret

draw_flag_ball:
    call wait_cp
    jc .done
    mov [es:0x78], ax
    mov [es:0x7a], dx
    mov dword [es:0x7c], BLT_MASKED
    clc
.done:
    ret

; Each of 96 points moves toward its counterpart in the next figure.
; Four 32x32 pattern rows supply circle diameters of 8, 16, 24 and 32.
draw_morph:
    movzx ax, byte [morph_tick]
    cmp ax, 64
    jb .hold
    sub ax, 64
    shl ax, 1
    jmp .fraction_ready
.hold:
    xor ax, ax
.fraction_ready:
    mov [morph_fraction], ax
    movzx ax, byte [morph_shape]
    imul ax, MORPH_STRIDE
    add ax, morph_shapes
    mov si, ax
    add ax, MORPH_STRIDE
    cmp byte [morph_shape], 4
    jne .next_ready
    mov ax, morph_shapes
.next_ready:
    mov bp, ax
    xor di, di
.ball:
    call wait_cp
    jc .done
    mov eax, [si]
    mov ebx, [bp]
    and eax, 0xffffff
    and ebx, 0xffffff
    mov dx, ax
    and dx, 1023
    mov cx, bx
    and cx, 1023
    sub cx, dx
    movsx ecx, cx
    imul ecx, dword [morph_fraction]
    sar ecx, 8
    add dx, cx
    sub dx, 16
    mov [es:0x78], dx
    shr eax, 10
    shr ebx, 10
    mov dx, ax
    and dx, 511
    mov cx, bx
    and cx, 511
    sub cx, dx
    movsx ecx, cx
    imul ecx, dword [morph_fraction]
    sar ecx, 8
    add dx, cx
    sub dx, 16
    mov [es:0x7a], dx
    shr eax, 9
    shr ebx, 9
    mov cx, di
    imul cx, 37
    and cx, 252
    inc cx
    cmp cx, [morph_fraction]
    ja .source_style
    mov eax, ebx
.source_style:
    mov bx, ax
    and bx, 3
    shl bx, 5
    mov [es:0x76], bx
    shr ax, 2
    and ax, 7
    mov bx, ax
    movzx eax, byte [morph_color_table+bx]
    mov [es:0x58], eax
    mov word [es:0x60], 31
    mov word [es:0x62], 31
    mov dword [es:0x7c], BLT_FLAT_MASKED
    add si, 3
    add bp, 3
    inc di
    cmp di, MORPH_COUNT
    jb .ball
    clc
.done:
    ret

; Seven flat circles at projected, depth-sorted ±X/±Y/±Z positions.
; The pattern map uses a 10/16 Bayer coverage, which suggests transparency.
draw_orbit3d:
    mov ax, [orbit_phase]
    and ax, 15
    mov [orbit_fraction], ax
    mov bx, [orbit_phase]
    shr bx, 4
    inc bx
    and bx, 511
    imul bx, 28
    add bx, orbit3d_frames
    mov [orbit_next_ptr], bx
    mov bx, [orbit_phase]
    shr bx, 4
    imul bx, 28             ; seven packed records, four bytes each
    mov si, orbit3d_frames
    add si, bx
    mov di, 7
.circle:
    call wait_cp
    jc .done
    mov byte [es:0x12], 3
    movzx bx, byte [si+3]
    shr bx, 3
    movzx cx, byte [orbit_sizes+bx]
    shl bx, 1
    movzx eax, word [orbit_mask_offsets+bx]
    add eax, ORBIT_MASK_BASE
    add eax, [cp_aperture]
    mov [es:0x14], eax
    dec cx
    mov [es:0x18], cx
    mov [es:0x1a], cx
    mov [es:0x60], cx
    mov [es:0x62], cx
    mov word [es:0x74], 0
    mov word [es:0x76], 0
    movzx eax, byte [si+3]
    and eax, 7
    add eax, 96
    mov [es:0x58], eax
    ; Match each satellite by ID in the next depth-sorted frame, then
    ; interpolate its screen position using the four fractional bits.
    push di
    mov bx, [orbit_next_ptr]
    mov di, 7
    mov dl, [si+3]
    and dl, 7
.find_next:
    mov al, [bx+3]
    and al, 7
    cmp al, dl
    je .matched
    add bx, 4
    dec di
    jnz .find_next
.matched:
    pop di
    push edi
    mov eax, [bx]
    mov edi, [si]
    and eax, 0x3ffff
    and edi, 0x3ffff
    mov cx, [orbit_fraction]
    mov dx, ax
    and dx, 511
    mov bx, di
    and bx, 511
    sub dx, bx
    imul dx, cx
    sar dx, 4
    add dx, bx
    mov [es:0x78], dx
    shr eax, 9
    shr edi, 9
    and ax, 511
    and di, 511
    sub ax, di
    imul ax, cx
    sar ax, 4
    add ax, di
    mov [es:0x7a], ax
    pop edi
    mov dword [es:0x7c], BLT_FLAT_MASKED
    add si, 4
    dec di
    jnz .circle
    clc
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
    push bx
    push cx
    push dx
    call read_pit
    mov [vsync_wait_start], ax
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
    call read_pit
    mov bx, [vsync_wait_start]
    sub bx, ax
    shr bx, 1
    movzx ebx, bx
    add [wait_pit_ticks], ebx
    pop dx
    pop cx
    pop bx
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
orbit_phase dw 0                ; 9 table-index bits and 4 fractional bits
orbit_step dw 8                 ; S0004 = half a table step per frame
orbit_fraction dw 0
orbit_next_ptr dw 0
orbit_speed db 4
morph_shape db 0
morph_tick db 0
morph_fraction dd 0
morph_color_table db 128,129,130,131,132,133,134,135
flag_phase db 0
vsync_wait_start dw 0
flag_wave_y dw 0
flag_x dw 0
active_ball_size db BALL_SIZE
ball_x dw 0
ball_y dw 0
stress_x0 dw 0
stress_y0 dw 0
stress_count dw 16
visible_balls dw 7
dense_count dw 128
dense_lanes dw 4
dense_center dw 60
dense_step dw 120
dense_amp dw 31
dense_x dw 0
dense_sample db 0
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
%include "xga_dense_palette.inc"
%include "xga_orbit_palette.inc"
%include "xga_flag_palette.inc"
%include "xga_morph_palette.inc"
ball_pixels: incbin "assets/xga_ball48.bin"
ball_mask: incbin "assets/xga_ball48_mask.bin"
small_pixels: incbin "assets/xga_ball24x4.bin"
small_mask: incbin "assets/xga_ball24_mask.bin"
orbit_masks: incbin "assets/xga_orbit_masks.bin"
flag_pixels: incbin "assets/xga_flag_balls.bin"
flag_mask: incbin "assets/xga_flag_mask.bin"
morph_masks: incbin "assets/xga_morph_masks.bin"
%include "xga_balls_sine.inc"
%include "xga_orbit3d_frames.inc"
%include "xga_flag_colors.inc"
%include "xga_morph_shapes.inc"
msg_start db 'XGA Balls: 1 orbit, 2 snake, 3 stress, 4 dense, 5 3D, 6 flag, 7 morph, +/- count/speed, V, G, T, Esc',13,10,'$'
msg_no_xga db 'XGA-1/XGA-2 not found on MCA.',13,10,'$'
msg_no_aperture db 'No XGA memory aperture in POS.',13,10,'$'
msg_no_vram db 'XGA 1 MB VRAM banks are not accessible.',13,10,'$'
msg_cp_timeout db 'XGA coprocessor timeout.',13,10,'$'
%include "xga_mode_640.inc"
