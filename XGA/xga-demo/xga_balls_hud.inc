; XGA 64x64 hardware sprite HUD with frame and wait timing.
; By Dag Erik Hagesæter / Retro Erik using Codex in VS Code

setup_sprite_hud:
    pushad
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0x0830                 ; sprite X = 8
    out dx, ax
    mov ax, 0x0031
    out dx, ax
    mov ax, 0x0032
    out dx, ax
    mov ax, 0x0833                 ; sprite Y = 8
    out dx, ax
    mov ax, 0x0034
    out dx, ax
    mov ax, 0x0035
    out dx, ax
    mov ax, 0x0038                 ; color 0 = black
    out dx, ax
    mov ax, 0x0039
    out dx, ax
    mov ax, 0x003a
    out dx, ax
    mov ax, 0xff3b                 ; color 1 = white
    out dx, ax
    mov ax, 0xff3c
    out dx, ax
    mov ax, 0xff3d
    out dx, ax
    mov ax, 0x0060                 ; sprite data offset 0
    out dx, ax
    mov ax, 0x0061
    out dx, ax
    mov al, 0x6a
    out dx, al
    inc dx
    mov al, 0xaa                   ; four transparent pixels
    mov cx, 1024
.clear:
    out dx, al
    loop .clear
    call update_sprite_hud
    mov dx, [io_base]
    add dx, 0x0a
    mov ax, 0x0136                 ; enable sprite
    out dx, ax
    popad
    ret

update_sprite_hud:
    pushad
    mov ax, [hud_fps10]
    cmp ax, [hud_last_fps]
    jne .changed
    mov ax, [visible_balls]
    cmp ax, [hud_last_balls]
    jne .changed
    mov ax, [hud_cpu_ms10]
    cmp ax, [hud_last_cpu]
    jne .changed
    mov ax, [hud_wait_ms10]
    cmp ax, [hud_last_wait]
    je .done
.changed:
    mov ax, [hud_fps10]
    mov [hud_last_fps], ax
    mov ax, [visible_balls]
    mov [hud_last_balls], ax
    mov ax, [hud_cpu_ms10]
    mov [hud_last_cpu], ax
    mov ax, [hud_wait_ms10]
    mov [hud_last_wait], ax
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
    mov bp, 64 * 32 / 4
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

; FPS is measured over at least 36 BIOS ticks (approximately two seconds).
; It includes CPU setup, XGA completion, and optional vertical retrace wait.
update_fps:
    pushad
    xor ah, ah
    int 0x1a
    movzx eax, cx
    shl eax, 16
    mov ax, dx
    mov [fps_now], eax
    cmp byte [fps_started], 0
    jne .elapsed
    mov [fps_start], eax
    mov byte [fps_started], 1
    mov dword [wait_pit_ticks], 0
    jmp .done
.elapsed:
    inc word [hud_frames]
    mov ebx, eax
    sub ebx, [fps_start]
    jnc .delta_ready
    add ebx, 0x1800b0             ; midnight rollover
.delta_ready:
    cmp ebx, 36
    jb .done
    movzx eax, word [hud_frames]
    mov ecx, 182
    mul ecx
    xor edx, edx
    div ebx
    cmp eax, 9999
    jbe .store
    mov ax, 9999
.store:
    mov [hud_fps10], ax
    ; Average frame duration uses BIOS ticks, while explicit waits use PIT ticks.
    ; Values are tenths of a millisecond and saturate at 999.9 ms.
    mov eax, ebx
    shl eax, 16
    movzx ecx, word [hud_frames]
    xor edx, edx
    div ecx
    mov ebx, 10000
    mul ebx
    mov ebx, 1193182
    div ebx
    cmp eax, 9999
    jbe .total_ready
    mov eax, 9999
.total_ready:
    mov [hud_total_ms10], ax
    mov eax, [wait_pit_ticks]
    xor edx, edx
    div ecx
    mov ebx, 10000
    mul ebx
    mov ebx, 1193182
    div ebx
    cmp eax, 9999
    jbe .wait_ready
    mov eax, 9999
.wait_ready:
    cmp ax, [hud_total_ms10]
    jbe .wait_bounded
    mov ax, [hud_total_ms10]
.wait_bounded:
    mov [hud_wait_ms10], ax
    mov dx, [hud_total_ms10]
    sub dx, ax
    mov [hud_cpu_ms10], dx
    mov eax, [fps_now]
    mov [fps_start], eax
    mov word [hud_frames], 0
    mov dword [wait_pit_ticks], 0
.done:
    popad
    ret

reset_fps:
    mov byte [fps_started], 0
    mov word [hud_frames], 0
    mov word [hud_fps10], 0
    mov word [hud_cpu_ms10], 0
    mov word [hud_wait_ms10], 0
    mov dword [wait_pit_ticks], 0
    mov word [hud_last_fps], 0xffff
    mov word [hud_last_cpu], 0xffff
    mov word [hud_last_wait], 0xffff
    ret

render_hud:
    pushad
    push es
    push ds
    pop es
    cld
    mov di, hud_canvas
    mov cx, 64 * 32 / 2
    xor ax, ax
    rep stosw
    pop es

    mov ax, [hud_fps10]
    mov si, hud_text_fps+4
    call format_tenths
    mov ax, [hud_cpu_ms10]
    mov si, hud_text_cpu+4
    call format_tenths
    mov ax, [hud_wait_ms10]
    mov si, hud_text_wait+5
    call format_tenths

    mov al, [hud_count_label]
    mov [hud_text_balls], al
    cmp byte [effect], 4
    jne .count_label_ready
    mov byte [hud_text_balls], 2  ; S = speed level in the 3D orbit
.count_label_ready:
    mov ax, [visible_balls]
    mov bx, 10
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text_balls+5], dl
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text_balls+4], dl
    xor dx, dx
    div bx
    add dl, 4
    mov [hud_text_balls+3], dl
    add al, 4
    mov [hud_text_balls+2], al
    mov byte [hud_text_balls+7], 15
    cmp byte [vsync_enabled], 0
    je .sync_done
    mov byte [hud_text_balls+7], 17
.sync_done:

    mov si, hud_text_fps
    mov di, hud_canvas + 65
    mov bp, 9
    call draw_hud_text
    mov si, hud_text_balls
    mov di, hud_canvas + 9 * 64 + 1
    mov bp, 8
    call draw_hud_text
    mov si, hud_text_cpu
    mov di, hud_canvas + 17 * 64 + 1
    mov bp, 9
    call draw_hud_text
    mov si, hud_text_wait
    mov di, hud_canvas + 25 * 64 + 1
    mov bp, 10
    call draw_hud_text
    popad
    ret

; AX tenths, SI destination of three digits, a dot, and one decimal digit.
format_tenths:
    mov bx, 10
    xor dx, dx
    div bx
    add dl, 4
    mov [si+4], dl
    xor dx, dx
    div bx
    add dl, 4
    mov [si+2], dl
    xor dx, dx
    div bx
    add dl, 4
    mov [si+1], dl
    add al, 4
    mov [si], al
    ret

; SI glyph indices, DI first canvas pixel, BP character count.
draw_hud_text:
    pushad
.char:
    push di
    movzx ax, byte [si]
    imul ax, 7
    mov bx, hud_glyphs
    add bx, ax
    mov dx, 7
.row:
    mov al, [bx]
    mov cx, 5
.pixel:
    test al, 0x10
    jz .skip
    mov byte [di], 1
.skip:
    shl al, 1
    inc di
    loop .pixel
    add di, 59
    inc bx
    dec dx
    jnz .row
    pop di
    add di, 6
    inc si
    dec bp
    jnz .char
    popad
    ret

hud_last_fps dw 0xffff
hud_last_balls dw 0xffff
hud_last_cpu dw 0xffff
hud_last_wait dw 0xffff
fps_started db 0
fps_start dd 0
fps_now dd 0
hud_frames dw 0
hud_fps10 dw 0
hud_total_ms10 dw 0
hud_cpu_ms10 dw 0
hud_wait_ms10 dw 0
wait_pit_ticks dd 0
hud_text_fps db 0,1,2,3,4,4,4,14,4
hud_text_balls db 16,3,4,4,4,4,15,17
hud_text_cpu db 18,1,19,3,4,4,4,14,4
hud_text_wait db 20,21,22,23,3,4,4,4,14,4
hud_glyphs:
    db 0x1f,0x10,0x10,0x1e,0x10,0x10,0x10 ; F
    db 0x1e,0x11,0x11,0x1e,0x10,0x10,0x10 ; P
    db 0x0f,0x10,0x10,0x0e,0x01,0x01,0x1e ; S
    db 0x00,0x04,0x04,0x00,0x04,0x04,0x00 ; :
    db 0x0e,0x11,0x13,0x15,0x19,0x11,0x0e ; 0
    db 0x04,0x0c,0x04,0x04,0x04,0x04,0x0e ; 1
    db 0x0e,0x11,0x01,0x02,0x04,0x08,0x1f ; 2
    db 0x1e,0x01,0x01,0x0e,0x01,0x01,0x1e ; 3
    db 0x02,0x06,0x0a,0x12,0x1f,0x02,0x02 ; 4
    db 0x1f,0x10,0x10,0x1e,0x01,0x01,0x1e ; 5
    db 0x0e,0x10,0x10,0x1e,0x11,0x11,0x0e ; 6
    db 0x1f,0x01,0x02,0x04,0x08,0x08,0x08 ; 7
    db 0x0e,0x11,0x11,0x0e,0x11,0x11,0x0e ; 8
    db 0x0e,0x11,0x11,0x0f,0x01,0x01,0x0e ; 9
    db 0x00,0x00,0x00,0x00,0x00,0x04,0x04 ; .
    times 7 db 0                        ; blank
    db 0x1e,0x11,0x11,0x1e,0x11,0x11,0x1e ; B
    db 0x11,0x11,0x11,0x11,0x11,0x0a,0x04 ; V
    db 0x0e,0x11,0x10,0x10,0x10,0x11,0x0e ; C
    db 0x11,0x11,0x11,0x11,0x11,0x11,0x0e ; U
    db 0x11,0x11,0x11,0x15,0x15,0x15,0x0a ; W
    db 0x0e,0x11,0x11,0x1f,0x11,0x11,0x11 ; A
    db 0x0e,0x04,0x04,0x04,0x04,0x04,0x0e ; I
    db 0x1f,0x04,0x04,0x04,0x04,0x04,0x04 ; T
hud_canvas times 64 * 32 db 0
