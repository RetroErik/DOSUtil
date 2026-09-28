; Shared XGA setup copied from the verified Dreams v2 source.
; By Dag Erik Hagesæter / Retro Erik using Codex in VS Code

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





