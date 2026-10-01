; XGADEMO: CGA artwork, two scrollers, music and XGA stars/raster via a back buffer.
; By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
; Build: python make_cgademo_assets.py
;        nasm -f bin xgademo.asm -o bin/v2/XGADEMO.COM
cpu 386
bits 16
org 0x100

SCREEN_W equ 640
SCREEN_H equ 480
PAGE_BYTES equ SCREEN_W * SCREEN_H
BACK_BASE equ PAGE_BYTES
LOGO_BASE equ PAGE_BYTES * 2
MASK_BASE equ PAGE_BYTES * 3
SOLID_A equ 0x08118000
COPY_B equ 0xA8218000
COPY_MASKED equ 0xA8213000
STAR_COUNT equ 64

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
    call load_mask
    jc .missing_mask
    call set_palette
    call setup_maps
    call render_logo
    jc .timeout
    call get_font
    call init_stars
    call render_footer
    jc .timeout
.frame:
    mov si, original_scroll_state
    call scroll_column
    jc .timeout
    mov si, xga_scroll_state
    call scroll_column
    jc .timeout
    call clear_frame
    jc .timeout
    call draw_stars
    jc .timeout
    call draw_raster
    jc .timeout
    call overlay_logo
    jc .timeout
    call wait_vsync
    call present_frame
    jc .timeout
    call do_music
    mov ah, 1
    int 0x16
    jz .advance
    xor ah, ah
    int 0x16
    cmp al, 27
    je .quit
.advance:
    jmp .frame
.quit:
    call silence
    call restore_mode
    mov ax, 0x4c00
    int 0x21
.timeout:
    mov dx, msg_timeout
    jmp .error
.missing_mask:
    mov dx, msg_mask
    jmp .error
.no_vram:
    mov dx, msg_vram
    jmp .error
.no_aperture:
    mov dx, msg_aperture
    jmp .error
.no_xga:
    mov dx, msg_xga
    call puts
    mov ax, 0x4c01
    int 0x21
.error:
    call silence
    call restore_mode
    call puts
    mov ax, 0x4c01
    int 0x21

puts:
    mov ah, 9
    int 0x21
    ret

load_mask:
    mov dx, mask_filename
    mov ax, 0x3d00
    int 0x21
    jc .fail
    mov [mask_handle], ax
    mov bx, 14
    call select_bank
    mov ax, 0xa000
    mov ds, ax
    mov bx, [cs:mask_handle]
    mov dx, MASK_BASE % 65536
    mov cx, 38400
    mov ah, 0x3f
    int 0x21
    pushf
    push ax
    push cs
    pop ds
    mov bx, [mask_handle]
    mov ah, 0x3e
    int 0x21
    pop ax
    popf
    jc .fail
    cmp ax, 38400
    jne .fail
    xor bx, bx
    call select_bank
    clc
    ret
.fail:
    stc
    ret

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
    mov si, palette
    mov cx, palette_end - palette
.color:
    lodsb
    out dx, al
    loop .color
    dec dx
    mov ax, 0xff64
    out dx, ax
    ret

setup_maps:
    mov ax, [cp_seg]
    mov es, ax
    mov byte [es:0x11], 0
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 3
    mov byte [es:0x12], 2
    add eax, LOGO_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 3
    mov byte [es:0x12], 3
    mov eax, [cp_aperture]
    add eax, MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 0
    mov byte [es:0x48], 3
    mov byte [es:0x49], 5
    mov byte [es:0x4a], 4
    mov dword [es:0x50], 0xff
    mov dword [es:0x54], 0xff
    mov dword [es:0x5c], 0
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, LOGO_BASE
    mov [es:0x14], eax
    ret

render_logo:
    mov dword [es:0x58], 0
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    jc .done
    mov si, logo_runs
.run:
    cmp si, logo_runs_end
    jae .done_ok
    movzx eax, byte [si]
    mov [es:0x58], eax
    mov ax, [si+1]
    mov [es:0x78], ax
    mov ax, [si+3]
    mov [es:0x7a], ax
    mov ax, [si+5]
    dec ax
    mov [es:0x60], ax
    mov word [es:0x62], 1
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    jc .done
    add si, 7
    jmp .run
.done_ok:
    clc
.done:
    ret

get_font:
    mov ax, 0xf000
    mov fs, ax
    ret

render_footer:
    mov dword [es:0x58], 0
    mov word [es:0x78], 0
    mov word [es:0x7a], 420
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], 45
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    jc .done
    mov si, footer_text
    mov word [text_x], (SCREEN_W - (footer_text_end-footer_text-1)*10)/2
    mov word [text_y], 422
    mov byte [text_color], 11
    call draw_fixed_text
    jc .done
    mov si, ported_text
    mov word [text_x], (SCREEN_W - (ported_text_end-ported_text-1)*10)/2
    mov word [text_y], 448
    mov byte [text_color], 2
    call draw_fixed_text
.done:
    ret

draw_fixed_text:
.character:
    lodsb
    test al, al
    jz .complete
    movzx bx, al
    shl bx, 3
    add bx, 0xfa6e
    xor di, di
.row:
    mov ah, [fs:bx+di]
    mov dl, 0x80
    xor bp, bp
.pixel:
    test ah, dl
    jz .next_pixel
    push ax
    movzx eax, byte [text_color]
    mov [es:0x58], eax
    mov ax, [text_x]
    add ax, bp
    mov [es:0x78], ax
    mov ax, di
    shl ax, 1
    add ax, [text_y]
    mov [es:0x7a], ax
    mov word [es:0x60], 1
    mov word [es:0x62], 1
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    pop ax
    jc .done
.next_pixel:
    shr dl, 1
    inc bp
    cmp bp, 8
    jb .pixel
    inc di
    cmp di, 8
    jb .row
    add word [text_x], 10
    jmp .character
.complete:
    clc
.done:
    ret

scroll_column:
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, LOGO_BASE
    mov [es:0x14], eax
    mov word [es:0x70], 8
    mov ax, [si+4]
    mov [es:0x72], ax
    mov word [es:0x74], 0
    mov word [es:0x76], 0
    mov word [es:0x78], 0
    mov [es:0x7a], ax
    mov word [es:0x60], 631
    mov word [es:0x62], 27
    mov dword [es:0x7c], COPY_B
    call wait_cp
    jc .done
    mov dword [es:0x58], 0
    mov word [es:0x78], 632
    mov ax, [si+4]
    mov [es:0x7a], ax
    mov word [es:0x60], 7
    mov word [es:0x62], 27
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    jc .done
    mov bx, [si]
    add bx, [si+6]
    mov al, [bx]
    test al, al
    jnz .character
    mov word [si], 0
    mov bx, [si+6]
    mov al, [bx]
.character:
    movzx bx, al
    shl bx, 3
    add bx, 0xfa6e
    mov ax, [si+2]
    mov cl, al
    shl cl, 1
    mov ch, 0x80
    shr ch, cl
    xor di, di
.row:
    mov al, [fs:bx+di]
    test al, ch
    jz .second
    push ax
    mov bp, 632
    call draw_scroll_dot
    pop ax
    jc .done
.second:
    shr ch, 1
    test al, ch
    jz .next_row
    mov bp, 636
    call draw_scroll_dot
    jc .done
.next_row:
    shl ch, 1
    inc di
    cmp di, 7
    jb .row
    inc word [si+2]
    cmp word [si+2], 4
    jb .done_ok
    mov word [si+2], 0
    inc word [si]
.done_ok:
    clc
.done:
    ret

draw_scroll_dot:
    movzx eax, byte [si+8]
    mov [es:0x58], eax
    mov [es:0x78], bp
    mov ax, di
    shl ax, 2
    add ax, [si+4]
    mov [es:0x7a], ax
    mov word [es:0x60], 1
    mov word [es:0x62], 1
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    ret

clear_frame:
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
    mov dword [es:0x58], 0
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    ret

init_stars:
    mov di, stars
    mov cx, STAR_COUNT
    mov bp, 240
.star:
    call random_star
    mov [di+4], bp
    sub bp, 3
    add di, 6
    loop .star
    ret

random_star:
    call random_signed_byte
    mov [di], ax
    call random_signed_byte
    sar ax, 1
    mov [di+2], ax
    ret

random_signed_byte:
    mov ax, [star_seed]
    mov dx, 25173
    mul dx
    add ax, 13849
    mov [star_seed], ax
    mov al, ah
    cbw
    ret

draw_stars:
    mov di, stars
    mov cx, STAR_COUNT
.star:
    mov bp, [di+4]
    cmp bp, 45
    ja .advance
    call random_star
    mov bp, 240
    jmp .project
.advance:
    sub bp, 5
.project:
    mov [di+4], bp
    mov bx, 96
    mov ax, [di]
    imul bx
    idiv bp
    add ax, 320
    mov [star_x], ax
    mov ax, [di+2]
    imul bx
    idiv bp
    add ax, 240
    mov [star_y], ax
    cmp word [star_x], SCREEN_W
    jae .next
    cmp word [star_y], SCREEN_H
    jae .next
    mov eax, 15
    cmp bp, 120
    jae .color
    mov eax, 1
.color:
    mov [es:0x58], eax
    mov ax, [star_x]
    mov [es:0x78], ax
    mov ax, [star_y]
    mov [es:0x7a], ax
    mov word [es:0x60], 0
    mov word [es:0x62], 0
    cmp bp, 100
    jae .draw
    mov ax, [star_x]
    sub ax, 320
    jns .abs_x
    neg ax
.abs_x:
    mov bx, ax
    mov ax, [star_y]
    sub ax, 240
    jns .abs_y
    neg ax
.abs_y:
    cmp bx, ax
    jb .vertical
    cmp word [star_x], 320
    jbe .horizontal
    sub word [es:0x78], 4
.horizontal:
    mov word [es:0x60], 4
    jmp .draw
.vertical:
    cmp word [star_y], 240
    jbe .downward
    sub word [es:0x7a], 4
.downward:
    mov word [es:0x62], 4
.draw:
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    jc .done
.next:
    add di, 6
    dec cx
    jnz .star
    clc
.done:
    ret

draw_raster:
    mov si, [raster_pos]
    add word [raster_pos], 121
    cmp si, 251 * 121
    jb .start_bands
    mov word [raster_pos], 0
.start_bands:
    xor di, di
.band:
    movzx eax, byte [raster_frames+si]
    cmp al, 0x10
    je .next_band
    mov [es:0x58], eax
    mov word [es:0x78], 0
    mov ax, di
    shl ax, 1
    add ax, 40
    mov [es:0x7a], ax
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], 1
    mov dword [es:0x7c], SOLID_A
    call wait_cp
    jc .done
.next_band:
    inc si
    inc di
    cmp di, 121
    jb .band
    clc
.done:
    ret

overlay_logo:
    mov word [es:0x70], 0
    mov word [es:0x72], 0
    mov word [es:0x74], 0
    mov word [es:0x76], 0
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov dword [es:0x7c], COPY_MASKED
    call wait_cp
    ret

present_frame:
    call wait_cp
    jc .done
    mov byte [es:0x12], 2
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 3
    mov word [es:0x70], 0
    mov word [es:0x72], 0
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    mov [es:0x14], eax
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov dword [es:0x7c], COPY_B
    call wait_cp
    pushf
    mov byte [es:0x12], 2
    mov eax, [cp_aperture]
    add eax, LOGO_BASE
    mov [es:0x14], eax
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
    popf
.done:
    ret

wait_vsync:
    push ax
    push cx
    push dx
    mov dx, 0x3da
    mov cx, 0xffff
.leave:
    in al, dx
    test al, 8
    jz .rise
    loop .leave
.rise:
    mov cx, 0xffff
.poll:
    in al, dx
    test al, 8
    jnz .done
    loop .poll
.done:
    pop dx
    pop cx
    pop ax
    ret

do_music:
    dec byte [music_tick]
    jnz .done
    mov si, [music_pos]
    mov bx, [music+si]
    cmp bx, 0xffff
    jne .note
    xor si, si
    mov bx, [music]
.note:
    add si, 2
    mov [music_pos], si
    mov byte [music_tick], 2
    test bx, bx
    jz silence
    mov al, 0xb6
    out 0x43, al
    mov al, bl
    out 0x42, al
    mov al, bh
    out 0x42, al
    in al, 0x61
    or al, 3
    out 0x61, al
.done:
    ret

silence:
    in al, 0x61
    and al, 0xfc
    out 0x61, al
    ret

io_base dw 0
cp_seg dw 0
aperture dd 0
cp_aperture dd 0
old_mode db 3
mode_active db 0
pos_base dw 0
card_id dw 0
pos1 db 0
pos3 db 0
pos4 db 0
wait_pit_ticks dd 0
mask_handle dw 0
original_scroll_state dw 0,0,334,scroll_text
                      db 10
xga_scroll_state dw 0,0,380,xga_scroll_text
                 db 9
text_x dw 0
text_y dw 0
text_color db 0
music_pos dw 0
music_tick db 1
raster_pos dw 0
star_seed dw 0x1357
star_x dw 0
star_y dw 0
stars times STAR_COUNT*6 db 0
mask_filename db 'XGAMASK.DAT',0
palette:
    db 0,0,0, 245,245,255, 35,220,245, 255,130,235
    db 100,0,8, 255,22,12, 255,100,20, 255,245,235
    db 10,55,250, 25,230,255, 15,250,70, 255,235,25
    db 255,0,230, 255,130,20, 255,255,255, 120,120,120
    db 0,0,0, 0,0,170, 0,170,0, 0,170,170
    db 170,0,0, 170,0,170, 170,85,0, 170,170,170
    db 85,85,85, 85,85,255, 85,255,85, 85,255,255
    db 255,85,85, 255,245,250, 255,255,85, 255,255,255
palette_end:
msg_start db 'XGADEMO: CGA classic on the XGA coprocessor. Esc quits.',13,10,'$'
msg_xga db 'XGA-1/XGA-2 not found on MCA.',13,10,'$'
msg_aperture db 'No XGA memory aperture in POS.',13,10,'$'
msg_vram db 'XGA 1 MB VRAM banks are not accessible.',13,10,'$'
msg_mask db 'Cannot read XGAMASK.DAT (38400 bytes).',13,10,'$'
msg_timeout db 'XGA coprocessor timeout.',13,10,'$'
footer_text db 'ANOTHER FREEWARE BY THE CODEBLASTERS IN 1992!',0
footer_text_end:
ported_text db 'Ported to XGA by Retro Erik in 2026!',0
ported_text_end:

%include "xga_mode_640.inc"
%include "xga_balls_runtime.inc"
logo_runs: incbin "bin/v2/xgademo_logo.bin"
logo_runs_end:
scroll_text: incbin "bin/v2/xgademo_scroll.bin"
xga_scroll_text db "IN 1990 XGA BECAME IBM'S FIRST VGA-COMPATIBLE CARD WITH A 2D GRAPHICS COPROCESSOR. "
                db "THE EARLIER 8514/A ACCELERATED DRAWING, BUT XGA BROUGHT VGA AND A BLITTER TO ONE ADAPTER. "
                db "HERE THE XGA BLITTER USES SOLID FILLS FOR THE MOVING RASTER BARS. THE ORIGINAL CGA MUSIC AND SCROLLER PLAY ON. "
                db "THIS DEMO WAS PORTED 100% BY GPT6-SOL.     ",0
music: incbin "bin/v2/xgademo_music.bin"
raster_frames: incbin "bin/v2/xgademo_raster.bin"