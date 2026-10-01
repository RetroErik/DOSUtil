ormirq0vect     dd      ?
opmirq0vect     dd      ?

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set up system timer for vertical retrace IRQ
; Out:
;   EAX,EDX,BL - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_initvrt:
        cli

        mov eax,offset vrtirqrm
        add eax,_code32a
        shl eax,12
        shr ax,12
        mov edx,offset vrtv-offset vrtirqrm
        add dx,ax
        mov vrtirqrmm0,dx
        xchg eax,gs:[8*4]
        mov ormirq0vect,eax

        xor bl,bl
	call _getirqvect
	mov opmirq0vect,edx
        mov edx,offset vrtirqpm
        call _setirqvect

        mov al,30h
        out 43h,al
        mov al,00h
        out 40h,al
        mov al,41h
        out 40h,al

        sti
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Reset system timer to normal
; Out:
;   AL,BL,EDX - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_resetvrt:
        cli

        mov edx,ormirq0vect
        mov gs:[8*4],edx
        mov edx,opmirq0vect
        xor bl,bl
        call _setirqvect

        mov al,36h
        out 43h,al
        xor al,al
        out 40h,al
        out 40h,al

        sti
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set timer to current vertical retrace period exactly
; Out:
;   AX,BX,DX - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_vrtset:
        cli

        mov al,30h
        out 43h,al
        mov dx,3dah
        in al,dx
        test al,8
        jnz $-3
        in al,dx
        test al,8
        jz $-3
        xor al,al
        out 40h,al
        out 40h,al

        in al,dx
        test al,8
	jnz $-3
        in al,dx
        test al,8
        jz $-3
        in al,40h
	mov ah,al
	in al,40h
	xchg al,ah
	neg ax
        sub ax,0c0h
        mov vrtv,ax
	mov bx,ax

        in al,dx
        test al,8
        jz $-3
        in al,dx
        test al,8
        jnz $-3
	mov al,bl
        out 40h,al
	mov al,bh
        out 40h,al

        sti
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
align 4
vrtirqpm:
        push eax edx ds
        mov ds,cs:_seldata
        mov dx,3dah
        in al,dx

;       test al,8
;       setnz ah
;       setz al
;       sub al,ah
;       movsx eax,al
        and eax,8
        dec eax
        neg eax

        add vrtv,ax
        in al,dx
        test al,8
        jz $-3
        mov ax,vrtv
        out 40h,al
        mov al,ah
        out 40h,al
        call _vrtrout           ; CALL _vrtrout
        pop ds edx
        mov al,20h
        out 20h,al
        pop eax
        sti
        iretd

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
align 4
vrtirqrm:                       ; This is 16bit code in a 32bit segment
        db 50h,52h              ; PUSH AX DX
        db 0bah,0dah,3          ; MOD DX,3dah
        db 0ech                 ; IN AL,DX

;       db 0a8h,8               ; TEST AL,8
;       db 0fh,95h,0c4h         ; SETNZ AH
;       db 0fh,94h,0c0h         ; SETZ AL
;       db 28h,0e0h             ; SUB AL,AH
;       db 0fh,0beh,0c0h        ; MOVSX AX,AL
        db 25h,8,0              ; AND AX,8
        db 48h                  ; DEC AX
        db 0f7h,0d8h            ; NEG AX

        db 2eh,1,6              ; ADD CS:VRTV,AX
vrtirqrmm0      dw      ?       ;
        db 0ech                 ; IN AL,DX
        db 0a8h,8               ; TEST AL,8
        db 74h,0fbh             ; JZ SHORT $-3
        db 0ebh,0               ; JMP SHORT $+2
        db 0b8h                 ; MOV AX,vrtv
vrtv    dw      4100h           ;
        db 0e6h,40h             ; OUT 40h,AL
        db 88h,0e0h             ; MOV AL,AH
        db 0e6h,40h             ; OUT 40h,AL
        db 05ah                 ; POP DX
        db 0b0h,20h             ; MOV AL,20h
        db 0e6h,20h             ; OUT 20h,AL
        db 58h                  ; POP AX
        db 0cfh                 ; IRET

