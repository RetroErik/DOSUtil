; ============================================================================
; DEDIT.COM - full-screen DESCRIPT.ION editor for DOS
; Version 1.0
; By Dag Erik Hagesæter / Retro Erik using Codex in VS Code
;
; NASM: nasm -f bin dedit.asm -o DEDIT.COM
; Target: DOS 2.0+, 8086/8088, 80-column text mode
; ============================================================================

                bits    16
                org     100h
                jmp     main

MAX_ENTRIES     equ     400
ENTRY_SIZE      equ     19
E_NAME          equ     0
E_ATTR          equ     13
E_FLAGS         equ     14
E_DESC_OFS      equ     15
E_DESC_LEN      equ     17
F_MISSING       equ     01h
F_HASLINE       equ     02h
DESC_NONE       equ     0FFFFh
POOL_SIZE       equ     24576
EDIT_MAX        equ     240
ROWS_VISIBLE    equ     20
DESCRIPTION_COL equ    23              ; matches DES: 57 visible columns on an 80-column screen
COLORDIR_LEN    equ     300
MAX_EXT_RULES   equ     64
EXT_RULE_SIZE   equ     5

program_name    db      'DEDIT 1.0 - DESCRIPT.ION Editor',0
copyright       db      'Copyright (C) 2026 Dag Erik Hages',91h,'ter / Retro Erik',0
credit_plain    db      'By Dag Erik Hages',91h,'ter / Retro Erik using Codex in VS Code',0
credit_prefix   db      'By Dag Erik Hages',91h,'ter / ',0
credit_retro    db      'Retro Erik',0
credit_suffix   db      ' using Codex in VS Code',0
credit_colors   db      0Ch,0Eh,0Ah,0Bh,0Dh,0Dh,09h,0Ch,0Eh,0Ah
help1           db      'Usage: DEDIT [directory]',0
help2           db      'Edits 4DOS-compatible DESCRIPT.ION files.',0
help3           db      'Enter/F2 Edit   F4 Copy   F5 Paste   Del Clear',0
help4           db      'Ctrl+S/F10 Save   Esc Quit   F1 Help',0
bad_mode_msg    db      'DEDIT requires an 80-column text screen.',13,10,'$'
too_many_msg    db      'Too many directory or description entries (maximum 400).',13,10,'$'
too_large_msg   db      'DESCRIPT.ION is too large (maximum 24575 bytes).',13,10,'$'
bad_path_msg    db      'Directory not found or invalid path.',13,10,'$'

desc_filename   db      'DESCRIPT.ION',0
bak_filename    db      'DESCRIPT.BAK',0
tmp_filename    db      'DESCRIPT.$$$',0
search_suffix   db      '*.*',0
colordir_name   db      'COLORDIR=',0
dirs_keyword    db      'DIRS',0
bri_keyword     db      'BRI',0
color_names     db      'BLA',0,'BLU',0,'GRE',0,'CYA',0,'RED',0,'MAG',0,'BRO',0,'WHI',0,'YEL',0
color_normal    db      00h,01h,02h,03h,04h,05h,06h,07h,0Eh
color_bright    db      08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,0Eh

title_left      db      ' DEDIT - ',0
title_mid       db      '  DESCRIPT.ION  ',0
column_header   db      ' NAME         TYPE  HS DESCRIPTION',0
missing_text    db      'MISSING',0
dir_text        db      '<DIR>',0
file_text       db      'FILE',0
hidden_text     db      'H',0
system_text     db      'S',0
blank_text      db      '(no description)',0
keys_text       db      ' Enter/F2 Edit  F4 Copy  F5 Paste  Del Clear  F10 Save  F1 Help  Esc Quit ',0
saved_text      db      'Saved DESCRIPT.ION (previous file is DESCRIPT.BAK)',0
changed_text    db      'Modified - Ctrl+S or F10 saves',0
ready_text      db      'Ready',0
copied_text     db      'Description copied',0
pasted_text     db      'Description pasted',0
cleared_text    db      'Description cleared',0
empty_clip_text db      'Copy a description first',0
pool_full_text  db      'Description memory is full; save and restart DEDIT',0
save_fail_text  db      'SAVE FAILED - original file was left intact',0
edit_prompt     db      'Edit description (Enter accepts, Esc cancels):',0
quit_prompt     db      'Unsaved changes. Save before quitting?  Y=save  N=discard  Esc=cancel',0
help_title      db      ' DEDIT Help ',0
help_l1         db      'DEDIT displays every file and directory, even when it has no description.',0
help_l2         db      'H and S mark hidden/system entries; stale descriptions show MISSING.',0
help_l3         db      'Descriptions use:  FILENAME.EXT description text',0
help_l4         db      'Up/Down/PgUp/PgDn/Home/End move through the list.',0
help_l5         db      'Enter or F2 edits.  F4 copies.  F5 pastes.  Del clears.',0
help_l6         db      'Ctrl+S or F10 saves.  A DESCRIPT.BAK backup is made.',0
help_l7         db      'Colors come from the same COLORDIR rules used by DES and 4DOS.',0
help_l8         db      'Press any key to return.',0

entry_count     dw      0
selected        dw      0
top_index       dw      0
dirty           db      0
status_ptr      dw      ready_text
pool_used       dw      0
clip_len        dw      0
ambient_attr    db      07h
video_segment   dw      0B800h
old_cursor      dw      0607h
colordir_active db      0
dirs_found      db      0
dirs_color      db      07h
ext_rule_count  dw      0
base_len        dw      0

; ColorDir parser temporaries.
rule_start      dw      0
rule_end        dw      0
keys_start      dw      0
keys_end        dw      0
cs_start        dw      0
cs_end          dw      0
parsed_color    db      0
parsed_valid    db      0
bri_flag        db      0

; UI/edit temporaries.
draw_row        db      0
draw_col        db      0
draw_attr       db      0
current_index   dw      0
edit_len        dw      0
edit_pos        dw      0
edit_view       dw      0
save_handle     dw      0
load_handle     dw      0
fatal_error     db      0               ; 1=too many entries, 2=file too large
one_byte        db      0
sort_passes     dw      0
color_index     dw      0

main:
                cld
                push    cs
                pop     ds
                push    cs
                pop     es
                call    parse_command_line
                jc      show_help_and_exit
                call    detect_video
                jc      bad_mode_exit
                call    read_ambient
                call    save_cursor_shape
                call    hide_cursor
                call    find_colordir
                call    parse_colordir
                call    collect_directory
                jc      path_error_exit
                call    load_descriptions
                cmp     byte [fatal_error],0
                jne     path_error_exit
                call    sort_entries
                cmp     word [entry_count],0
                jne     .have_entry
                mov     word [selected],0
.have_entry:
                call    editor_loop
                call    restore_cursor
                call    clear_screen
                mov     ax,4C00h
                int     21h

show_help_and_exit:
                mov     si,program_name
                call    print_dos_line
                mov     si,copyright
                call    print_dos_line
                mov     si,credit_plain
                call    print_dos_line
                mov     si,help1
                call    print_dos_line
                mov     si,help2
                call    print_dos_line
                mov     si,help3
                call    print_dos_line
                mov     si,help4
                call    print_dos_line
                mov     ax,4C00h
                int     21h

bad_mode_exit:
                mov     dx,bad_mode_msg
                mov     ah,09h
                int     21h
                mov     ax,4C01h
                int     21h

path_error_exit:
                call    restore_cursor
                call    clear_screen
                mov     dx,bad_path_msg
                cmp     byte [fatal_error],1
                jne     .check_large
                mov     dx,too_many_msg
                jmp     .print
.check_large:
                cmp     byte [fatal_error],2
                jne     .print
                mov     dx,too_large_msg
.print:
                mov     ah,09h
                int     21h
                mov     ax,4C01h
                int     21h

; CF set means help was requested.
parse_command_line:
                mov     si,81h
                xor     cx,cx
                mov     cl,[80h]
.skip_left:
                cmp     cx,0
                je      .current
                cmp     byte [si],' '
                jne     .check_help
                inc     si
                dec     cx
                jmp     .skip_left
.check_help:
                cmp     cx,2
                jne     .copy
                cmp     byte [si],'/'
                jne     .copy
                mov     al,[si+1]
                and     al,0DFh
                cmp     al,'H'
                je      .help
                cmp     byte [si+1],'?'
                je      .help
.copy:
                mov     di,base_path
                xor     bx,bx
.copy_loop:
                cmp     cx,0
                je      .trim
                lodsb
                dec     cx
                cmp     bx,119
                jae     .copy_loop
                stosb
                inc     bx
                jmp     .copy_loop
.trim:
                cmp     bx,0
                je      .terminate
                cmp     byte [di-1],' '
                jne     .terminate
                dec     di
                dec     bx
                jmp     .trim
.terminate:
                mov     byte [di],0
                mov     [base_len],bx
                clc
                ret
.current:
                mov     byte [base_path],0
                mov     word [base_len],0
                clc
                ret
.help:
                stc
                ret

; Builds base\name into path_buf. SI points to ASCIZ name.
build_path:
                push    ax
                push    bx
                push    si
                push    di
                mov     di,path_buf
                mov     bx,[base_len]
                cmp     bx,0
                je      .copy_name
                push    si
                mov     si,base_path
.base_loop:
                lodsb
                or      al,al
                jz      .base_done
                stosb
                jmp     .base_loop
.base_done:
                pop     si
                mov     al,[di-1]
                cmp     al,'\'
                je      .copy_name
                cmp     al,'/'
                je      .copy_name
                cmp     al,':'
                je      .copy_name
                mov     al,'\'
                stosb
.copy_name:
                lodsb
                stosb
                or      al,al
                jnz     .copy_name
                pop     di
                pop     si
                pop     bx
                pop     ax
                ret

detect_video:
                mov     ah,0Fh
                int     10h
                cmp     ah,80
                jne     .bad
                cmp     bh,0
                jne     .bad
                cmp     al,7
                je      .mono
                cmp     al,2
                je      .color
                cmp     al,3
                je      .color
.bad:
                stc
                ret
.mono:
                mov     word [video_segment],0B000h
                clc
                ret
.color:
                mov     word [video_segment],0B800h
                clc
                ret

read_ambient:
                xor     bh,bh
                mov     ah,08h
                int     10h
                mov     [ambient_attr],ah
                ret

save_cursor_shape:
                xor     bh,bh
                mov     ah,03h
                int     10h
                mov     [old_cursor],cx
                ret

hide_cursor:
                mov     ah,01h
                mov     cx,2000h
                int     10h
                ret

restore_cursor:
                mov     ah,01h
                mov     cx,[old_cursor]
                int     10h
                ret

clear_screen:
                mov     ax,0600h
                mov     bh,[ambient_attr]
                xor     cx,cx
                mov     dx,184Fh
                int     10h
                xor     dx,dx
                mov     ah,02h
                xor     bh,bh
                int     10h
                ret

; DOS console line, SI -> ASCIZ.
print_dos_line:
                lodsb
                or      al,al
                jz      .newline
                mov     dl,al
                mov     ah,02h
                int     21h
                jmp     print_dos_line
.newline:
                mov     dl,13
                mov     ah,02h
                int     21h
                mov     dl,10
                int     21h
                ret

; ---------------------------------------------------------------------------
; Directory collection
; ---------------------------------------------------------------------------
collect_directory:
                mov     byte [fatal_error],0
                mov     si,search_suffix
                call    build_path
                mov     dx,our_dta
                mov     ah,1Ah
                int     21h
                mov     dx,path_buf
                mov     cx,37h          ; read-only, hidden, system, directory, archive
                mov     ah,4Eh
                int     21h
                jc      .first_failed
.next_item:
                mov     al,[our_dta+15h]
                test    al,08h
                jnz     .find_next
                mov     si,our_dta+1Eh
                cmp     byte [si],'.'
                jne     .not_dot
                cmp     byte [si+1],0
                je      .find_next
                cmp     byte [si+1],'.'
                jne     .not_dot
                cmp     byte [si+2],0
                je      .find_next
.not_dot:
                mov     di,desc_filename
                call    str_ieq
                je      .find_next
                mov     si,our_dta+1Eh
                mov     di,bak_filename
                call    str_ieq
                je      .find_next
                mov     si,our_dta+1Eh
                mov     di,tmp_filename
                call    str_ieq
                je      .find_next
                cmp     word [entry_count],MAX_ENTRIES
                jae     .overflow
                call    append_dta_entry
.find_next:
                mov     ah,4Fh
                int     21h
                jnc     .next_item
                clc
                ret
.first_failed:
                cmp     ax,2
                je      .empty_ok
                cmp     ax,18
                je      .empty_ok
                stc
                ret
.empty_ok:
                clc
                ret
.overflow:
                mov     byte [fatal_error],1
                stc
                ret

append_dta_entry:
                call    new_entry_ptr
                mov     bx,di
                mov     cx,ENTRY_SIZE
                xor     al,al
                rep     stosb
                mov     di,bx
                mov     si,our_dta+1Eh
                mov     cx,13
.name:
                lodsb
                stosb
                or      al,al
                jz      .name_done
                loop    .name
.name_done:
                mov     al,[our_dta+15h]
                mov     [bx+E_ATTR],al
                mov     byte [bx+E_FLAGS],0
                mov     word [bx+E_DESC_OFS],DESC_NONE
                mov     word [bx+E_DESC_LEN],0
                inc     word [entry_count]
                ret

; AX = entry_count*ENTRY_SIZE, DI = entry pointer. Does not increment count.
new_entry_ptr:
                mov     ax,[entry_count]
                mov     bx,ENTRY_SIZE
                mul     bx
                mov     di,entries
                add     di,ax
                ret

; ---------------------------------------------------------------------------
; DESCRIPT.ION loading and merging
; ---------------------------------------------------------------------------
load_descriptions:
                mov     word [pool_used],0
                mov     si,desc_filename
                call    build_path
                mov     dx,path_buf
                mov     ax,3D00h
                int     21h
                jc      .done
                mov     bx,ax
                mov     [load_handle],ax
                mov     dx,desc_pool
                mov     cx,POOL_SIZE-1
                mov     ah,3Fh
                int     21h
                jc      .close
                mov     [pool_used],ax
                cmp     ax,POOL_SIZE-1
                jne     .terminate
                mov     dx,one_byte
                mov     cx,1
                mov     bx,[load_handle]
                mov     ah,3Fh
                int     21h
                jc      .close
                cmp     ax,0
                je      .terminate
                mov     byte [fatal_error],2
                jmp     .close
.terminate:
                mov     si,desc_pool
                add     si,[pool_used]
                mov     byte [si],0
                call    parse_description_lines
.close:
                mov     bx,[load_handle]
                mov     ah,3Eh
                int     21h
.done:
                ret

parse_description_lines:
                xor     si,si                   ; pool-relative input position
.line_loop:
                cmp     si,[pool_used]
                jae     .done
                mov     bx,si                   ; BX = line start
.find_end:
                cmp     si,[pool_used]
                jae     .at_end
                mov     al,[desc_pool+si]
                cmp     al,13
                je      .line_end
                cmp     al,10
                je      .line_end
                inc     si
                jmp     .find_end
.line_end:
                mov     byte [desc_pool+si],0
                inc     si
                cmp     si,[pool_used]
                jae     .parse
                cmp     byte [desc_pool+si],10
                jne     .parse
                mov     byte [desc_pool+si],0
                inc     si
                jmp     .parse
.at_end:
                mov     byte [desc_pool+si],0
.parse:
                push    si
                mov     si,bx
                call    parse_one_description_line
                pop     si
                jmp     .line_loop
.done:
                ret

; SI is a pool-relative, zero-terminated line.
parse_one_description_line:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                mov     bx,si
.skip_lead:
                mov     al,[desc_pool+si]
                cmp     al,' '
                je      .lead_next
                cmp     al,9
                jne     .name_start
.lead_next:
                inc     si
                jmp     .skip_lead
.name_start:
                cmp     al,0
                je      .out
                mov     bx,si
                mov     di,temp_name
                xor     cx,cx
.copy_name:
                mov     al,[desc_pool+si]
                cmp     al,0
                je      .name_done
                cmp     al,' '
                je      .name_done
                cmp     al,9
                je      .name_done
                cmp     cx,12
                jae     .skip_name_char
                mov     [di],al
                inc     di
                inc     cx
.skip_name_char:
                inc     si
                jmp     .copy_name
.name_done:
                mov     byte [di],0
.skip_gap:
                mov     al,[desc_pool+si]
                cmp     al,' '
                je      .gap_next
                cmp     al,9
                jne     .desc_start
.gap_next:
                inc     si
                jmp     .skip_gap
.desc_start:
                mov     dx,si                   ; description pool offset
                xor     cx,cx
.desc_len:
                cmp     byte [desc_pool+si],0
                je      .have_len
                inc     si
                inc     cx
                jmp     .desc_len
.have_len:
                mov     si,temp_name
                call    find_entry_by_name
                jnc     .attach
                cmp     word [entry_count],MAX_ENTRIES
                jb      .space_for_missing
                mov     byte [fatal_error],1
                jmp     .out
.space_for_missing:
                push    dx
                push    cx
                call    new_entry_ptr
                mov     bx,di
                push    di
                mov     cx,ENTRY_SIZE
                xor     al,al
                rep     stosb
                pop     di
                mov     si,temp_name
                mov     cx,13
.copy_missing_name:
                lodsb
                stosb
                or      al,al
                jz      .missing_name_done
                loop    .copy_missing_name
.missing_name_done:
                pop     cx
                pop     dx
                mov     byte [bx+E_FLAGS],F_MISSING
                mov     word [bx+E_DESC_OFS],DESC_NONE
                inc     word [entry_count]
                mov     di,bx
.attach:
                or      byte [di+E_FLAGS],F_HASLINE
                mov     [di+E_DESC_OFS],dx
                mov     [di+E_DESC_LEN],cx
.out:
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret

; SI -> name. Returns DI entry pointer, CF clear on match.
find_entry_by_name:
                push    ax
                push    bx
                push    cx
                push    si
                xor     bx,bx
                mov     di,entries
.loop:
                cmp     bx,[entry_count]
                jae     .not_found
                push    si
                push    di
                call    str_ieq
                pop     di
                pop     si
                je      .found
                add     di,ENTRY_SIZE
                inc     bx
                jmp     .loop
.found:
                pop     si
                pop     cx
                pop     bx
                pop     ax
                clc
                ret
.not_found:
                pop     si
                pop     cx
                pop     bx
                pop     ax
                stc
                ret

; ---------------------------------------------------------------------------
; Sorting: real directories, real files, then missing entries; names within.
; ---------------------------------------------------------------------------
sort_entries:
                mov     ax,[entry_count]
                cmp     ax,2
                jb      .done
                dec     ax
                mov     [sort_passes],ax
.outer:
                xor     bx,bx
                mov     si,entries
.inner:
                mov     ax,[entry_count]
                dec     ax
                cmp     bx,ax
                jae     .next_pass
                mov     di,si
                add     di,ENTRY_SIZE
                call    compare_entries
                jbe     .no_swap
                push    bx
                push    si
                push    di
                mov     bx,si
                mov     dx,di
                mov     di,swap_buf
                mov     cx,ENTRY_SIZE
                rep     movsb
                mov     si,dx
                mov     di,bx
                mov     cx,ENTRY_SIZE
                rep     movsb
                mov     si,swap_buf
                mov     di,dx
                mov     cx,ENTRY_SIZE
                rep     movsb
                pop     di
                pop     si
                pop     bx
.no_swap:
                add     si,ENTRY_SIZE
                inc     bx
                jmp     .inner
.next_pass:
                dec     word [sort_passes]
                jnz     .outer
.done:
                ret

; SI first, DI second. Returns flags as unsigned ordering (CF/ZF usable by JBE).
compare_entries:
                push    ax
                push    bx
                mov     al,[si+E_FLAGS]
                and     al,F_MISSING
                mov     ah,[di+E_FLAGS]
                and     ah,F_MISSING
                cmp     al,ah
                jne     .result
                or      al,al
                jnz     .names
                mov     al,[si+E_ATTR]
                and     al,10h
                mov     ah,[di+E_ATTR]
                and     ah,10h
                cmp     al,ah
                je      .names
                cmp     al,0
                jne     .first_before
                mov     al,1
                cmp     al,0
                jmp     .result
.first_before:
                xor     al,al
                cmp     al,1
                jmp     .result
.names:
                push    si
                push    di
.name_loop:
                mov     al,[si]
                mov     ah,[di]
                call    upper_al
                xchg    al,ah
                call    upper_al
                xchg    al,ah
                cmp     al,ah
                jne     .name_result
                or      al,al
                jz      .name_result
                inc     si
                inc     di
                jmp     .name_loop
.name_result:
                pop     di
                pop     si
.result:
                pop     bx
                pop     ax
                ret

; ---------------------------------------------------------------------------
; Full-screen editor
; ---------------------------------------------------------------------------
editor_loop:
.redraw:
                call    draw_editor
.key:
                xor     ah,ah
                int     16h
                cmp     al,0
                je      .extended
                cmp     al,13
                je      .edit
                cmp     al,27
                je      .quit
                cmp     al,19                   ; Ctrl+S
                je      .save
                cmp     al,3                    ; Ctrl+C
                je      .copy
                cmp     al,22                   ; Ctrl+V
                je      .paste
                jmp     .key
.extended:
                cmp     ah,48h
                je      .up
                cmp     ah,50h
                je      .down
                cmp     ah,49h
                je      .page_up
                cmp     ah,51h
                je      .page_down
                cmp     ah,47h
                je      .home
                cmp     ah,4Fh
                je      .end
                cmp     ah,3Bh                  ; F1
                je      .help
                cmp     ah,3Ch                  ; F2
                je      .edit
                cmp     ah,3Eh                  ; F4
                je      .copy
                cmp     ah,3Fh                  ; F5
                je      .paste
                cmp     ah,44h                  ; F10
                je      .save
                cmp     ah,53h                  ; Del
                je      .clear
                jmp     .key
.up:
                cmp     word [selected],0
                je      .key
                dec     word [selected]
                call    ensure_visible
                jmp     .redraw
.down:
                mov     ax,[selected]
                inc     ax
                cmp     ax,[entry_count]
                jae     .key
                mov     [selected],ax
                call    ensure_visible
                jmp     .redraw
.page_up:
                mov     ax,[selected]
                cmp     ax,ROWS_VISIBLE
                jb      .home
                sub     ax,ROWS_VISIBLE
                mov     [selected],ax
                call    ensure_visible
                jmp     .redraw
.page_down:
                mov     ax,[selected]
                add     ax,ROWS_VISIBLE
                cmp     ax,[entry_count]
                jb      .set_page_down
                mov     ax,[entry_count]
                or      ax,ax
                jz      .key
                dec     ax
.set_page_down:
                mov     [selected],ax
                call    ensure_visible
                jmp     .redraw
.home:
                mov     word [selected],0
                mov     word [top_index],0
                jmp     .redraw
.end:
                cmp     word [entry_count],0
                je      .key
                mov     ax,[entry_count]
                dec     ax
                mov     [selected],ax
                call    ensure_visible
                jmp     .redraw
.help:
                call    show_help_screen
                jmp     .redraw
.edit:
                cmp     word [entry_count],0
                je      .key
                call    edit_selected
                jmp     .redraw
.copy:
                cmp     word [entry_count],0
                je      .key
                call    copy_selected
                jmp     .redraw
.paste:
                cmp     word [entry_count],0
                je      .key
                call    paste_selected
                jmp     .redraw
.clear:
                cmp     word [entry_count],0
                je      .key
                call    clear_selected
                jmp     .redraw
.save:
                call    save_descriptions
                jmp     .redraw
.quit:
                cmp     byte [dirty],0
                je      .done
                call    confirm_quit
                cmp     al,0                    ; cancel
                je      .redraw
                cmp     al,1                    ; discard
                je      .done
                call    save_descriptions
                cmp     byte [dirty],0
                jne     .redraw
.done:
                ret

ensure_visible:
                mov     ax,[selected]
                cmp     ax,[top_index]
                jae     .check_bottom
                mov     [top_index],ax
                ret
.check_bottom:
                mov     bx,[top_index]
                add     bx,ROWS_VISIBLE
                cmp     ax,bx
                jb      .done
                sub     ax,ROWS_VISIBLE-1
                mov     [top_index],ax
.done:
                ret

entry_ptr_selected:
                mov     ax,[selected]
entry_ptr_ax:
                mov     bx,ENTRY_SIZE
                mul     bx
                mov     si,entries
                add     si,ax
                ret

draw_editor:
                mov     dh,0
                mov     dl,0
                mov     bl,1Fh
                call    fill_row
                mov     si,title_left
                mov     dh,0
                mov     dl,0
                mov     bl,1Fh
                call    draw_string
                mov     si,base_path
                cmp     byte [si],0
                jne     .draw_path
                mov     si,current_dir_text
.draw_path:
                mov     dh,0
                mov     dl,9
                mov     bl,1Fh
                call    draw_string_limited_asciz
                mov     si,title_mid
                mov     dh,0
                mov     dl,62
                mov     bl,1Fh
                call    draw_string
                mov     si,column_header
                mov     dh,1
                mov     dl,0
                mov     bl,[ambient_attr]
                call    fill_row
                mov     si,column_header
                mov     dh,1
                mov     dl,1
                mov     bl,0Fh
                call    draw_string
                xor     bx,bx
.rows:
                cmp     bx,ROWS_VISIBLE
                jae     .footer
                mov     ax,[top_index]
                add     ax,bx
                cmp     ax,[entry_count]
                jb      .draw_row
                push    bx
                mov     ax,bx
                add     al,2
                mov     dh,al
                mov     dl,0
                mov     bl,[ambient_attr]
                call    fill_row
                pop     bx
                jmp     .next_row
.draw_row:
                mov     [current_index],ax
                push    bx
                call    draw_entry_row
                pop     bx
.next_row:
                inc     bx
                jmp     .rows
.footer:
                mov     dh,22
                mov     dl,0
                mov     bl,08h
                call    fill_row
                mov     dh,23
                mov     dl,0
                mov     bl,[ambient_attr]
                call    fill_row
                mov     si,[status_ptr]
                mov     dh,23
                mov     dl,1
                mov     bl,0Eh
                call    draw_string_limited_asciz
                mov     dh,24
                mov     dl,0
                mov     bl,70h
                call    fill_row
                mov     si,keys_text
                mov     dh,24
                mov     dl,0
                mov     bl,70h
                call    draw_string
                ret

current_dir_text db    '.',0

draw_entry_row:
                mov     ax,[current_index]
                call    entry_ptr_ax
                mov     di,si
                mov     al,[si+E_ATTR]
                call    get_entry_color
                mov     [draw_attr],al
                mov     ax,[current_index]
                cmp     ax,[selected]
                jne     .not_selected
                mov     byte [draw_attr],1Fh
.not_selected:
                mov     ax,[current_index]
                sub     ax,[top_index]
                add     al,2
                mov     [draw_row],al
                mov     dh,al
                mov     dl,0
                mov     bl,[draw_attr]
                call    fill_row
                mov     si,di
                mov     dh,[draw_row]
                mov     dl,1
                mov     bl,[draw_attr]
                call    draw_string
                test    byte [di+E_FLAGS],F_MISSING
                jz      .real
                mov     si,missing_text
                mov     bl,4Fh
                mov     ax,[current_index]
                cmp     ax,[selected]
                jne     .missing_color_ok
                mov     bl,1Fh
.missing_color_ok:
                jmp     .type
.real:
                test    byte [di+E_ATTR],10h
                jz      .is_file
                mov     si,dir_text
                jmp     .type
.is_file:
                mov     si,file_text
.type:
                mov     dh,[draw_row]
                mov     dl,14
                call    draw_string
                test    byte [di+E_FLAGS],F_MISSING
                jnz     .attributes_done
                test    byte [di+E_ATTR],02h     ; DOS hidden attribute
                jz      .check_system
                mov     si,hidden_text
                mov     dh,[draw_row]
                mov     dl,20
                mov     bl,[draw_attr]
                call    draw_string
.check_system:
                test    byte [di+E_ATTR],04h     ; DOS system attribute
                jz      .attributes_done
                mov     si,system_text
                mov     dh,[draw_row]
                mov     dl,21
                mov     bl,[draw_attr]
                call    draw_string
.attributes_done:
                mov     ax,[di+E_DESC_OFS]
                cmp     ax,DESC_NONE
                je      .blank
                cmp     word [di+E_DESC_LEN],0
                je      .blank
                mov     si,desc_pool
                add     si,ax
                mov     cx,[di+E_DESC_LEN]
                mov     dh,[draw_row]
                mov     dl,DESCRIPTION_COL
                mov     bl,[draw_attr]
                call    draw_string_len
                ret
.blank:
                mov     si,blank_text
                mov     dh,[draw_row]
                mov     dl,DESCRIPTION_COL
                mov     bl,08h
                mov     ax,[current_index]
                cmp     ax,[selected]
                jne     .blank_color_ok
                mov     bl,1Fh
.blank_color_ok:
                call    draw_string
                ret

show_help_screen:
                call    clear_screen
                mov     dh,0
                mov     dl,0
                mov     bl,1Fh
                call    fill_row
                mov     si,help_title
                mov     dh,0
                mov     dl,33
                mov     bl,1Fh
                call    draw_string
                mov     si,credit_prefix
                mov     dh,1
                mov     dl,8
                mov     bl,[ambient_attr]
                call    draw_string
                mov     si,credit_retro
                mov     dh,1
                mov     dl,32
                call    draw_rainbow_retro
                mov     si,credit_suffix
                mov     dh,1
                mov     dl,42
                mov     bl,[ambient_attr]
                call    draw_string
                mov     si,help_l1
                mov     dh,3
                call    help_line
                mov     si,help_l2
                mov     dh,5
                call    help_line
                mov     si,help_l3
                mov     dh,8
                call    help_line
                mov     si,help_l4
                mov     dh,11
                call    help_line
                mov     si,help_l5
                mov     dh,13
                call    help_line
                mov     si,help_l6
                mov     dh,15
                call    help_line
                mov     si,help_l7
                mov     dh,18
                call    help_line
                mov     si,help_l8
                mov     dh,22
                call    help_line
                xor     ah,ah
                int     16h
                ret
help_line:
                mov     dl,2
                mov     bl,[ambient_attr]
                call    draw_string
                ret

; Draws "Retro Erik" with the same rainbow sequence used by AUTOEXEC.BAT/DES.
; SI string, DH row, DL column.
draw_rainbow_retro:
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    es
                call    screen_offset
                mov     ax,[video_segment]
                mov     es,ax
                mov     bx,credit_colors
                mov     cx,10
.loop:
                lodsb
                mov     ah,[bx]
                stosw
                inc     bx
                loop    .loop
                pop     es
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret

; ---------------------------------------------------------------------------
; Description editing and clipboard
; ---------------------------------------------------------------------------
edit_selected:
                call    entry_ptr_selected
                mov     di,edit_buf
                xor     cx,cx
                mov     ax,[si+E_DESC_OFS]
                cmp     ax,DESC_NONE
                je      .loaded
                mov     bx,[si+E_DESC_LEN]
                cmp     bx,EDIT_MAX
                jbe     .len_ok
                mov     bx,EDIT_MAX
.len_ok:
                mov     cx,bx
                push    si
                mov     si,desc_pool
                add     si,ax
                rep     movsb
                pop     si
                mov     cx,bx
.loaded:
                mov     byte [di],0
                mov     [edit_len],cx
                mov     [edit_pos],cx
                mov     word [edit_view],0
                call    show_edit_prompt
.loop:
                call    draw_edit_line
                xor     ah,ah
                int     16h
                cmp     al,0
                je      .extended
                cmp     al,13
                je      .accept
                cmp     al,27
                je      .cancel
                cmp     al,8
                je      .backspace
                cmp     al,32
                jb      .loop
                cmp     al,126
                ja      .loop
                cmp     word [edit_len],EDIT_MAX
                jae     .loop
                call    insert_edit_char
                jmp     .loop
.extended:
                cmp     ah,4Bh
                je      .left
                cmp     ah,4Dh
                je      .right
                cmp     ah,47h
                je      .home
                cmp     ah,4Fh
                je      .end
                cmp     ah,53h
                je      .delete
                jmp     .loop
.left:
                cmp     word [edit_pos],0
                je      .loop
                dec     word [edit_pos]
                call    adjust_edit_view
                jmp     .loop
.right:
                mov     ax,[edit_pos]
                cmp     ax,[edit_len]
                jae     .loop
                inc     word [edit_pos]
                call    adjust_edit_view
                jmp     .loop
.home:
                mov     word [edit_pos],0
                mov     word [edit_view],0
                jmp     .loop
.end:
                mov     ax,[edit_len]
                mov     [edit_pos],ax
                call    adjust_edit_view
                jmp     .loop
.backspace:
                cmp     word [edit_pos],0
                je      .loop
                dec     word [edit_pos]
                call    delete_edit_char
                call    adjust_edit_view
                jmp     .loop
.delete:
                mov     ax,[edit_pos]
                cmp     ax,[edit_len]
                jae     .loop
                call    delete_edit_char
                jmp     .loop
.accept:
                call    hide_cursor
                call    commit_edit_buffer
                ret
.cancel:
                call    hide_cursor
                ret

show_edit_prompt:
                mov     dh,22
                mov     dl,0
                mov     bl,1Eh
                call    fill_row
                mov     si,edit_prompt
                mov     dh,22
                mov     dl,1
                mov     bl,1Eh
                call    draw_string
                ret

draw_edit_line:
                mov     dh,23
                mov     dl,0
                mov     bl,1Fh
                call    fill_row
                mov     si,edit_buf
                add     si,[edit_view]
                mov     cx,[edit_len]
                sub     cx,[edit_view]
                cmp     cx,78
                jbe     .len_ok
                mov     cx,78
.len_ok:
                mov     dh,23
                mov     dl,1
                mov     bl,1Fh
                call    draw_string_len
                mov     ax,[edit_pos]
                sub     ax,[edit_view]
                inc     al
                mov     dl,al
                mov     dh,23
                xor     bh,bh
                mov     ah,02h
                int     10h
                mov     ah,01h
                mov     cx,[old_cursor]
                int     10h
                ret

adjust_edit_view:
                mov     ax,[edit_pos]
                cmp     ax,[edit_view]
                jae     .right
                mov     [edit_view],ax
                ret
.right:
                mov     bx,[edit_view]
                add     bx,77
                cmp     ax,bx
                jbe     .done
                sub     ax,77
                mov     [edit_view],ax
.done:
                ret

; AL is printable input.
insert_edit_char:
                push    ax
                mov     bx,[edit_len]
                mov     di,edit_buf
                add     di,bx
                inc     di
                mov     cx,bx
                sub     cx,[edit_pos]
                inc     cx                      ; include zero terminator
                std
                mov     si,di
                dec     si
                rep     movsb
                cld
                pop     ax
                mov     di,edit_buf
                add     di,[edit_pos]
                mov     [di],al
                inc     word [edit_pos]
                inc     word [edit_len]
                call    adjust_edit_view
                ret

delete_edit_char:
                mov     si,edit_buf
                add     si,[edit_pos]
                mov     di,si
                inc     si
                mov     cx,[edit_len]
                sub     cx,[edit_pos]
                rep     movsb                   ; includes terminator
                dec     word [edit_len]
                ret

commit_edit_buffer:
                mov     ax,[pool_used]
                mov     bx,[edit_len]
                inc     bx
                add     bx,ax
                cmp     bx,POOL_SIZE
                ja      .full
                mov     di,desc_pool
                add     di,ax
                mov     si,edit_buf
                mov     cx,[edit_len]
                inc     cx
                rep     movsb
                push    ax
                call    entry_ptr_selected
                mov     di,si
                pop     ax
                mov     [di+E_DESC_OFS],ax
                mov     bx,[edit_len]
                mov     [di+E_DESC_LEN],bx
                or      byte [di+E_FLAGS],F_HASLINE
                mov     ax,[pool_used]
                add     ax,bx
                inc     ax
                mov     [pool_used],ax
                mov     byte [dirty],1
                mov     word [status_ptr],changed_text
                ret
.full:
                mov     word [status_ptr],pool_full_text
                ret

copy_selected:
                call    entry_ptr_selected
                mov     ax,[si+E_DESC_OFS]
                cmp     ax,DESC_NONE
                je      .empty
                mov     cx,[si+E_DESC_LEN]
                cmp     cx,EDIT_MAX
                jbe     .copy
                mov     cx,EDIT_MAX
.copy:
                mov     [clip_len],cx
                mov     si,desc_pool
                add     si,ax
                mov     di,clip_buf
                rep     movsb
                mov     byte [di],0
                mov     word [status_ptr],copied_text
                ret
.empty:
                mov     word [clip_len],0
                mov     byte [clip_buf],0
                mov     word [status_ptr],copied_text
                ret

paste_selected:
                cmp     word [clip_len],0
                jne     .have
                mov     word [status_ptr],empty_clip_text
                ret
.have:
                mov     si,clip_buf
                mov     di,edit_buf
                mov     cx,[clip_len]
                rep     movsb
                mov     byte [di],0
                mov     ax,[clip_len]
                mov     [edit_len],ax
                call    commit_edit_buffer
                cmp     word [status_ptr],pool_full_text
                je      .done
                mov     word [status_ptr],pasted_text
.done:
                ret

clear_selected:
                call    entry_ptr_selected
                mov     word [si+E_DESC_OFS],DESC_NONE
                mov     word [si+E_DESC_LEN],0
                and     byte [si+E_FLAGS],0FDh
                mov     byte [dirty],1
                mov     word [status_ptr],cleared_text
                ret

confirm_quit:
                mov     dh,23
                mov     dl,0
                mov     bl,4Fh
                call    fill_row
                mov     si,quit_prompt
                mov     dh,23
                mov     dl,1
                mov     bl,4Fh
                call    draw_string
.key:
                xor     ah,ah
                int     16h
                cmp     al,27
                je      .cancel
                and     al,0DFh
                cmp     al,'N'
                je      .discard
                cmp     al,'Y'
                jne     .key
                mov     al,2
                ret
.discard:
                mov     al,1
                ret
.cancel:
                xor     al,al
                ret

; ---------------------------------------------------------------------------
; Safe save: write temporary file, rotate original to BAK, rename temporary.
; ---------------------------------------------------------------------------
save_descriptions:
                call    prepare_save_paths
                mov     dx,tmp_path
                xor     cx,cx
                mov     ah,3Ch
                int     21h
                jc      .fail
                mov     [save_handle],ax
                xor     bp,bp
                mov     si,entries
.entry_loop:
                cmp     bp,[entry_count]
                jae     .close_temp
                test    byte [si+E_FLAGS],F_HASLINE
                jz      .next_entry
                push    si
                mov     dx,si
                call    write_asciz
                pop     si
                jc      .write_fail
                cmp     word [si+E_DESC_LEN],0
                je      .newline
                mov     dx,space_byte
                mov     cx,1
                call    write_block
                jc      .write_fail
                mov     dx,desc_pool
                add     dx,[si+E_DESC_OFS]
                mov     cx,[si+E_DESC_LEN]
                call    write_block
                jc      .write_fail
.newline:
                mov     dx,crlf_bytes
                mov     cx,2
                call    write_block
                jc      .write_fail
.next_entry:
                add     si,ENTRY_SIZE
                inc     bp
                jmp     .entry_loop
.close_temp:
                mov     bx,[save_handle]
                mov     ah,3Eh
                int     21h
                jc      .delete_temp_fail

                ; Remove the prior backup, then rename current file to backup.
                mov     dx,bak_path
                mov     ah,41h
                int     21h
                push    ds
                pop     es
                mov     dx,desc_path
                mov     di,bak_path
                mov     ah,56h
                int     21h                      ; error is OK when no original exists

                ; Put completed temporary file in place.
                mov     dx,tmp_path
                mov     di,desc_path
                mov     ah,56h
                int     21h
                jc      .restore_backup
                mov     byte [dirty],0
                mov     word [status_ptr],saved_text
                ret
.restore_backup:
                mov     dx,bak_path
                mov     di,desc_path
                mov     ah,56h
                int     21h
                jmp     .fail
.write_fail:
                mov     bx,[save_handle]
                mov     ah,3Eh
                int     21h
.delete_temp_fail:
                mov     dx,tmp_path
                mov     ah,41h
                int     21h
.fail:
                mov     word [status_ptr],save_fail_text
                ret

prepare_save_paths:
                mov     si,desc_filename
                call    build_path
                mov     si,path_buf
                mov     di,desc_path
                call    strcpy
                mov     si,bak_filename
                call    build_path
                mov     si,path_buf
                mov     di,bak_path
                call    strcpy
                mov     si,tmp_filename
                call    build_path
                mov     si,path_buf
                mov     di,tmp_path
                call    strcpy
                ret

; DX points to ASCIZ. Writes to save_handle.
write_asciz:
                push    dx
                push    si
                mov     si,dx
                xor     cx,cx
.count:
                cmp     byte [si],0
                je      .write
                inc     si
                inc     cx
                jmp     .count
.write:
                pop     si
                pop     dx
                jmp     write_block

; DX buffer, CX count. CF set on short/error write.
write_block:
                push    bx
                push    cx
                mov     bx,[save_handle]
                mov     ah,40h
                int     21h
                jc      .bad
                pop     cx
                cmp     ax,cx
                jne     .short
                pop     bx
                clc
                ret
.bad:
                pop     cx
.short:
                pop     bx
                stc
                ret

space_byte      db      ' '
crlf_bytes      db      13,10

; ---------------------------------------------------------------------------
; Screen primitives
; ---------------------------------------------------------------------------
; DH row, DL column, BL attribute. Fills to column 79.
fill_row:
                push    ax
                push    bx
                push    cx
                push    dx
                push    di
                push    es
                call    screen_offset
                mov     ax,[video_segment]
                mov     es,ax
                mov     al,' '
                mov     ah,bl
                xor     ch,ch
                mov     cl,80
                sub     cl,dl
                rep     stosw
                pop     es
                pop     di
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret

; SI ASCIZ, DH/DL position, BL attribute.
draw_string:
                push    cx
                mov     cx,0FFFFh
                call    draw_string_len
                pop     cx
                ret

draw_string_limited_asciz:
                push    cx
                mov     cx,80
                sub     cl,dl
                xor     ch,ch
                call    draw_string_len
                pop     cx
                ret

; SI bytes, CX maximum, DH/DL, BL. Stops at zero or screen edge.
draw_string_len:
                push    ax
                push    bx
                push    cx
                push    dx
                push    di
                push    es
                call    screen_offset
                mov     ax,[video_segment]
                mov     es,ax
.loop:
                cmp     cx,0
                je      .done
                cmp     dl,80
                jae     .done
                lodsb
                or      al,al
                jz      .done
                mov     ah,bl
                stosw
                inc     dl
                dec     cx
                jmp     .loop
.done:
                pop     es
                pop     di
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret

; DH/DL -> DI byte offset in 80-column text buffer.
screen_offset:
                push    ax
                push    bx
                mov     al,dh
                xor     ah,ah
                mov     bl,80
                mul     bl
                xor     bh,bh
                mov     bl,dl
                add     ax,bx
                shl     ax,1
                mov     di,ax
                pop     bx
                pop     ax
                ret

; ---------------------------------------------------------------------------
; COLORDIR support (4DOS/DES syntax)
; ---------------------------------------------------------------------------
find_colordir:
                push    es
                mov     byte [colordir_active],0
                mov     ax,[2Ch]
                mov     es,ax
                xor     di,di
.entry:
                cmp     byte [es:di],0
                je      .done
                mov     si,colordir_name
                call    env_starts_with
                jc      .found
.skip:
                cmp     byte [es:di],0
                je      .next
                inc     di
                jmp     .skip
.next:
                inc     di
                jmp     .entry
.found:
                add     di,9
                mov     si,colordir_buf
                mov     cx,COLORDIR_LEN-1
.copy:
                mov     al,[es:di]
                mov     [si],al
                inc     di
                inc     si
                or      al,al
                jz      .active
                loop    .copy
                mov     byte [si],0
.active:
                mov     byte [colordir_active],1
.done:
                pop     es
                ret

env_starts_with:
                push    ax
                push    bx
                push    si
                push    di
.loop:
                mov     al,[si]
                or      al,al
                jz      .yes
                call    upper_al
                mov     bl,al
                mov     al,[es:di]
                call    upper_al
                cmp     al,bl
                jne     .no
                inc     si
                inc     di
                jmp     .loop
.yes:
                pop     di
                pop     si
                pop     bx
                pop     ax
                stc
                ret
.no:
                pop     di
                pop     si
                pop     bx
                pop     ax
                clc
                ret

parse_colordir:
                mov     word [ext_rule_count],0
                mov     byte [dirs_found],0
                cmp     byte [colordir_active],0
                je      .done
                mov     si,colordir_buf
.rules:
                cmp     byte [si],0
                je      .done
                mov     [rule_start],si
.find_end:
                mov     al,[si]
                cmp     al,0
                je      .end_found
                cmp     al,';'
                je      .end_found
                inc     si
                jmp     .find_end
.end_found:
                mov     [rule_end],si
                push    si
                call    parse_one_color_rule
                pop     si
                cmp     byte [si],';'
                jne     .done
                inc     si
                jmp     .rules
.done:
                ret

parse_one_color_rule:
                mov     si,[rule_start]
.colon:
                cmp     si,[rule_end]
                jae     .done
                cmp     byte [si],':'
                je      .have_colon
                inc     si
                jmp     .colon
.have_colon:
                mov     ax,[rule_start]
                mov     [keys_start],ax
                mov     [keys_end],si
                inc     si
                mov     [cs_start],si
                mov     ax,[rule_end]
                mov     [cs_end],ax
                call    parse_color_spec
                cmp     byte [parsed_valid],0
                je      .done
                call    parse_color_keys
.done:
                ret

parse_color_spec:
                mov     byte [parsed_valid],0
                mov     byte [bri_flag],0
                mov     word [color_index],0FFFFh
                mov     si,[cs_start]
.skip:
                cmp     si,[cs_end]
                jae     .finish
                cmp     byte [si],' '
                jne     .token
                inc     si
                jmp     .skip
.token:
                mov     di,tiny_tok
                mov     cx,8
                xor     al,al
                rep     stosb
                mov     di,tiny_tok
                xor     cx,cx
.copy:
                cmp     si,[cs_end]
                jae     .token_done
                mov     al,[si]
                cmp     al,' '
                je      .token_done
                call    upper_al
                cmp     cx,3
                jae     .no_store
                mov     [di],al
                inc     di
.no_store:
                inc     si
                inc     cx
                jmp     .copy
.token_done:
                push    si
                mov     si,tiny_tok
                mov     di,bri_keyword
                call    str_ieq
                pop     si
                jne     .colors
                mov     byte [bri_flag],1
                jmp     .skip
.colors:
                xor     bx,bx
.color_loop:
                cmp     bx,9
                jae     .skip
                push    si
                mov     ax,bx
                mov     dx,4
                mul     dx
                mov     di,color_names
                add     di,ax
                mov     si,tiny_tok
                call    str_ieq
                pop     si
                je      .color_found
                inc     bx
                jmp     .color_loop
.color_found:
                mov     [color_index],bx
                jmp     .skip
.finish:
                mov     bx,[color_index]
                cmp     bx,0FFFFh
                je      .done
                cmp     byte [bri_flag],0
                jne     .bright
                mov     al,[color_normal+bx]
                jmp     .set
.bright:
                mov     al,[color_bright+bx]
.set:
                mov     [parsed_color],al
                mov     byte [parsed_valid],1
.done:
                ret

parse_color_keys:
                mov     si,[keys_start]
.skip:
                cmp     si,[keys_end]
                jae     .done
                cmp     byte [si],' '
                jne     .token
                inc     si
                jmp     .skip
.token:
                mov     di,key_tok
                mov     cx,8
                xor     al,al
                rep     stosb
                mov     di,key_tok
                xor     cx,cx
.copy:
                cmp     si,[keys_end]
                jae     .token_done
                mov     al,[si]
                cmp     al,' '
                je      .token_done
                call    upper_al
                cmp     cx,7
                jae     .no_store
                mov     [di],al
                inc     di
.no_store:
                inc     si
                inc     cx
                jmp     .copy
.token_done:
                push    si
                mov     si,key_tok
                mov     di,dirs_keyword
                call    str_ieq
                pop     si
                jne     .extension
                mov     al,[parsed_color]
                mov     [dirs_color],al
                mov     byte [dirs_found],1
                jmp     .skip
.extension:
                cmp     word [ext_rule_count],MAX_EXT_RULES
                jae     .skip
                push    si
                mov     ax,[ext_rule_count]
                mov     bx,EXT_RULE_SIZE
                mul     bx
                mov     di,ext_color_table
                add     di,ax
                mov     bx,di
                mov     cx,5
                xor     al,al
                rep     stosb
                mov     di,bx
                mov     si,key_tok
                mov     cx,3
.ext_copy:
                lodsb
                or      al,al
                jz      .ext_done
                stosb
                loop    .ext_copy
.ext_done:
                mov     al,[parsed_color]
                mov     [bx+4],al
                inc     word [ext_rule_count]
                pop     si
                jmp     .skip
.done:
                ret

; SI entry name, AL attributes -> AL color (ambient if unmatched).
get_entry_color:
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                mov     dl,[ambient_attr]
                cmp     byte [colordir_active],0
                je      .ambient
                test    al,10h
                jz      .file
                cmp     byte [dirs_found],0
                je      .ambient
                mov     dl,[dirs_color]
                jmp     .done
.file:
                call    extract_extension
                mov     cx,[ext_rule_count]
                mov     di,ext_color_table
.rules:
                cmp     cx,0
                je      .ambient
                mov     si,ext_tok
                call    str_ieq
                je      .match
                add     di,EXT_RULE_SIZE
                dec     cx
                jmp     .rules
.match:
                mov     dl,[di+4]
.ambient:
.done:
                mov     al,dl
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                ret

extract_extension:
                push    ax
                push    cx
                push    si
                push    di
                mov     di,ext_tok
                mov     cx,4
                xor     al,al
                rep     stosb
.dot:
                mov     al,[si]
                or      al,al
                jz      .done
                cmp     al,'.'
                je      .copy_start
                inc     si
                jmp     .dot
.copy_start:
                inc     si
                mov     di,ext_tok
                mov     cx,3
.copy:
                lodsb
                or      al,al
                jz      .done
                call    upper_al
                stosb
                loop    .copy
.done:
                pop     di
                pop     si
                pop     cx
                pop     ax
                ret

; ---------------------------------------------------------------------------
; String helpers
; ---------------------------------------------------------------------------
upper_al:
                cmp     al,'a'
                jb      .done
                cmp     al,'z'
                ja      .done
                sub     al,20h
.done:
                ret

; Case-insensitive ASCIZ comparison, SI and DI preserved; ZF=1 if equal.
str_ieq:
                push    ax
                push    bx
                push    si
                push    di
.loop:
                mov     al,[si]
                call    upper_al
                mov     bl,al
                mov     al,[di]
                call    upper_al
                cmp     bl,al
                jne     .done
                cmp     bl,0
                je      .done
                inc     si
                inc     di
                jmp     .loop
.done:
                pop     di
                pop     si
                pop     bx
                pop     ax
                ret

; SI source, DI destination.
strcpy:
                lodsb
                stosb
                or      al,al
                jnz     strcpy
                ret

; Runtime storage is deliberately omitted from the COM image. DOS gives a COM
; program the rest of its 64 KiB segment, and every buffer is initialized
; before use.
runtime_buffers equ     $
our_dta         equ     runtime_buffers
base_path       equ     our_dta + 43
path_buf        equ     base_path + 128
desc_path       equ     path_buf + 128
bak_path        equ     desc_path + 128
tmp_path        equ     bak_path + 128
temp_name       equ     tmp_path + 128
swap_buf        equ     temp_name + 13
tiny_tok        equ     swap_buf + ENTRY_SIZE
key_tok         equ     tiny_tok + 8
ext_tok         equ     key_tok + 8
colordir_buf    equ     ext_tok + 4
ext_color_table equ     colordir_buf + COLORDIR_LEN
edit_buf        equ     ext_color_table + (MAX_EXT_RULES * EXT_RULE_SIZE)
clip_buf        equ     edit_buf + EDIT_MAX + 1
entries         equ     clip_buf + EDIT_MAX + 1
desc_pool       equ     entries + (MAX_ENTRIES * ENTRY_SIZE)
runtime_end     equ     desc_pool + POOL_SIZE + 1

%if (runtime_end - $$) >= 0EF00h
    %error "Runtime buffers leave too little stack space"
%endif
