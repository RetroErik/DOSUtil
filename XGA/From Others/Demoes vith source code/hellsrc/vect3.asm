        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32

public  _v0r0sincosptr, _v0r0perspective
public  _v0r0srx0, _v0r0sry0, _v0r0srz0
public  _v0r0crx0, _v0r0cry0, _v0r0crz0
public  _v0r0srx1, _v0r0sry1, _v0r0srz1
public  _v0r0crx1, _v0r0cry1, _v0r0crz1
public  _v0r0tx, _v0r0ty, _v0r0tz

public  _v0rot0init, _v0rot0a, _v0rot0b

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize sin and cos for rotation
; In:
;   EBX - rotation around X (0-511)
;   ECX - rotation around Y (0-511)
;   EDX - rotation around Z (0-511)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_v0rot0init:
        push eax ebp
        db 0bdh
_v0r0sincosptr  dd      ?
        movsx eax,word ptr [ebp+ebx*2]
        mov _v0r0srx0,eax
        mov _v0r0srx1,eax
        movsx eax,word ptr [ebp+ebx*2+256]
        mov _v0r0crx0,eax
        mov _v0r0crx1,eax
        movsx eax,word ptr [ebp+ecx*2]
        mov _v0r0sry0,eax
        mov _v0r0sry1,eax
        movsx eax,word ptr [ebp+ecx*2+256]
        mov _v0r0cry0,eax
        mov _v0r0cry1,eax
        movsx eax,word ptr [ebp+edx*2]
        mov _v0r0srz0,eax
        mov _v0r0srz1,eax
        movsx eax,word ptr [ebp+edx*2+256]
        mov _v0r0crz0,eax
        mov _v0r0crz1,eax
        pop ebp eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Rotate set of X,Y,Z coordinates (translate and apply perspective if needed)
; In:
;   ESI -> source raw point buffer
;   EDI -> destination point buffer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;-----------------------------------------------------------------------------
_v0rot0a:                               ; without xlat and perspective
        mov word ptr vrot0m0,(VROT0M0LEN shl 8)+0ebh
        jmp short vrot0
;-----------------------------------------------------------------------------
_v0rot0b:                               ; with xlat and perspective
        mov word ptr vrot0m0,0c089h
        jmp short vrot0
;-----------------------------------------------------------------------------
vrot0:
        pushad
        lodsw
        stosw
        push ax
vrot0ml:
        movsx ecx,word ptr [esi]
        mov eax,ecx
        db 69h,0c0h             ;       imul eax,crz
_v0r0crz0       dd      ?       ;
        sar eax,9
        movsx edx,word ptr [esi+2]
        mov ebx,edx
        db 69h,0dbh             ;       imul ebx,srz
_v0r0srz0       dd      ?       ;
        sar ebx,9
        sub eax,ebx
        db 69h,0c9h             ;       imul ecx,srz
_v0r0srz1       dd      ?       ;
        sar ecx,9
        db 69h,0d2h             ;       imul edx,crz
_v0r0crz1       dd      ?       ;
        sar edx,9
        add ecx,edx
        movsx ebp,word ptr [esi+4]
        mov ebx,ecx
        db 69h,0dbh             ;       imul ebx,crx
_v0r0crx0       dd      ?       ;
        sar ebx,9
        mov edx,ebp
        db 69h,0d2h             ;       imul edx,srx
_v0r0srx0       dd      ?       ;
        sar edx,9
        sub ebx,edx
        db 69h,0c9h             ;       imul ecx,srx
_v0r0srx1       dd      ?       ;
        sar ecx,9
        db 69h,0edh             ;       imul ebp,crx
_v0r0crx1       dd      ?       ;
        sar ebp,9
        add ebp,ecx
        mov edx,ebp
	db 69h,0edh		;	imul ebp,cry
_v0r0cry0       dd      ?       ;
	sar ebp,9
        mov ecx,eax
        db 69h,0c9h             ;       imul ecx,sry
_v0r0sry0       dd      ?       ;
        sar ecx,9
	sub ebp,ecx
	db 69h,0d2h		;	imul edx,sry
_v0r0sry1       dd      ?       ;
	sar edx,9
        db 69h,0c0h             ;       imul eax,cry
_v0r0cry1       dd      ?       ;
        sar eax,9
	add eax,edx
        add esi,6
vrot0m0         dw      ?       ; MOV EAX,EAX or JMP SHORT vrot0mlc
        db 66h,5                ; ADD AX,_v0r0tx
_v0r0tx         dw      0       ;
        db 66h,81h,0c3h         ; ADD BX,_v0r0ty
_v0r0ty         dw      0       ;
        db 66h,81h,0c5h         ; ADD BP,_v0r0tz
_v0r0tz         dw      0       ;
        mov [edi],ax
        mov [edi+2],bx
	mov [edi+4],bp
        db 66h,0b9h             ; MOV CX,_v0r0perspective
_v0r0perspective  dw 0          ;       ; perspective multiplier
        imul cx
        idiv bp
        mov [edi+6],ax
        mov eax,ebx
        imul cx
        idiv bp
        mov [edi+8],ax
        add edi,10
        dec word ptr [esp]
        jnz vrot0ml
        jmp short vrot0mld
VROT0M0LEN=($-vrot0m0)-2
vrot0mlc:
        mov [edi],ax
        mov [edi+2],bx
        mov [edi+4],bp
        add edi,6
        dec word ptr [esp]
        jnz vrot0ml
vrot0mld:
        add esp,2
        popad
        ret

code32  ends
        end

