; XGA vector demo: cube, octahedron, polygon stress, torus, Boing Ball, crystal.
; By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
; Build: nasm -f bin xga_vector.asm -o bin/v2/XVECTOR.COM
cpu 386
bits 16
org 0x100

SCREEN_W equ 640
SCREEN_H equ 480
SCREEN_BYTES equ SCREEN_W * SCREEN_H
BACK_BASE equ SCREEN_BYTES
MASK_BASE equ 2 * SCREEN_BYTES
GRID_BASE equ MASK_BASE + SCREEN_BYTES / 8 ; 1-bit boundary map ends here
%ifdef XDEMO2
MESH_MASK_W equ 320
MESH_MASK_H equ 320
%else
MESH_MASK_W equ 128
MESH_MASK_H equ 128
%endif
LINE_OP equ 0x05118000       ; IBM XGA guide example: line draw, all pixels
AREA_BOUNDARY_LINE_OP equ 0x05138030 ; area boundary, mask scissoring disabled
AREA_FILL_OP equ 0x0A313000 ; map C to A, octant 0: left-to-right fill
MASKED_SOLID_OP equ 0x08113000 ; fixed color through 1-bit pattern map C
SOLID_A equ 0x08118000
OCTA_FACES equ 8
STRESS_MAX equ 512
STRESS_W equ 30
STRESS_H equ 22
TORUS_VERTS equ 128
TORUS_QUADS equ 128
BOING_QUADS equ 112
CRYSTAL_VERTS equ 120
CRYSTAL_FACETS equ 100

%ifdef XDEMO
%include "xdemo_scene.inc"
%else
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
    call setup_maps
    call enter_back_buffer
    call prerender_room_grid
    jc .cp_timeout
    mov byte [vsync_enabled], 1
    call setup_sprite_hud
.frame:
    cmp byte [demo_mode], 4
    jne .clear_frame
    call restore_room_grid
    jmp .frame_ready
.clear_frame:
    call clear_back_buffer
.frame_ready:
    jc .cp_timeout
    cmp byte [demo_mode], 0
    jne .other_demo
    call draw_cube
    jmp .draw_done
.other_demo:
    cmp byte [demo_mode], 1
    je .solid
    cmp byte [demo_mode], 2
    je .polygon_stress
    cmp byte [demo_mode], 4
    je .boing
    cmp byte [demo_mode], 5
    je .crystal
    call draw_torus
    jmp .draw_done
.crystal:
    call draw_crystal
    jmp .draw_done
.boing:
    call draw_boing
    jmp .draw_done
.polygon_stress:
    call draw_polygon_stress
    jmp .draw_done
.solid:
    call draw_solid
    jmp .draw_done
.draw_done:
    jc .cp_timeout
    call wait_cp
    jc .cp_timeout
    cmp byte [vsync_enabled], 0
    je .no_sync
    call wait_vsync
.no_sync:
    call present_back_frame
    jc .cp_timeout
    mov byte [hud_text_balls+6], 15 ; no mesh fill marker
    cmp byte [demo_mode], 1
    je .hud_solid
    cmp byte [demo_mode], 2
    je .hud_stress
    cmp byte [demo_mode], 3
    je .hud_torus
    cmp byte [demo_mode], 4
    je .hud_torus
    cmp byte [demo_mode], 5
    je .hud_torus
    mov word [visible_balls], 12
    mov byte [hud_count_label], 16 ; B = vector command count
    jmp .hud_ready
.hud_solid:
    mov word [visible_balls], OCTA_FACES
    mov byte [hud_count_label], 1 ; P = face count
    jmp .hud_ready
.hud_stress:
    mov ax, [stress_count]
    mov [visible_balls], ax
    mov byte [hud_count_label], 1 ; P = filled polygon count
    jmp .hud_ready
.hud_torus:
    mov ax, [mesh_drawn]
    mov [visible_balls], ax
    mov byte [hud_count_label], 1 ; P = visible mesh facets filled
    cmp byte [mesh_area_mode], 0
    je .hud_ready
    mov byte [hud_text_balls+6], 21 ; A = hybrid XGA Area Fill
.hud_ready:
    call update_fps
    call update_sprite_hud
    mov ah, 1
    int 0x16
    jz .animate
    xor ah, ah
    int 0x16
    cmp al, 27
    je .quit
    cmp al, '1'
    jb .key_space
    cmp al, '6'
    ja .key_space
    sub al, '1'
    mov [demo_mode], al
    jmp .mode_changed
.key_space:
    cmp al, ' '
    jne .key_v
    inc byte [demo_mode]
    cmp byte [demo_mode], 6
    jb .mode_changed
    mov byte [demo_mode], 0
.mode_changed:
    mov byte [speaker_frames], 0
    call stop_speaker
    call init_mesh_order
    call set_mask_map_for_mode
    jc .cp_timeout
    call reset_frame_page
    jc .cp_timeout
    call reset_fps
    jmp .animate
.key_v:
    cmp al, 'v'
    je .toggle_sync
    cmp al, 'V'
    je .toggle_sync
    cmp al, 'm'
    je .toggle_mesh_renderer
    cmp al, 'M'
    je .toggle_mesh_renderer
    cmp al, '+'
    je .increase_count
    cmp al, '='
    je .increase_count
    cmp al, '-'
    je .decrease_count
    jmp .animate
.increase_count:
    cmp byte [demo_mode], 2
    jne .animate
    cmp word [stress_count], STRESS_MAX
    jae .animate
    shl word [stress_count], 1
    call reset_fps
    jmp .animate
.decrease_count:
    cmp byte [demo_mode], 2
    jne .animate
    cmp word [stress_count], 8
    jbe .animate
    shr word [stress_count], 1
    call reset_fps
    jmp .animate
.toggle_sync:
    xor byte [vsync_enabled], 1
    call reset_fps
.toggle_done:
    jmp .animate
.toggle_mesh_renderer:
    cmp byte [demo_mode], 3
    jb .animate
    xor byte [mesh_area_mode], 1
    call set_mask_map_for_mode
    jc .cp_timeout
    call reset_fps
    jmp .toggle_done
.animate:
    inc word [rotation]
    cmp byte [demo_mode], 4
    jne .frame
    inc word [boing_frame]
    call update_boing_motion
    jmp .frame
.quit:
    call stop_speaker
    call restore_mode
    mov ax, 0x4c00
    int 0x21
.cp_timeout:
    call stop_speaker
    call restore_mode
    mov dx, msg_cp_timeout
    jmp .error
.no_vram:
    call stop_speaker
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
%endif

puts:
    mov ah, 9
    int 0x21
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
%ifdef XDEMO
    mov si, xdemo_palette
    mov cx, 144 ; 16 base CGA colors + 8 lanes x 4 shades
%else
    mov si, vector_palette
    mov cx, 60
%endif
.color:
    lodsb
%ifndef XDEMO
    shl al, 2
%endif
%ifdef XDEMO2
    shl al, 2
%endif
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
    mov byte [es:0x48], 3
    mov byte [es:0x49], 5
    mov byte [es:0x4a], 4
    mov dword [es:0x50], 0xff
    mov dword [es:0x54], 0xff
    mov dword [es:0x5c], 0
    mov byte [es:0x12], 0
    mov eax, [cp_aperture]
    add eax, MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 0
    mov word [es:0x6c], 0
    mov word [es:0x6e], 0
    mov byte [es:0x12], 1
    mov byte [es:0x12], 3
    mov eax, [cp_aperture]
    add eax, MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 0
    mov byte [es:0x12], 1
    ret

; Map C points to VRAM for Area Fill and to the conventional-RAM mask for
; the proven fallback. Keep its active source so consecutive quads avoid
; redundant map setup.
set_mask_map_for_mode:
    cmp byte [demo_mode], 3
    jb select_mesh_vram_map
    cmp byte [mesh_area_mode], 0
    jne select_mesh_vram_map
    jmp select_mesh_ram_map

select_mesh_vram_map:
    cmp byte [mesh_map_ram], 0
    je .ready
    call wait_cp
    jc .done
    mov byte [es:0x12], 3
    mov eax, [cp_aperture]
    add eax, MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 0
    mov byte [es:0x12], 1
    mov byte [mesh_map_ram], 0
.ready:
    clc
.done:
    ret

select_mesh_ram_map:
    cmp byte [mesh_map_ram], 1
    je .ready
    call wait_cp
    jc .done
    mov byte [es:0x12], 3
    mov ax, cs
    movzx eax, ax
    shl eax, 4
    add eax, mesh_mask_ram
    mov [es:0x14], eax
    mov word [es:0x18], MESH_MASK_W-1
    mov word [es:0x1a], MESH_MASK_H-1
    mov byte [es:0x1c], 0
    mov byte [es:0x12], 1
    mov byte [mesh_map_ram], 1
.ready:
    clc
.done:
    ret

; Return to the fixed hidden page whenever the demo changes.
reset_frame_page:
    call wait_cp
    jc .done
    xor eax, eax
    call set_view_start
    mov dword [draw_page_base], BACK_BASE
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
    clc
.done:
    ret

; XGA display start is expressed in four-byte units. Register 42h latches
; the new address, allowing a completed hidden page to become visible.
set_view_start:
    push ebx
    push dx
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
    mov al, 0x42
    out dx, ax
    pop dx
    pop ebx
    ret

enter_back_buffer:
    call wait_cp
    jc .done
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
.done:
    ret

; Store the static Boing room in spare 8-bit VRAM (652800..959999).
; This replaces about 50 line commands with one XGA BitBlt per frame.
prerender_room_grid:
    call wait_cp
    jc .done
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, GRID_BASE
    mov [es:0x14], eax
    call clear_back_buffer
    jc .restore
    call draw_room_grid
    jc .restore
    call wait_cp
.restore:
    pushf
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
    popf
.done:
    ret

restore_room_grid:
    call wait_cp
    jc .done
    mov byte [es:0x12], 2
    mov eax, [cp_aperture]
    add eax, GRID_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 3
    mov word [es:0x70], 0
    mov word [es:0x72], 0
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, [draw_page_base]
    mov [es:0x14], eax
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov dword [es:0x7c], 0xA8218000
    call wait_cp
.done:
    ret

present_back_frame:
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
    mov dword [es:0x7c], 0xA8218000
    call wait_cp
    jc .done
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
.done:
    ret

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

clear_back_buffer:
    call wait_cp
    jc .done
    mov dword [es:0x58], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov dword [es:0x7c], SOLID_A
    call wait_cp
.done:
    ret

clear_boundary_map:
    call wait_cp
    jc .done
    mov byte [es:0x12], 3
    mov eax, [cp_aperture]
    add eax, MASK_BASE
    mov [es:0x14], eax
    mov word [es:0x18], SCREEN_W-1
    mov word [es:0x1a], SCREEN_H-1
    mov byte [es:0x1c], 0
    mov dword [es:0x58], 0
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov dword [es:0x7c], 0x08138000
    call wait_cp
    jc .done
    mov byte [es:0x12], 1
    mov eax, [cp_aperture]
    add eax, BACK_BASE
    mov [es:0x14], eax
.done:
    ret

; Convert two endpoints to XGA's normalized Bresenham line parameters.
draw_line:
    push ax
    push dx
    push bx
    push cx
    push si
    push di
    push bp
    mov si, ax
    mov di, dx
    mov bp, bx
    mov byte [line_octant], 0
    sub bx, ax
    jns .x_positive
    neg bx
    or byte [line_octant], 4
.x_positive:
    sub cx, dx
    jns .y_positive
    neg cx
    or byte [line_octant], 2
.y_positive:
    cmp bx, cx
    jae .x_major
    xchg bx, cx
    or byte [line_octant], 1
.x_major:
    mov bp, bx
    movzx eax, byte [line_color]
    mov [es:0x58], eax
    xor ax, ax
    add ax, cx
    add ax, cx
    sub ax, bx
    mov [es:0x20], ax
    mov ax, cx
    add ax, cx
    mov [es:0x24], ax
    mov ax, cx
    sub ax, bx
    add ax, cx
    sub ax, bx
    mov [es:0x28], ax
    mov [es:0x60], bp
    mov word [es:0x62], 0
    mov [es:0x78], si
    mov [es:0x7a], di
    mov eax, LINE_OP
    cmp byte [line_flags], 0
    je .normal_line
    mov eax, AREA_BOUNDARY_LINE_OP
.normal_line:
    and eax, 0xfffffff8
    movzx ebx, byte [line_octant]
    or eax, ebx
    movzx ebx, byte [line_flags]
    or eax, ebx
    mov [es:0x7c], eax
    call wait_cp
.done:
    pop bp
    pop di
    pop si
    pop cx
    pop bx
    pop dx
    pop ax
    ret

; Rotate all eight cube vertices around Y and X before drawing 12 edges.
; Each angle uses the full 256-entry sine cycle, with no sawtooth reset.
draw_cube:
    mov ax, [rotation]
    and ax, 255
    mov bx, ax
    movsx ax, byte [sine_table+bx]
    mov [cube_sin_y], ax
    add bx, 64
    and bx, 255
    movsx ax, byte [sine_table+bx]
    mov [cube_cos_y], ax
    mov ax, [rotation]
    shr ax, 1
    add ax, 32
    and ax, 255
    mov bx, ax
    movsx ax, byte [sine_table+bx]
    mov [cube_sin_x], ax
    add bx, 64
    and bx, 255
    movsx ax, byte [sine_table+bx]
    mov [cube_cos_x], ax
    xor si, si
.vertex:
    mov bx, si
    shl bx, 1
    mov di, bx
    shl bx, 1
    add bx, di                  ; six bytes per 3D vertex
    shl di, 1                  ; four bytes per projected vertex
    mov ax, [cube_points+bx]
    mov [tmp_x], ax
    mov ax, [cube_points+bx+2]
    mov [tmp_y], ax
    mov ax, [cube_points+bx+4]
    mov [tmp_z], ax
    mov ax, [tmp_x]
    imul word [cube_cos_y]
    sar ax, 7
    mov [tmp1], ax
    mov ax, [tmp_z]
    imul word [cube_sin_y]
    sar ax, 7
    sub [tmp1], ax
    mov ax, [tmp1]
    add ax, 320
    mov [projected_points+di], ax
    mov ax, [tmp_x]
    imul word [cube_sin_y]
    sar ax, 7
    mov [tmp2], ax
    mov ax, [tmp_z]
    imul word [cube_cos_y]
    sar ax, 7
    add ax, [tmp2]
    mov [tmp_zrot], ax
    mov ax, [tmp_y]
    imul word [cube_cos_x]
    sar ax, 7
    mov [tmp2], ax
    mov ax, [tmp_zrot]
    imul word [cube_sin_x]
    sar ax, 7
    sub [tmp2], ax
    mov ax, [tmp2]
    add ax, 240
    mov [projected_points+di+2], ax
    inc si
    cmp si, 8
    jb .vertex
    xor si, si
.edge:
    movzx bx, byte [cube_edges+si]
    shl bx, 2
    mov ax, [projected_points+bx]
    mov dx, [projected_points+bx+2]
    movzx bx, byte [cube_edges+si+1]
    shl bx, 2
    mov cx, [projected_points+bx+2]
    mov bx, [projected_points+bx]
    call draw_line
    jc .done
    add si, 2
    cmp si, cube_edges_end-cube_edges
    jb .edge
.done:
    ret

finish_area:
    jc .done
    mov byte [line_flags], 0
    call wait_cp
    jc .done
    mov byte [es:0x48], 3   ; source mix for the color fill
    movzx eax, byte [fill_color]
    mov [es:0x58], eax
    mov word [es:0x60], SCREEN_W-1
    mov word [es:0x62], SCREEN_H-1
    mov word [es:0x70], 0       ; force a known source/pattern read origin;
    mov word [es:0x72], 0       ; a prior BitBlt/fill can leave these
    mov word [es:0x74], 0       ; auto-incremented, misaligning this fill's
    mov word [es:0x76], 0       ; read of the boundary map
    mov word [es:0x78], 0
    mov word [es:0x7a], 0
    mov dword [es:0x7c], AREA_FILL_OP
    call wait_cp
.done:
    ret

; Single Y-axis rotation, then orthographic screen projection; keeps
; rotated Z per vertex for the painter's-algorithm face sort that follows.
rotate_octa:
    mov ax, [rotation]
    and ax, 255
    mov bx, ax
    movsx ax, byte [sine_table+bx]
    mov [rot_sin], ax
    add bx, 64
    and bx, 255
    movsx ax, byte [sine_table+bx]
    mov [rot_cos], ax
    xor si, si
.vert:
    mov bx, si
    add bx, bx
    add bx, si
    add bx, bx
    mov di, si
    add di, di
    mov ax, [octa_verts+bx]
    mov [tmp_x], ax
    mov ax, [octa_verts+bx+4]
    mov [tmp_z], ax
    mov ax, [tmp_x]
    imul word [rot_cos]
    sar ax, 7
    mov [tmp1], ax
    mov ax, [tmp_z]
    imul word [rot_sin]
    sar ax, 7
    mov [tmp2], ax
    mov ax, [tmp1]
    sub ax, [tmp2]
%ifdef XDEMO
    add ax, [xdemo_octa_cx]
%else
    add ax, 320
%endif
    mov [octa_screen_x+di], ax
    mov ax, [tmp_x]
    imul word [rot_sin]
    sar ax, 7
    mov [tmp1], ax
    mov ax, [tmp_z]
    imul word [rot_cos]
    sar ax, 7
    mov [tmp2], ax
    mov ax, [tmp1]
    add ax, [tmp2]
    mov [octa_rot_z+di], ax
    mov ax, [octa_verts+bx+2]
%ifdef XDEMO
    mov cx, [xdemo_octa_cy]
%else
    mov cx, 240
%endif
    sub cx, ax
    mov [octa_screen_y+di], cx ; equatorial vertices share one scan line
    inc si
    cmp si, 6
    jb .vert
    ret

; Per-face depth is the sum of its three rotated vertex Z values.
build_depth:
    xor bx, bx
.face:
    mov si, bx
    shl si, 2
    movzx di, byte [octa_faces+si]
    add di, di
    mov ax, [octa_rot_z+di]
    movzx di, byte [octa_faces+si+1]
    add di, di
    add ax, [octa_rot_z+di]
    movzx di, byte [octa_faces+si+2]
    add di, di
    add ax, [octa_rot_z+di]
    mov di, bx
    add di, di
    mov [octa_depth+di], ax
    inc bx
    cmp bx, OCTA_FACES
    jb .face
    ret

; Bubble sort octa_order back-to-front by depth; no z-buffer in the XGA,
; so faces must be drawn farthest first for correct opaque overdraw.
sort_faces:
    mov cx, OCTA_FACES - 1
.pass:
    push cx
    xor bx, bx
.compare:
    mov si, bx
    inc si
    movzx ax, byte [octa_order+bx]
    add ax, ax
    mov di, ax
    mov ax, [octa_depth+di]
    movzx dx, byte [octa_order+si]
    add dx, dx
    mov di, dx
    mov dx, [octa_depth+di]
    cmp ax, dx
    jge .no_swap
    mov al, [octa_order+bx]
    mov ah, [octa_order+si]
    mov [octa_order+bx], ah
    mov [octa_order+si], al
.no_swap:
    inc bx
    cmp bx, OCTA_FACES-1
    jb .compare
    pop cx
    loop .pass
    ret

; Rotate, depth-sort, then draw each triangular face: boundary edges into
; the 1-bit map, one Area Fill per face, farthest face first.
draw_solid:
%ifdef XDEMO
    call xdemo_rotate_octa
%else
    call rotate_octa
%endif
    call build_depth
    call sort_faces
    mov byte [solid_pos], 0
.face:
    movzx bx, byte [solid_pos]
    movzx si, byte [octa_order+bx]
    shl si, 2
%ifdef XDEMO2
    call xdemo2_face_too_small
    jc .next_face
%else
    ; Each face has two equatorial vertices. Skip an edge-on projection
    ; rather than asking Area Fill to scan a zero- or one-pixel-wide wedge.
    movzx bx, byte [octa_faces+si]
    cmp bx, 2
    jb .equator_ready
    movzx bx, byte [octa_faces+si+1]
.equator_ready:
    add bx, bx
    mov ax, [octa_screen_x+bx]
    movzx bx, byte [octa_faces+si+2]
    add bx, bx
    sub ax, [octa_screen_x+bx]
    cmp ax, 1
    je .next_face
    cmp ax, -1
    je .next_face
    or ax, ax
    jz .next_face
%endif
%ifdef XDEMO2
    call xdemo2_fill_masked_face
    jc .done
    jmp .next_face
%else
    call clear_boundary_map
    jc .done
    mov byte [es:0x48], 6
    mov byte [line_flags], 0x30
    movzx bx, byte [octa_faces+si]
    add bx, bx
    mov ax, [octa_screen_x+bx]
    mov dx, [octa_screen_y+bx]
    movzx bx, byte [octa_faces+si+1]
    add bx, bx
    mov cx, [octa_screen_y+bx]
    mov bx, [octa_screen_x+bx]
    call draw_line
    jc .done
    movzx bx, byte [octa_faces+si+1]
    add bx, bx
    mov ax, [octa_screen_x+bx]
    mov dx, [octa_screen_y+bx]
    movzx bx, byte [octa_faces+si+2]
    add bx, bx
    mov cx, [octa_screen_y+bx]
    mov bx, [octa_screen_x+bx]
    call draw_line
    jc .done
    movzx bx, byte [octa_faces+si+2]
    add bx, bx
    mov ax, [octa_screen_x+bx]
    mov dx, [octa_screen_y+bx]
    movzx bx, byte [octa_faces+si]
    add bx, bx
    mov cx, [octa_screen_y+bx]
    mov bx, [octa_screen_x+bx]
    call draw_line
    jc .done
    movzx ax, byte [octa_faces+si+3]
    mov [fill_color], al
    call finish_area
%endif
    jc .done
.next_face:
    inc byte [solid_pos]
    cmp byte [solid_pos], OCTA_FACES
    jb .face
    clc
.done:
    ret

; Fill two moving triangles per cell in a permuted 16x16 grid. The CPU
; selects vertices and color; XGA clears map C and fills map A.
draw_polygon_stress:
    mov word [stress_index], 0
.polygon:
    call position_stress_polygon
    call clear_stress_boundary
    jc .done
    mov byte [es:0x48], 6
    mov byte [line_flags], 0x30
    test byte [stress_index], 1
    jnz .second
    mov ax, [stress_xmid]
    mov dx, [stress_y0]
    mov bx, [stress_x1]
    mov cx, [stress_ymid]
    call draw_line
    jc .done
    mov ax, [stress_x1]
    mov dx, [stress_ymid]
    mov bx, [stress_x0]
    mov cx, dx
    call draw_line
    jc .done
    mov ax, [stress_x0]
    mov dx, [stress_ymid]
    mov bx, [stress_xmid]
    mov cx, [stress_y0]
    call draw_line
    jc .done
    jmp .fill
.second:
    mov ax, [stress_x0]
    mov dx, [stress_ymid]
    mov bx, [stress_x1]
    mov cx, dx
    call draw_line
    jc .done
    mov ax, [stress_x1]
    mov dx, [stress_ymid]
    mov bx, [stress_xmid]
    mov cx, [stress_y1]
    call draw_line
    jc .done
    mov ax, [stress_xmid]
    mov dx, [stress_y1]
    mov bx, [stress_x0]
    mov cx, [stress_ymid]
    call draw_line
    jc .done
.fill:
    call fill_stress_polygon
    jc .done
    inc word [stress_index]
    mov ax, [stress_index]
    cmp ax, [stress_count]
    jb .polygon
.done:
    ret

position_stress_polygon:
    mov ax, [stress_index]
    shr ax, 1
    mov bx, 73                  ; odd multiplier visits all 256 cells
    mul bx
    and ax, 255
    mov [stress_cell], ax
    mov bx, ax
    and bx, 15
    shl bx, 5
    add bx, 64
    mov [stress_x0], bx
    add bx, STRESS_W-1
    mov [stress_x1], bx
    shr ax, 4
    mov bx, ax
    shl bx, 3
    shl ax, 4
    add ax, bx                  ; row * 24
    add ax, 64
    mov [stress_y0], ax
    add ax, STRESS_H-1
    mov [stress_y1], ax
    mov bx, [stress_cell]
    mov ax, bx
    shl bx, 4
    add bx, ax                  ; cell * 17 gives each diamond a phase
    mov ax, [rotation]
    shl ax, 1
    add bx, ax
    and bx, 255
    movsx ax, byte [sine_table+bx]
    sar ax, 4                   ; horizontal movement: -8 to +7 pixels
    add [stress_x0], ax
    add [stress_x1], ax
    add bx, 64
    and bx, 255
    movsx ax, byte [sine_table+bx]
    sar ax, 4                   ; vertical movement: -8 to +7 pixels
    add [stress_y0], ax
    add [stress_y1], ax
    mov ax, [stress_x0]
    add ax, STRESS_W/2
    mov [stress_xmid], ax
    mov ax, [stress_y0]
    add ax, STRESS_H/2
    mov [stress_ymid], ax
    mov ax, [stress_index]
    and al, 7
    add al, 2                   ; palette entries 2 through 9
    mov [fill_color], al
    ret

clear_stress_boundary:
    call wait_cp
    jc .done
    mov byte [es:0x12], 3      ; 1-bit map C
    mov dword [es:0x58], 0
    mov word [es:0x60], STRESS_W-1
    mov word [es:0x62], STRESS_H-1
    mov ax, [stress_x0]
    mov [es:0x78], ax
    mov ax, [stress_y0]
    mov [es:0x7a], ax
    mov dword [es:0x7c], 0x08138000
    call wait_cp
    jc .done
    mov byte [es:0x12], 1      ; restore hidden 8-bit map A
.done:
    ret

fill_stress_polygon:
    mov byte [line_flags], 0
    call wait_cp
    jc .done
    mov byte [es:0x48], 3
    movzx eax, byte [fill_color]
    mov [es:0x58], eax
    mov word [es:0x60], STRESS_W-1
    mov word [es:0x62], STRESS_H-1
    mov ax, [stress_x0]
    mov [es:0x70], ax
    mov [es:0x74], ax           ; pattern and destination start together
    mov [es:0x78], ax
    mov ax, [stress_y0]
    mov [es:0x72], ax
    mov [es:0x76], ax
    mov [es:0x7a], ax
    mov dword [es:0x7c], AREA_FILL_OP
    call wait_cp
.done:
    ret

; Rebuild the shared sort order whenever the active mesh changes.
init_mesh_order:
    xor bx, bx
.next:
    mov [torus_order+bx], bl
    inc bx
    cmp bx, TORUS_QUADS
    jb .next
    ret

; Painter's order for a closed mesh: far quads first.
draw_torus:
    mov word [mesh_vertices], torus_vertices
    mov word [mesh_quads], torus_quads
    mov word [mesh_area_table], torus_area_unsafe
    mov word [mesh_quad_count], TORUS_QUADS
    mov word [mesh_vertex_count], TORUS_VERTS
    mov word [mesh_center_x], 320
    mov word [mesh_center_y], 240
    jmp draw_mesh

; Convex crystal: backface culling makes painter sorting unnecessary.
draw_crystal:
    mov word [mesh_vertices], crystal_vertices
    mov word [mesh_quads], crystal_quads
    mov word [mesh_area_table], crystal_area_unsafe
    mov word [mesh_quad_count], CRYSTAL_FACETS
    mov word [mesh_vertex_count], CRYSTAL_VERTS
    mov word [mesh_center_x], 320
    mov word [mesh_center_y], 240
    jmp draw_mesh

; XGA-native Boing Ball: draw the room as hardware lines and the spinning
; checker sphere as depth-sorted, XGA-filled polygon faces.
draw_boing:
    call draw_shadow
    jc .done
    mov word [mesh_vertices], boing_vertices
    mov word [mesh_quads], boing_quads
    mov word [mesh_area_table], boing_area_unsafe
    mov word [mesh_quad_count], BOING_QUADS
    mov word [mesh_vertex_count], TORUS_VERTS
    mov ax, [boing_x]
    mov [mesh_center_x], ax
    mov ax, [boing_y]
    mov [mesh_center_y], ax
    call draw_mesh
.done:
    ret

; Nine gray XGA lines form a flattened floor shadow. It shrinks at the apex.
draw_shadow:
    mov ax, 300
    sub ax, [boing_y]
    shr ax, 2
    mov [shadow_shrink], ax
    mov byte [es:0x48], 3
    mov byte [line_flags], 0
    mov byte [line_color], 9
    mov word [shadow_row], 0
.row:
    mov si, [shadow_row]
    shl si, 1
    mov ax, [shadow_widths+si]
    sub ax, [shadow_shrink]
    cmp ax, 6
    jae .width_ok
    mov ax, 6
.width_ok:
    mov [shadow_half], ax
    mov bx, [boing_x]
    add bx, 10
    mov ax, bx
    sub ax, [shadow_half]
    add bx, [shadow_half]
    mov dx, [shadow_row]
    add dx, 358
    mov cx, dx
    call draw_line
    jc .done
    inc word [shadow_row]
    cmp word [shadow_row], 9
    jb .row
    clc
.done:
    mov byte [line_color], 1
    ret

draw_room_grid:
    mov byte [es:0x48], 3
    mov byte [line_flags], 0
    mov byte [line_color], 6
    mov word [grid_index], 0
.wall_vertical:
    mov ax, [grid_index]
    mov bx, 26
    mul bx
    add ax, 124
    mov bx, ax
    mov dx, 0
    mov cx, 330
    call draw_line
    jc .done
    inc word [grid_index]
    cmp word [grid_index], 16
    jb .wall_vertical
    mov word [grid_index], 0
.wall_horizontal:
    mov ax, [grid_index]
    mov bx, 22
    mul bx
    mov dx, ax
    mov cx, ax
    mov ax, 124
    mov bx, 514
    call draw_line
    jc .done
    inc word [grid_index]
    cmp word [grid_index], 16
    jb .wall_horizontal
    mov word [grid_index], 0
.floor_vertical:
    mov ax, [grid_index]
    mov bx, 26
    mul bx
    add ax, 124
    mov [grid_top_x], ax
    mov ax, [grid_index]
    mov bx, 40
    mul bx
    add ax, 16
    mov bx, ax
    mov ax, [grid_top_x]
    mov dx, 330
    mov cx, 380
    call draw_line
    jc .done
    inc word [grid_index]
    cmp word [grid_index], 16
    jb .floor_vertical
    mov si, floor_rows
    mov word [grid_index], 3
.floor_horizontal:
    mov ax, [si]
    mov dx, [si+2]
    mov bx, [si+4]
    mov cx, dx
    call draw_line
    jc .done
    add si, 6
    dec word [grid_index]
    jnz .floor_horizontal
    clc
.done:
    mov byte [line_color], 1
    ret

update_boing_motion:
    mov bx, [boing_frame]
    and bx, 63
    cmp bx, 0
    jne .no_impact
    call start_boing_sound
.no_impact:
    shl bx, 1
    mov ax, [boing_bounce+bx]
    mov bx, 110
    mul bx
    shr ax, 8
    mov bx, 300
    sub bx, ax
    mov [boing_y], bx
    mov ax, [boing_x]
    add ax, [boing_dx]
    mov [boing_x], ax
    cmp ax, 100
    jg .right
    mov word [boing_dx], 5
    call start_boing_sound
.right:
    cmp ax, 540
    jl .sound
    mov word [boing_dx], -5
    call start_boing_sound
.sound:
    cmp byte [speaker_frames], 0
    je .done
    dec byte [speaker_frames]
    jnz .pitch
    call stop_speaker
    ret
.pitch:
    mov ax, [speaker_divisor]
    add ax, 220
    mov [speaker_divisor], ax
    out 0x42, al
    mov al, ah
    out 0x42, al
.done:
    ret

start_boing_sound:
    push ax
    mov byte [speaker_frames], 4
    mov word [speaker_divisor], 1800
    mov al, 0xb6
    out 0x43, al
    mov ax, 1800
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 3
    out 0x61, al
    pop ax
    ret

stop_speaker:
    in al, 0x61
    and al, 0xfc
    out 0x61, al
    ret

draw_mesh:
    mov byte [line_color], 1
    call project_torus
    cmp byte [demo_mode], 4
    je .order_ready             ; convex sphere needs only backface culling
    cmp byte [demo_mode], 5
    je .order_ready             ; convex crystal also needs no sort
    call build_torus_depth
    call sort_torus_quads
.order_ready:
    mov byte [torus_pos], 0
    mov word [mesh_drawn], 0
.quad:
    movzx bx, byte [torus_pos]
    movzx ax, byte [torus_order+bx]
    mov [mesh_quad_index], al
    mov bx, ax
    shl bx, 2
    add bx, ax
    add bx, [mesh_quads]
    mov [torus_quad_offset], bx
    mov al, [bx+4]
    mov [fill_color], al
    mov al, [bx]
    mov [tri_a], al
    mov al, [bx+1]
    mov [tri_b], al
    mov al, [bx+2]
    mov [tri_c], al
    mov al, [bx+3]
    mov [tri_d], al
    call render_mesh_quad
    jc .done
    inc byte [torus_pos]
    mov al, [torus_pos]
    cmp al, byte [mesh_quad_count]
    jb .quad
.done:
    ret

; Backface cull one projected checker or torus quad. A precomputed bit
; selects XGA Area Fill or the proven CPU-mask/XGA BitBlt fallback.
render_mesh_quad:
    movzx si, byte [tri_a]
    shl si, 1
    mov ax, [torus_screen_x+si]
    mov [tri_x0], ax
    mov ax, [torus_screen_y+si]
    mov [tri_y0], ax
    movzx si, byte [tri_b]
    shl si, 1
    mov ax, [torus_screen_x+si]
    mov [tri_x1], ax
    mov ax, [torus_screen_y+si]
    mov [tri_y1], ax
    movzx si, byte [tri_c]
    shl si, 1
    mov ax, [torus_screen_x+si]
    mov [tri_x2], ax
    mov ax, [torus_screen_y+si]
    mov [tri_y2], ax
    movzx si, byte [tri_d]
    shl si, 1
    mov ax, [torus_screen_x+si]
    mov [tri_x3], ax
    mov ax, [torus_screen_y+si]
    mov [tri_y3], ax
    mov ax, [tri_x1]
    sub ax, [tri_x0]
    mov [tri_dx1], ax
    mov ax, [tri_y1]
    sub ax, [tri_y0]
    mov [tri_dy1], ax
    mov ax, [tri_x2]
    sub ax, [tri_x0]
    mov [tri_dx2], ax
    mov ax, [tri_y2]
    sub ax, [tri_y0]
    mov [tri_dy2], ax
    mov ax, [tri_x3]
    sub ax, [tri_x0]
    mov [tri_dx3], ax
    mov ax, [tri_y3]
    sub ax, [tri_y0]
    mov [tri_dy3], ax
    mov ax, [tri_dx1]
    imul word [tri_dy2]
    mov [tri_cross], ax
    mov ax, [tri_dy1]
    imul word [tri_dx2]
    sub [tri_cross], ax
    mov ax, [tri_dx2]
    imul word [tri_dy3]
    mov [quad_cross2], ax
    mov ax, [tri_dy2]
    imul word [tri_dx3]
    sub [quad_cross2], ax
    mov ax, [tri_cross]
    xor ax, [quad_cross2]
    js .skip                     ; twisted projected quad near the silhouette
    mov ax, [quad_cross2]
    add [tri_cross], ax
    cmp word [tri_cross], 4     ; a,b,c,d winding faces toward +Z
    jle .skip
    mov ax, [tri_x0]
    mov [tri_min_x], ax
    mov [tri_max_x], ax
    mov ax, [tri_y0]
    mov [tri_min_y], ax
    mov [tri_max_y], ax
    mov ax, [tri_x1]
    cmp ax, [tri_min_x]
    jge .x1_min_done
    mov [tri_min_x], ax
.x1_min_done:
    cmp ax, [tri_max_x]
    jle .x1_max_done
    mov [tri_max_x], ax
.x1_max_done:
    mov ax, [tri_x2]
    cmp ax, [tri_min_x]
    jge .x2_min_done
    mov [tri_min_x], ax
.x2_min_done:
    cmp ax, [tri_max_x]
    jle .x2_max_done
    mov [tri_max_x], ax
.x2_max_done:
    mov ax, [tri_x3]
    cmp ax, [tri_min_x]
    jge .x3_min_done
    mov [tri_min_x], ax
.x3_min_done:
    cmp ax, [tri_max_x]
    jle .x3_max_done
    mov [tri_max_x], ax
.x3_max_done:
    mov ax, [tri_y1]
    cmp ax, [tri_min_y]
    jge .y1_min_done
    mov [tri_min_y], ax
.y1_min_done:
    cmp ax, [tri_max_y]
    jle .y1_max_done
    mov [tri_max_y], ax
.y1_max_done:
    mov ax, [tri_y2]
    cmp ax, [tri_min_y]
    jge .y2_min_done
    mov [tri_min_y], ax
.y2_min_done:
    cmp ax, [tri_max_y]
    jle .y2_max_done
    mov [tri_max_y], ax
.y2_max_done:
    mov ax, [tri_y3]
    cmp ax, [tri_min_y]
    jge .y3_min_done
    mov [tri_min_y], ax
.y3_min_done:
    cmp ax, [tri_max_y]
    jle .y3_max_done
    mov [tri_max_y], ax
.y3_max_done:
    mov ax, [tri_max_x]
    sub ax, [tri_min_x]
    cmp ax, 1
    jbe .skip
    cmp ax, MESH_MASK_W-1
    ja .skip
    mov [tri_width], ax
    mov ax, [tri_max_y]
    sub ax, [tri_min_y]
    cmp ax, 1
    jbe .skip
    cmp ax, MESH_MASK_H-1
    ja .skip
    mov [tri_height], ax
    cmp byte [demo_mode], 4
    jne .shade_done
    mov ax, [tri_y0]
    add ax, [tri_y1]
    add ax, [tri_y2]
    add ax, [tri_y3]
    shr ax, 2
    mov bx, [boing_y]
    add bx, 20
    cmp ax, bx
    jle .shade_done
    cmp byte [fill_color], 7
    jne .shade_white
    mov byte [fill_color], 10 ; shaded magenta
    jmp .shade_done
.shade_white:
    mov byte [fill_color], 11 ; shaded white
.shade_done:
    cmp byte [mesh_area_mode], 0
    je .mask_fill
    mov bx, [rotation]
    and bx, 511
    shl bx, 4
    movzx ax, byte [mesh_quad_index]
    shr ax, 3
    add bx, ax
    mov si, [mesh_area_table]
    mov al, [si+bx]
    mov cl, [mesh_quad_index]
    and cl, 7
    shr al, cl
    test al, 1
    jz .area_fill
.mask_fill:
    call select_mesh_ram_map
    jc .done
    call raster_quad_mask
    jc .done
    call fill_masked_quad
    jc .done
    jmp .filled
.area_fill:
    call select_mesh_vram_map
    jc .done
    call fill_quad_area
    jc .done
.filled:
    inc word [mesh_drawn]
    clc
    ret
.skip:
    clc
.done:
    ret

; Clear the small local mask box in conventional RAM. Only the bytes XGA
; will sample are reset; the full 128x128 map never needs clearing.
clear_mask_box:
    push ax
    push bx
    push cx
    push di
    push es
%ifdef XDEMO2
    mov ax, [xdemo2_mask_seg]
    mov es, ax
%else
    push ds
    pop es
%endif
    mov ax, [tri_width]
    shr ax, 3
    inc ax
    mov [mask_clear_bytes], ax
    mov bx, [tri_height]
    inc bx
%ifdef XDEMO2
    xor di, di
%else
    mov di, mesh_mask_ram
%endif
    cld
.row:
    mov cx, [mask_clear_bytes]
    push di
    xor ax, ax
    rep stosb
    pop di
    add di, MESH_MASK_W/8
    dec bx
    jnz .row
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    clc
    ret

; Build two X intersections per row in system RAM. Each edge slope uses
; signed 16.16 division once; each scanline then uses addition.
prepare_mask_spans:
    mov ax, [tri_x0]
    mov [tri_x4], ax
    mov ax, [tri_y0]
    mov [tri_y4], ax
    mov cx, [tri_height]
    xor bx, bx
.init:
    mov word [mask_scan_left+bx], MESH_MASK_W
    mov word [mask_scan_right+bx], 0
    add bx, 2
    loop .init
    mov si, tri_x0
    mov bp, 4
.edge:
    mov ax, [si]              ; x0
    mov dx, [si+2]            ; y0
    mov bx, [si+4]            ; x1
    mov cx, [si+6]            ; y1
    cmp dx, cx
    je .next_edge
    jl .ordered
    xchg ax, bx
    xchg dx, cx
.ordered:
    mov [edge_y], dx
    mov [edge_end_y], cx
    mov [edge_top_x], ax
    sub ax, [tri_min_x]
    cwde
    shl eax, 16
    mov [edge_x_fp], eax
    mov ax, bx
    sub ax, [edge_top_x]
    cwde
    shl eax, 16
    cdq
    mov bx, cx
    sub bx, [edge_y]
    movzx ebx, bx
    idiv ebx
    mov [edge_slope], eax
    mov bx, [edge_y]
    sub bx, [tri_min_y]
    shl bx, 1
.edge_row:
    mov eax, [edge_x_fp]
    sar eax, 16
    cmp ax, 0
    jge .left_clamped
    xor ax, ax
.left_clamped:
    cmp ax, [tri_width]
    jle .right_clamped
    mov ax, [tri_width]
.right_clamped:
    cmp ax, [mask_scan_left+bx]
    jge .left_kept
    mov [mask_scan_left+bx], ax
.left_kept:
    cmp ax, [mask_scan_right+bx]
    jle .right_kept
    mov [mask_scan_right+bx], ax
.right_kept:
    mov eax, [edge_slope]
    add [edge_x_fp], eax
    add bx, 2
    inc word [edge_y]
    mov ax, [edge_y]
    cmp ax, [edge_end_y]
    jl .edge_row
.next_edge:
    add si, 4
    dec bp
    jnz .edge
    ret

; Write covered span bytes into the local mask in conventional RAM.
raster_quad_mask:
    call clear_mask_box
    call prepare_mask_spans
    push es
%ifdef XDEMO2
    mov ax, [xdemo2_mask_seg]
    mov es, ax
%else
    mov ax, ds
    mov es, ax
%endif
    cld
    mov word [mask_y], 0
.row:
    mov ax, [mask_y]
    shl ax, 1
    mov si, ax
    mov ax, [mask_scan_left+si]
    mov bx, [mask_scan_right+si]
    cmp ax, bx
    ja .advance
    mov [mask_span_left], ax
    mov [mask_span_right], bx
    mov ax, [mask_y]
%ifdef XDEMO2
    mov bx, MESH_MASK_W/8
    mul bx
%else
    shl ax, 4
    add ax, mesh_mask_ram
%endif
    mov [mask_row_offset], ax
    mov ax, [mask_span_left]
    mov bx, ax
    and bx, 7
    mov dl, [mask_first_bits+bx]
    shr ax, 3
    mov [mask_first_byte], ax
    mov ax, [mask_span_right]
    mov bx, ax
    and bx, 7
    mov dh, [mask_last_bits+bx]
    shr ax, 3
    mov [mask_last_byte], ax
    mov di, [mask_row_offset]
    add di, [mask_first_byte]
    cmp ax, [mask_first_byte]
    je .single_byte
    mov al, dl
    stosb
    mov cx, [mask_last_byte]
    sub cx, [mask_first_byte]
    dec cx
    mov al, 0xff
    rep stosb
    mov al, dh
    stosb
    jmp .advance
.single_byte:
    mov al, dl
    and al, dh
    stosb
.advance:
    inc word [mask_y]
    mov ax, [mask_y]
    cmp ax, [tri_height]
    jb .row
    pop es
    clc
.done:
    ret

; XGA paints the CPU-generated 1-bit shape from system RAM. Pattern-zero
; pixels retain the destination, so no boundary line is used.
fill_masked_quad:
    mov byte [es:0x48], 3
    mov byte [es:0x49], 5
    movzx eax, byte [fill_color]
    mov [es:0x58], eax
    mov ax, [tri_width]
    mov [es:0x60], ax
    mov ax, [tri_height]
    mov [es:0x62], ax
    mov word [es:0x74], 0
    mov ax, [tri_min_x]
    mov [es:0x78], ax
    mov word [es:0x76], 0
    mov ax, [tri_min_y]
    mov [es:0x7a], ax
    mov dword [es:0x7c], MASKED_SOLID_OP
    call wait_cp
    ret

; Clear only this quad's bounding box in the off-screen 1-bit map, draw
; its four area boundaries with XGA, then fill just that box with Area Fill.
; Bounding both passes prevents a bad edge from extending across the screen.
fill_quad_area:
    ; The fourth edge must close this quad, regardless of the prior fill path.
    mov ax, [tri_x0]
    mov [tri_x4], ax
    mov ax, [tri_y0]
    mov [tri_y4], ax
    call wait_cp
    jc .done
    mov byte [es:0x12], 3
    mov dword [es:0x58], 0
    mov ax, [tri_width]
    mov [es:0x60], ax
    mov ax, [tri_height]
    mov [es:0x62], ax
    mov ax, [tri_min_x]
    mov [es:0x78], ax
    mov ax, [tri_min_y]
    mov [es:0x7a], ax
    mov dword [es:0x7c], 0x08138000
    call wait_cp
    jc .done
    mov byte [es:0x12], 1
    mov byte [es:0x48], 6
    mov byte [line_flags], 0x30
    mov si, tri_x0
    mov bp, 4
.edge:
    mov ax, [si]
    mov dx, [si+2]
    mov bx, [si+4]
    mov cx, [si+6]
    cmp ax, bx
    jne .draw_edge
    cmp dx, cx
    je .next_edge              ; pointed facets have one zero-length side
.draw_edge:
    call draw_line
    jc .done
.next_edge:
    add si, 4
    dec bp
    jnz .edge
    mov byte [line_flags], 0
    mov byte [es:0x48], 3
    movzx eax, byte [fill_color]
    mov [es:0x58], eax
    mov ax, [tri_width]
    mov [es:0x60], ax
    mov ax, [tri_height]
    mov [es:0x62], ax
    mov ax, [tri_min_x]
    mov [es:0x70], ax
    mov [es:0x74], ax
    mov [es:0x78], ax
    mov ax, [tri_min_y]
    mov [es:0x72], ax
    mov [es:0x76], ax
    mov [es:0x7a], ax
    mov dword [es:0x7c], AREA_FILL_OP
    call wait_cp
.done:
    mov byte [line_flags], 0
    ret

; Rotate the selected precomputed mesh around Y and X and project it.
; Z remains in torus_screen_z for the painter's-order sort.
project_torus:
    mov ax, [rotation]
    and ax, 255
    mov bx, ax
    movsx ax, byte [sine_table+bx]
    mov [torus_sin_y], ax
    add bx, 64
    and bx, 255
    movsx ax, byte [sine_table+bx]
    mov [torus_cos_y], ax
    mov ax, [rotation]
    shr ax, 1
    add ax, 32
    and ax, 255
    mov bx, ax
    movsx ax, byte [sine_table+bx]
    mov [torus_sin_x], ax
    add bx, 64
    and bx, 255
    movsx ax, byte [sine_table+bx]
    mov [torus_cos_x], ax
    mov word [mesh_vertex_index], 0
.vertex:
    mov si, [mesh_vertex_index]
    mov bx, si
    shl bx, 1
    mov di, bx
    shl bx, 1
    add bx, di                  ; six bytes per model vertex
    mov si, [mesh_vertices]
    add si, bx
    mov ax, [si]
    mov [tmp_x], ax
    mov ax, [si+2]
    mov [tmp_y], ax
    mov ax, [si+4]
    mov [tmp_z], ax
    mov ax, [tmp_x]
    imul word [torus_cos_y]
    sar ax, 7
    mov [tmp1], ax
    mov ax, [tmp_z]
    imul word [torus_sin_y]
    sar ax, 7
    sub [tmp1], ax
    mov ax, [tmp1]
    add ax, [mesh_center_x]
    mov [torus_screen_x+di], ax
    mov ax, [tmp_x]
    imul word [torus_sin_y]
    sar ax, 7
    mov [tmp2], ax
    mov ax, [tmp_z]
    imul word [torus_cos_y]
    sar ax, 7
    add ax, [tmp2]
    mov [tmp_zrot], ax
    mov ax, [tmp_y]
    imul word [torus_cos_x]
    sar ax, 7
    mov [tmp2], ax
    mov ax, [tmp_zrot]
    imul word [torus_sin_x]
    sar ax, 7
    sub [tmp2], ax
    mov ax, [mesh_center_y]
    sub ax, [tmp2]
    mov [torus_screen_y+di], ax
    mov ax, [tmp_y]
    imul word [torus_sin_x]
    sar ax, 7
    mov [tmp1], ax
    mov ax, [tmp_zrot]
    imul word [torus_cos_x]
    sar ax, 7
    add ax, [tmp1]
    mov [torus_screen_z+di], ax
    inc word [mesh_vertex_index]
    mov si, [mesh_vertex_index]
    cmp si, [mesh_vertex_count]
    jb .vertex
    ret

; Average the four rotated Z values of each small quad.
build_torus_depth:
    xor bx, bx
.quad:
    mov si, bx
    shl si, 2
    add si, bx                  ; five bytes per quad
    add si, [mesh_quads]
    movzx di, byte [si]
    shl di, 1
    mov ax, [torus_screen_z+di]
    movzx di, byte [si+1]
    shl di, 1
    add ax, [torus_screen_z+di]
    movzx di, byte [si+2]
    shl di, 1
    add ax, [torus_screen_z+di]
    movzx di, byte [si+3]
    shl di, 1
    add ax, [torus_screen_z+di]
    mov di, bx
    shl di, 1
    mov [torus_depth+di], ax
    inc bx
    cmp bx, [mesh_quad_count]
    jb .quad
    ret

; Insertion sort farthest first. Retaining last frame's order saves work as
; each mesh moves only a small angle between frames.
sort_torus_quads:
    mov si, 1
.next:
    mov al, [torus_order+si]
    mov [torus_key], al
    movzx bx, al
    shl bx, 1
    mov ax, [torus_depth+bx]
    mov [torus_key_depth], ax
    mov bx, si
.shift:
    or bx, bx
    jz .insert
    mov di, bx
    dec di
    movzx ax, byte [torus_order+di]
    shl ax, 1
    mov di, ax
    mov ax, [torus_depth+di]
    cmp ax, [torus_key_depth]
    jle .insert
    mov di, bx
    dec di
    mov al, [torus_order+di]
    mov [torus_order+bx], al
    dec bx
    jmp .shift
.insert:
    mov al, [torus_key]
    mov [torus_order+bx], al
    inc si
    cmp si, [mesh_quad_count]
    jb .next
    ret

rotation dw 0
stress_count dw 64
stress_index dw 0
stress_cell dw 0
stress_x0 dw 0
stress_x1 dw 0
stress_xmid dw 0
stress_y0 dw 0
stress_y1 dw 0
stress_ymid dw 0
torus_pos db 0
mesh_drawn dw 0
mesh_vertices dw torus_vertices
mesh_quads dw torus_quads
mesh_quad_count dw TORUS_QUADS
mesh_vertex_count dw TORUS_VERTS
mesh_vertex_index dw 0
mesh_center_x dw 320
mesh_center_y dw 240
boing_x dw 320
boing_y dw 300
boing_dx dw 5
boing_frame dw 0
speaker_frames db 0
speaker_divisor dw 1800
grid_index dw 0
grid_top_x dw 0
floor_rows dw 100,342,538, 62,358,576, 16,380,616
shadow_row dw 0
shadow_half dw 0
shadow_shrink dw 0
shadow_widths dw 24,32,38,42,44,42,38,32,24
torus_quad_offset dw 0
torus_key db 0
torus_key_depth dw 0
torus_sin_y dw 0
torus_cos_y dw 0
torus_sin_x dw 0
torus_cos_x dw 0
tri_a db 0
tri_b db 0
tri_c db 0
tri_d db 0
tri_x0 dw 0
tri_y0 dw 0
tri_x1 dw 0
tri_y1 dw 0
tri_x2 dw 0
tri_y2 dw 0
tri_x3 dw 0
tri_y3 dw 0
tri_x4 dw 0
tri_y4 dw 0
tri_dx1 dw 0
tri_dy1 dw 0
tri_dx2 dw 0
tri_dy2 dw 0
tri_dx3 dw 0
tri_dy3 dw 0
tri_cross dw 0
quad_cross2 dw 0
tri_min_x dw 0
tri_max_x dw 0
tri_min_y dw 0
tri_max_y dw 0
tri_width dw 0
tri_height dw 0
mask_y dw 0
mask_row_offset dw 0
mask_span_left dw 0
mask_span_right dw 0
mask_first_byte dw 0
mask_last_byte dw 0
mask_clear_bytes dw 0
mesh_area_mode db 1
mesh_map_ram db 0
mesh_quad_index db 0
mesh_area_table dw torus_area_unsafe
draw_page_base dd BACK_BASE
edge_y dw 0
edge_end_y dw 0
edge_top_x dw 0
edge_x_fp dd 0
edge_slope dd 0
mask_scan_left times MESH_MASK_H dw 0
mask_scan_right times MESH_MASK_H dw 0
mask_first_bits db 0xff,0xfe,0xfc,0xf8,0xf0,0xe0,0xc0,0x80
mask_last_bits db 0x01,0x03,0x07,0x0f,0x1f,0x3f,0x7f,0xff
torus_screen_x times TORUS_VERTS dw 0
torus_screen_y times TORUS_VERTS dw 0
torus_screen_z times TORUS_VERTS dw 0
torus_depth times TORUS_QUADS dw 0
cube_sin_y dw 0
cube_cos_y dw 0
cube_sin_x dw 0
cube_cos_x dw 0
demo_mode db 0
vsync_enabled db 1
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
vsync_wait_start dw 0
line_octant db 0
line_flags db 0
line_color db 1
fill_color db 2
visible_balls dw 12
hud_count_label db 16
effect db 0
mask_enabled db 0
background_mode db 0
vector_palette db 0,0,0, 63,63,63, 63,0,0, 0,63,0, 0,0,63, 63,63,0, 0,63,63, 63,0,63, 63,32,0, 32,32,32
               db 38,0,38, 40,40,40
               db 0,0,18, 2,8,35, 6,18,51, 10,35,63, 18,53,63, 40,62,63, 28,19,57, 60,63,63
cube_points dw -80,-80,-80, 80,-80,-80, 80,80,-80, -80,80,-80
             dw -80,-80,80, 80,-80,80, 80,80,80, -80,80,80
projected_points times 16 dw 0
cube_edges db 0,1, 1,2, 2,3, 3,0, 4,5, 5,6, 6,7, 7,4
            db 0,4, 1,5, 2,6, 3,7
cube_edges_end:
octa_verts dw 100,0,0, -100,0,0, 0,100,0, 0,-100,0, 0,0,100, 0,0,-100
octa_faces db 0,2,4,2, 2,1,4,3, 1,3,4,4, 3,0,4,5, 2,0,5,6, 1,2,5,7, 3,1,5,8, 0,3,5,9
octa_screen_x times 6 dw 0
octa_screen_y times 6 dw 0
octa_rot_z times 6 dw 0
octa_depth times 8 dw 0
octa_order db 0,1,2,3,4,5,6,7
solid_pos db 0
rot_sin dw 0
rot_cos dw 0
tmp_x dw 0
tmp_y dw 0
tmp_z dw 0
tmp_zrot dw 0
tmp1 dw 0
tmp2 dw 0
%include "xga_torus_mesh.inc"
%include "xga_boing_mesh.inc"
%include "xga_crystal_mesh.inc"
%include "xga_area_safety.inc"
boing_bounce:
    dw 0,13,25,37,50,62,74,86,98,109,120,131,142,152,162,171
    dw 180,189,197,205,212,219,225,231,236,240,244,247,250,252,254,255
    dw 255,255,254,252,250,247,244,240,236,231,225,219,212,205,197,189
    dw 180,171,162,152,142,131,120,109,98,86,74,62,50,37,25,13
%include "xga_balls_sine.inc"
msg_start db 'XGA Vector: 1 cube, 2 solid, 3 polygons, 4 torus, 5 Boing, 6 crystal, +/- count, M fill, Space, V, Esc',13,10,'$'
msg_no_xga db 'XGA-1/XGA-2 not found on MCA.',13,10,'$'
msg_no_aperture db 'No XGA memory aperture in POS.',13,10,'$'
msg_no_vram db 'XGA 1 MB VRAM banks are not accessible.',13,10,'$'
msg_cp_timeout db 'XGA coprocessor timeout.',13,10,'$'
%include "xga_mode_640.inc"
%include "xga_balls_runtime.inc"
%include "xga_balls_hud.inc"
%ifndef XDEMO2
mesh_mask_ram times MESH_MASK_W*MESH_MASK_H/8 db 0
%else
mesh_mask_ram:
%endif
%ifdef XDEMO
%include "xdemo_art.inc"
%endif
%ifdef XDEMO2
xdemo2_stack times 1024 db 0
xdemo2_stack_top:
%endif
