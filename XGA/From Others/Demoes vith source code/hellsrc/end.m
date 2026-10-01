endpalptr       dd      ?               ; ptr to end pic pal
endretrace      dw      0               ; retrace flag and counter

;ฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐ
; Put end piccy to screen and wait a little
; Out:
;   EAX,EBX,ECX,EDX,ESI,EDI - ?
;ฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐฐ
_end:
        mov v86r_ax,12h                 ; 640x480x16 mode
        mov al,10h
        int 33h
        mov dx,3dah
        in al,dx
        test al,8
        jz short $-3
        mov dx,3c0h
        xor ah,ah
endl2:
        mov al,ah
        out dx,al
        jmp short $+2
        out dx,al
        inc ah
        cmp ah,10h
        jb endl2
        mov al,20h
        out dx,al
        call _vrtset

        mov esi,_clearpalptr            ; clear palette
        mov ecx,10h
        xor al,al
        call _setcpal

        mov eax,'endp'                  ; load up end piccy and pal
        call _loaddata
        mov edi,_vidptr0
        mov esi,eax
        mov dx,3ceh
        @outw 0ff08h
        mov dl,0c4h
        @outb 2
        inc edx
        mov ebx,480
endl0:
        mov al,1
endl0l0:
        out dx,al
        mov ecx,20
        rep movsd
        sub edi,80
        shl al,1
        and al,0fh
        jnz endl0l0
        add edi,80
        dec ebx
        jnz endl0

        mov edi,_cpalptr                ; slide to piccy pal
        call endr0

        mov _vrtrout,offset endir1      ; wait a little or for a key
        mov _kbhit,0
endl1:
        cmp _kbhit,0
        jne short endl1d
        cmp endretrace,70*10
        jb endl1
endl1d:

        mov esi,_clearpalptr            ; slide to black and exit

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
endr0:                                  ; slide to a color palette
        mov _vrtrout,offset endir0
        mov ecx,30h
        mov bl,1
endr0l0:
        cmp endretrace,0
        je endr0l0
        mov endretrace,0
        call _slidebytes
        jnc endr0l0
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
endir1:                                 ; just a simple timer
        inc endretrace
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
endir0:                                 ; retrace palette setting routine
        cld
        push ecx esi
        mov dx,3c8h
        @outb 0
        mov esi,_cpalptr
        inc edx
        mov ecx,30h
        rep outsb
        mov endretrace,1
        pop esi ecx
        ret

