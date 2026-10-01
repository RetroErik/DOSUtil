;*****************************************************************************
openvideo macro
	  mov   ax,0013h
	  int   10h
	  mov   dx,3ceh
	  mov   al,5
	  out   dx,al
	  inc   dx
	  in    al,dx
	  and   al,11101111b
	  out   dx,al
	  dec   dx
	  mov   al,6
	  out   dx,al
	  inc   dx
	  in    al,dx
	  and   al,11111101b
	  out   dx,al
	  mov   dx,3c4h
	  mov   al,4
	  out   dx,al
	  inc   dx
	  in    al,dx
	  and   al,11110111b
	  or    al,4
	  out   dx,al
	  mov   ax,0A000h
	  mov   vio_seg,ax
	  mov   es,ax
	  xor   di,di
	  mov   ax,di
	  mov   cx,8000h
	  rep   stosw
	  mov   dx,3d4h
	  mov   al,14h
	  out   dx,al
	  inc   dx
	  in    al,dx
	  and   al,10111111b
	  out   dx,al
	  dec   dx
	  mov   al,17h
	  out   dx,al
	  inc   dx
	  in    al,dx
	  or    al,01000000b
	  out   dx,al
endm
;*****************************************************************************
LOAD_PAL MACRO PAL
        local bcl
	mov     dx, 3C8h
	mov     ax, 0
	xor     si, si
bcl:    out     dx, al
	inc     dl
	push    ax
	mov     al, byte ptr &PAL&[si]
	out     dx, al
	mov     al, byte ptr &PAL&[si+1]
	out     dx, al
	mov     al, byte ptr &PAL&[si+2]
	out     dx, al
	pop     ax
	dec     dl
	add     si, 3
	inc     ax
	cmp     ax, 256
	jl      bcl
ENDM
;*****************************************************************************
FADE_PAL MACRO PAL
	mov     dx, 3C8h
	mov     ax, 0
	xor     si, si
bcl:    out     dx, al
	inc     dl
	push    ax
	mov     al, byte ptr &PAL&[si]
	out     dx, al
	mov     al, byte ptr &PAL&[si+1]
	out     dx, al
	mov     al, byte ptr &PAL&[si+2]
	out     dx, al
	pop     ax
	dec     dl
	add     si, 3
	inc     ax
	cmp     ax, 256
	jl      bcl
ENDM
;*****************************************************************************
CloseVideo MACRO
        mov     ax, 3h
        int     10h
ENDM
;*****************************************************************************
WAITVRT MACRO
local vrt, novrt    
    mov     dx,3dah
VRT:
    in      al,dx
    test    al,8
    jnz     VRT         ; attend que le 'vertical retrace' d‚marre 
NOVRT:
    in      al,dx
    test    al,8
    jz      NOVRT       ; attend que le 'vertical retrace' s'arrˆte
ENDM
;*****************************************************************************