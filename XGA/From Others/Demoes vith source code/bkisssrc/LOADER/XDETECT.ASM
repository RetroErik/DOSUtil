i86       equ 0
i186      equ 1
i286      equ 2
i386sx    equ 3
i386dx    equ 4

NONE      equ 0
MDA       equ 1
CGA       equ 2
EGAMono   equ 3
EGAColor  equ 4
VGAMono   equ 5
VGAColor  equ 6
MCGAMono  equ 7
MCGAColor equ 8

PS2_CARDS db  0,1,2,2,4,3,2,5,6,2,8,7,8

;-----------------------------------------------------------------------
; PC Graphics detection routine. Returns graphics card type
;
; C callable as:
;    unsigned int x_graphics_card();
;
;

proc _x_graphics_card
    mov  ax,1A00h            ; Try calling VGA Identity Adapter function
    int  10h
    cmp  al,1Ah              ; Do we have PS/2 video bios ?
    jne  @@not_PS2           ; No!

    cmp  bl,0Ch              ; bl > 0Ch => CGA hardware
    jg   @@is_CGA            ; Jump if we have CGA
    xor  bh,bh
    xor  ah,ah
    mov  al,[cs:PS2_CARDS+bx] ; Load ax from PS/2 hardware table
    jmp  short @@done        ; return ax
@@is_CGA:
    mov  ax,CGA              ; Have detected CGA, return id
    jmp  short @@done
@@not_PS2:                       ; OK We don't have PS/2 Video bios
    mov  ah,12h              ; Set alternate function service
    mov  bx,10h              ; Set to return EGA information
    int  10h                 ; call video service
    cmp  bx,10h              ; Is EGA there ?
    je   @@simple_adapter    ; Nop!
    mov  ah,12h              ; Since we have EGA bios, get details
    mov  bl,10h
    int  10h
    or   bh,bh               ; Do we have colour EGA ?
    jz   @@ega_color         ; Yes
    mov  ax,EGAMono          ; Otherwise we have Mono EGA
    jmp  short @@done
@@ega_color:
    mov  ax,EGAColor         ; Have detected EGA Color, return id
    jmp  short @@done
@@simple_adapter:
    int  11h                 ; Lets try equipment determination service
    and  al,30h
    shr  al,4
    xor  ah,ah
    or   al,al               ; Do we have any graphics card at all ?
    jz   @@done              ; No ? This is a stupid machine!
    cmp  al,3                ; Do We have a Mono adapter
    jne  @@is_CGA            ; No
    mov  ax,MDA              ; Have detected MDA, return id
@@done:
    ret
endp    _x_graphics_card


;-----------------------------------------------------------------------
; PC Processor detection routine
;
; C callable as:
;    unsigned int x_processor();
;
;
proc _x_processor
        pushf                    ; Save flags

        ;8086 detection
        xor  ax,ax               ; Clear AX
        push ax                  ; Push it on the stack
        popf                     ; Zero the flags
        pushf                    ; Try to zero bits 12-15
        pop  ax                  ; Recover flags
        and  ax,0F000h           ; If bits 12-15 are 1 => i86 or i286
        cmp  ax,0F000h
        jne  @@1

        ;80186 detection
        push cx                  ; save CX
        mov  ax,0FFFFh           ; Set all AX bits
        mov  cl,33               ; Will shift once on 80186
        shl  ax,cl               ; or 33 x on 8086
        pop  cx
        mov  ax,i186
        jnz  @@done
        mov  ax,i86              ; 0 => 8086/8088
        jmp  short @@done

@@1:    ;80286 detection
        mov  ax,07000h           ; Try to set bits 12-14
        push ax
        popf
        pushf
        pop  ax
        and  ax,07000h           ; If bits 12-14 are 0 => i286
        mov  ax,i286
        jz   @@done

p386        
        ;80386 detection
        mov  eax,cr0
        mov  ebx,eax                 ;Original CR0 into EBX
        or   al,10h                  ;Set bit
        mov  cr0,eax                 ;Store it
        mov  eax,cr0                 ;Read it back
        mov  cr0,ebx                 ;Restore CR0
        test al,10h                  ;Did it set?
        mov  ax,i386sx
        jz   @@done                  ;Jump if 386SX
        mov  ax,i386dx               ;assume it's 386dx or higher
p286

@@done: popf
        ret
endp    _x_processor
