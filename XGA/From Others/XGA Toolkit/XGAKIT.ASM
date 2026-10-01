;
;	XGA Adapter Programmer's Toolkit, version 1.1
;		by Bert Tyler of Tyler Software
;		CIS ID:  73477,433
;		(From Internet/BITNET: 73477.433@compuserve.com)
;	Copyright 1990, 1991 Tyler Software
;	(except, of course, for those parts copied right out of IBM's
;	"Preliminary XGA Video Subsystem Hardware Users Guide")
;		((which is most of the code, really...))
;
;	Free for use in commercial, shareware or freeware applications
;
;	Routines in this module:
;
;	int xga_detect()
;		returns	0 if no XGA adapter found
;			non-zero if XGA adapter found
;		bits:	0 - XGA adapter found
;			1 - XGA monitor is color, not mono
;			2 - XGA monitor is high-rez - capable of 1024x768
;			3 - XGA adapter has 1MB of RAM
;			4 - XGA adapter is in a dual-monitor setup
;		(IE, return code of 7 means XGA adapter with 512K of RAM
;		connected to a high-rez color monitor in a single-
;		monitor setup)
;
;	int xga_mode(int mode)
;		mode =	0 to enter normal VGA text mode (BIOS mode 3)
;			1 to enter 132-col VGA text mode
;			2 to enter 1024x768x256 graphics mode
;			3 to enter 1024x768x16 graphics mode
;			4 to enter 640x480x256 graphics mode
;			5 to enter 640x480x65536 graphics mode
;			6 to enter 800x600x16 graphics mode
;			7 to enter 800x600x256 graphics mode
;			8 to enter 800x600x65536 graphics mode
;		returns	0 on failure
;			1 on success
;		(NOTE!  You *must* use 'xga_mode(0)' to exit any of the
;		other modes and get back to standard VGA operation, even
;		on a dual-monitor (XGA & VGA) setup!  On a dual-monitor
;		setup, 'xga_mode(0)' leaves the XGA image intact, but
;		disables the XGA adapter's 64K aperture at A000:0000)
;
;	void xga_putpixel(int row, int col, int color)
;		writes pixel (row, col) using color
;		(all pixel counts start at 0, and [0][0] is in the UL corner)
;
;	int xga_getpixel(int row, int col)
;		returns	color of pixel at (row, col)
;		(all pixel counts start at 0, and [0][0] is in the UL corner)
;
;	void xga_putline(int row, int firstcol, int lastcol, char *pixels)
;		sends the line segment directly to the video
;		(all pixel counts start at 0, and [0][0] is in the UL corner)
;		(IE, xga_putline(3,7,12,*pixels) sends pixel[0] thru pixel[5]
;		to the 8th thru 13th pixel in the fourth row)
;
;	void xga_getline(int row, int firstcol, int lastcol, char *pixels)
;		reads the line segment directly from the video
;		(all pixel counts start at 0, and [0][0] is in the UL corner)
;		(IE, xga_putline(3,7,12,*pixels) fills pixel[0] thru pixel[5]
;		from the 8th thru 13th pixel in the fourth row)
;
;	void xga_setpalette(char *palette)
;		where 'palette' points to a 768-byte array of RGB values
;			(values from 0-255, not the VGA's internal 0-63!)
;

	.MODEL	medium,c


	.DATA

public		xga_isinmode		; (only public for Fractint purposes)
public		xga_clearvideo		; (only public for Fractint purposes)

xga_pos_base	dw	0		; MCA Pos Base value
xga_cardid	dw	0		; MCA Card ID value
xga_reg_base	dw	-1		; XGA IO Reg Base (-1 means dunno yet)
xga_1mb		dd	0		; XGA 1MB aperture address
xga_4mb		dd	0		; XGA 4MB aperture address
xga_result	dw	0		; XGA_detect result code
xga_isinmode	dw	0		; XGA is in this mode right now
xga_iscolors	dw	0		; XGA using this many colors (0=64K)
xga_clearvideo	db	0		; set to 80h to prevent video-clearing
xga_dotwrite	dw	0		; write-a-dot routine:	mode-specific
xga_dotread 	dw	0		; read-a-dot routine:	mode-specific
xga_linewrite	dw	0		; write-a-line routine: mode-specific
xga_lineread	dw	0		; read-a-line routine: mode-specific
xga_curbk	dw	0		; bank number
xga_xdots	dw	0		; bytes per scan line
xga_linelen	dw	0		; line segment length
xga_offset	dw	0		; line segment offset

	.CODE

;		Graphics mode setup values
;		(the first two entries in each line 
;		indicate where the table values are to be stored)
;
;		1024x768x256 vvv
;		1024x768x16  -----vvvv
;		640x480x256  -----------vvvv
;		640x480x65536 ----------------vvvv
;		800x600x16   -----------------------vvvv
;		800x600x256  -----------------------------vvvv
;		800x600x65536 ----------------------------------vvvv

xga_twidth dw	9					; width of these tables

xga_requir dw      0,    0,  0dh,  05h,  01h,  09h,  01h,  01h,  09h	; adapter requirements
xga_colors dw	   0,    0,  256,   16,  256,    0,   16,  256,    0	; 0 means 64K colors
xga_swidth dw      0,    0, 1024,  512,  640, 1280,  400,  800, 1600	; bytes / scan line

xga_val	db	004h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; interrupt enable
	db	005h, 000h, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; interrupt status
	db	000h, 000h, 004h, 004h, 004h, 004h, 004h, 004h, 004h	; operating mode
	db	00ah, 064h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; palette mask
	db	001h, 000h, 001h, 001h, 001h, 001h, 001h, 001h, 001h	; vid mem aper cntl
	db	008h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; vid mem aper indx
	db	006h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; virt mem ctl
	db	009h, 000h, 003h, 002h, 003h, 004h, 002h, 003h, 004h	; mem access mode
	db	00ah, 050h, 001h, 001h, 001h, 001h, 001h, 001h, 001h	; disp mode 1
	db	00ah, 050h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; disp mode 1
	db	00ah, 010h, 09dh, 09dh, 063h, 063h, 088h, 088h, 088h	; horiz tot lo.
	db	00ah, 011h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; horiz tot hi.
	db	00ah, 012h, 07fh, 07fh, 04fh, 04fh, 063h, 063h, 063h	; hor disp end lo
	db	00ah, 013h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; hor disp end hi
	db	00ah, 014h, 07fh, 07fh, 04fh, 04fh, 063h, 063h, 063h	; hor blank start lo
	db	00ah, 015h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; hor blank start hi
	db	00ah, 016h, 09dh, 09dh, 063h, 063h, 088h, 088h, 088h	; hor blank end lo
	db	00ah, 017h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; hor blank end hi
	db	00ah, 018h, 087h, 087h, 055h, 055h, 06ah, 06ah, 06ah	; hor sync start lo
	db	00ah, 019h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; hor sync start hi
	db	00ah, 01ah, 09ch, 09ch, 061h, 061h, 084h, 084h, 084h	; hor sync end lo
	db	00ah, 01bh, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; hor sync end hi
	db	00ah, 01ch, 040h, 040h, 000h, 000h, 000h, 000h, 000h	; hor sync pos
	db	00ah, 01eh, 004h, 004h, 000h, 000h, 000h, 000h, 000h	; hor sync pos
	db	00ah, 020h, 030h, 030h, 00ch, 00ch, 086h, 086h, 086h	; vert tot lo
	db	00ah, 021h, 003h, 003h, 002h, 002h, 002h, 002h, 002h	; vert tot hi
	db	00ah, 022h, 0ffh, 0ffh, 0dfh, 0dfh, 057h, 057h, 057h	; vert disp end lo
	db	00ah, 023h, 002h, 002h, 001h, 001h, 002h, 002h, 002h	; vert disp end hi
	db	00ah, 024h, 0ffh, 0ffh, 0dfh, 0dfh, 057h, 057h, 057h	; vert blank start lo
	db	00ah, 025h, 002h, 002h, 001h, 001h, 002h, 002h, 002h	; vert blank start hi
	db	00ah, 026h, 030h, 030h, 00ch, 00ch, 086h, 086h, 086h	; vert blank end lo
	db	00ah, 027h, 003h, 003h, 002h, 002h, 002h, 002h, 002h	; vert blank end hi
	db	00ah, 028h, 000h, 000h, 0eah, 0eah, 058h, 058h, 058h	; vert sync start lo
	db	00ah, 029h, 003h, 003h, 001h, 001h, 002h, 002h, 002h	; vert sync start hi
	db	00ah, 02ah, 008h, 008h, 0ech, 0ech, 06eh, 06eh, 06eh	; vert sync end
	db	00ah, 02ch, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; vert line comp lo
	db	00ah, 02dh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; vert line comp hi
	db	00ah, 036h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; sprite cntl
	db	00ah, 040h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; start addr lo
	db	00ah, 041h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; start addr me
	db	00ah, 042h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; start addr hi
	db	00ah, 043h, 080h, 040h, 050h, 0a0h, 032h, 064h, 0c8h	; pixel map width lo
	db	00ah, 044h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; pixel map width hi
	db	00ah, 054h, 00dh, 00dh, 000h, 000h, 001h, 001h, 001h	; clock sel
	db	00ah, 051h, 003h, 002h, 003h, 004h, 002h, 003h, 004h	; display mode 2
	db	00ah, 070h, 000h, 000h, 000h, 000h, 080h, 080h, 080h	; ext clock sel
	db	00ah, 050h, 00fh, 00fh, 0c7h, 0c7h, 007h, 007h, 007h	; display mode 1
	db	00ah, 055h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; Border Color
	db	00ah, 060h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; Sprite Pal Lo
	db	00ah, 061h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; Sprite Pal hi
	db	00ah, 062h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; Sprite Pre Lo
	db	00ah, 063h, 000h, 000h, 000h, 000h, 000h, 000h, 000h	; Sprite Pre hi
	db	00ah, 064h, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; Palette Mask
	db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; end of the list

xga_newbank	proc			; XGA-specific bank-switching routine
	cmp	xga_isinmode,2		; are we in an XGA-specific mode?
	jl	return			;  nope.  bail out.
	mov	xga_curbk,ax		; save the new current bank value
	mov	dx,xga_reg_base		; Select Page
	add	dx,08h
	out	dx,al			; assumes bank number is in al
return:	ret
xga_newbank	endp

xga_nullroutine	proc	near		; "do-nothing" placeholder routine
	mov	ax,0
	ret
xga_nullroutine	endp

xga_normalinewrite	proc	near	; slow, generic line-write routine
normal_line1:
	push	ax			; save stop col
	mov	al,[si] 		; retrieve the color
	cmp	xga_iscolors,0		; 64K-color mode?
	jne	normal_line2
	mov	ax,[si]			; yup - adjust
	inc	si
normal_line2:
	push	cx			; save the counter around the call
	push	dx			; save column around the call
	push	si			; save the pointer around the call also
	call	xga_dotwrite		; write the dot via the approved method
	pop	si			; restore the pointer
	pop	dx			; restore the column
	pop	cx			; restore the counter
	inc	si			; bump it up
	inc	cx			; bump it up
	pop	ax			; retrieve number of dots
	cmp	cx,ax			; more to go?
	jl	normal_line1		; yup.	do it.
	ret
xga_normalinewrite	endp

xga_normalineread	proc	near	; slow, generic read-line routine
	mov	bx,0a000h
	mov	es,bx
normal_lineread1:
	push	ax			; save stop col
	push	cx			; save the counter around the call
	push	dx			; save column around the call
	push	di			; save the pointer around the call also
	call	xga_dotread 		; read the dot via the approved method
	pop	di			; restore the pointer
	pop	dx			; restore the column
	pop	cx			; restore the counter
	mov	bx,di			; locate the actual pixel color
	mov	[bx],al 		; retrieve the color
	cmp	xga_iscolors,0		; 64K-color mode?
	jne	normal_line2
	mov	[bx],ax			; yup - adjust
	inc	di
normal_line2:
	inc	di			; bump it up
	inc	cx			; bump it up
	pop	ax			; retrieve number of dots
	cmp	cx,ax			; more to go?
	jle	normal_lineread1	; yup.	do it.
	ret
xga_normalineread	endp

xga_sameseg	proc	near		; line segment support
	cmp	xga_iscolors,0		; 64K-color mode?
	jne	xga_sk1
	add	ax,ax			; two bytes / pixel
	add	cx,cx
xga_sk1:
	mov	bx,ax			; calculate the line segment len
	sub	bx,cx
	mov	xga_linelen,bx
	mov	ax,xga_xdots		; calculate the first pixel bank
	mul	dx
	add	ax,cx
	adc	dx,0
	mov	bx,dx			; save the bank address
	mov	xga_offset,ax		; save the destination
	add	ax,xga_linelen		; calculate the last pixel bank
	adc	dx,0
	cmp	dx,bx			; same bank?
	jne	xga_sk2			;  nope
	mov	ax,dx			; xga_newbank expects bank in al
	call	far ptr xga_newbank
	cmp	ax,ax			; set flag: same bank
xga_sk2:ret
xga_sameseg	endp

xga_16linewrite	proc	near		; 16-color Line Write
	mov	bx,ax			; calculate the # of columns
	sub	bx,cx
	mov	ax,xga_xdots		; this many dots / line
	mul	dx			; times this many lines - ans in dx:ax
	push	cx			; save the X-value for a tad
	shr	cx,1			; and adjust for two bits per pixel
	add	ax,cx			; plus this many x-dots
	adc	dx,0			; answer in dx:ax - dl=bank, ax=offset
	mov	di,ax			; save offset in DI
	pop	cx			; restore the X-value
	mov	ax,dx			; xga_newbank expects bank in al
new_bank:
	call	far ptr xga_newbank
same_bank:
	mov	ah,es:[di]		; grab the old byte value
	mov	al,[si]			; and the new color value
	and	al,0fh			; isolate the bits we want
	test	cx,1			; odd pixel address?
	jnz	xga_sk1			;  yup
	and	ah,0f0h			; isolate the low-order
	jmp	short	xga_sk2
xga_sk1:and	ah,0fh			; isolate the high-order
	shl	al,1
	shl	al,1
	shl	al,1
	shl	al,1
xga_sk2:or	al,ah			; combine the two nibbles
	mov	es:[di],al		; write the dot
	inc	si			; increment the source addr
	dec	bx			; more to go?
	jz	done			; nope
	inc	cx			; next pixel
	test	cx,1			; odd pixel?
	jnz	same_bank		;  yup
	inc	di			; increment the destination
	cmp	di,0			; segment wrap?
	jnz	same_bank		;  nope
	mov	ax,xga_curbk		; update the bank cvalue
	inc	ax
	jmp	new_bank
done:	ret
xga_16linewrite		endp

xga_256linewrite	proc	near	; 256-color, 64K color line write
	push	dx			; save a few registers
	push	cx
	push	ax
	call	xga_sameseg
	jne	slow			; go slow if banks changed
	mov	cx,xga_linelen		; do it the fast way
	mov	di,xga_offset
	cld
	shr	cx,1
	rep	movsw
	rcl	cx,1
	rep	movsb
	pop	ax			; restore the registers
	pop	cx
	pop	dx
	ret
slow:	pop	ax			; call the slow routine
	pop	cx
	pop	dx
	call	xga_normalinewrite
	ret
xga_256linewrite	endp

xga_256lineread	proc	near		; 256-color, 64K color line write
	push	dx			; save a few registers
	push	cx
	push	ax
	call	xga_sameseg
	jne	slow			; go slow if banks changed
	mov	cx,xga_linelen		; do it the fast way
	mov	si,xga_offset
	push	ds
	pop	es
	mov	ax,0a000h
	mov	ds,ax
	cld
	shr	cx,1
	rep	movsw
	rcl	cx,1
	rep	movsb
	push	es
	pop	ds
	pop	ax			; restore the registers
	pop	cx
	pop	dx
	ret
slow:	pop	ax			; call the slow routine
	pop	cx
	pop	dx
	call	xga_normalineread
	ret
xga_256lineread	endp

xga_super256addr	proc near	; can be put in-line but shared by
					; read and write routines
	clc				; clear carry flag
	push	ax			; save this for a tad
	mov	ax,xga_xdots		; this many dots / line
	mul	dx			; times this many lines - ans in dx:ax
	add	ax,cx			; plus this many x-dots
	adc	dx,0			; answer in dx:ax - dl=bank, ax=offset
	mov	bx,ax			; save this in BX
	cmp	dx,xga_curbk		; see if bank changed
	je	same_bank		; jump if old bank ok
	mov	ax,dx			; xga_newbank expects bank in al
	call	far ptr xga_newbank
same_bank:
	pop	ax			; restore AX
	ret
xga_super256addr	endp

xga_super64kaddr	proc near	; can be put in-line but shared by
					; read and write routines
	clc				; clear carry flag
	push	ax			; save this for a tad
	mov	ax,xga_xdots		; this many dots / line
	mul	dx			; times this many lines - ans in dx:ax
	add	ax,cx			; plus this many x-dots
	adc	dx,0			; answer in dx:ax - dl=bank, ax=offset
	add	ax,cx			; plus this many x-dots
	adc	dx,0			; answer in dx:ax - dl=bank, ax=offset
	mov	bx,ax			; save this in BX
	cmp	dx,xga_curbk		; see if bank changed
	je	same_bank		; jump if old bank ok
	mov	ax,dx			; xga_newbank expects bank in al
	call	far ptr xga_newbank
same_bank:
	pop	ax			; restore AX
	ret
xga_super64kaddr	endp

xga_super16addr	proc near		; can be put in-line but shared by
					; read and write routines
	clc				; clear carry flag
	push	ax			; save this for a tad
	mov	ax,xga_xdots		; this many dots / line
	mul	dx			; times this many lines - ans in dx:ax
	push	cx			; save the X-value for a tad
	shr	cx,1			; and adjust for two bits per pixel
	add	ax,cx			; plus this many x-dots
	adc	dx,0			; answer in dx:ax - dl=bank, ax=offset
	pop	cx			; restore the X-value
	mov	bx,ax			; save this in BX
	cmp	dx,xga_curbk		; see if bank changed
	je	same_bank		; jump if old bank ok
	mov	ax,dx			; xga_newbank expects bank in al
	call	far ptr xga_newbank
same_bank:
	pop	ax			; restore AX
	ret
xga_super16addr	endp

xga_256write	proc near		; XGA 256 colors write-a-dot
	call	xga_super256addr	; calculate address and switch banks
	mov	es:[bx],al		; write the dot
	ret				; we done.
xga_256write	endp

xga_256read	proc near		; XGA 256 colors read-a-dot
	call	xga_super256addr	; calculate address and switch banks
	mov	al,es:[bx]		; read the dot
	mov	ah,0			; convert to an int
	ret				; we done.
xga_256read	endp

xga_64kwrite	proc near		; XGA 256 colors write-a-dot
	call	xga_super64kaddr	; calculate address and switch banks
	mov	es:[bx],ax		; write the dot
	ret				; we done.
xga_64kwrite	endp

xga_64kread	proc near		; XGA 256 colors read-a-dot
	call	xga_super64kaddr	; calculate address and switch banks
	mov	ax,es:[bx]		; read the dot
	ret				; we done.
xga_64kread	endp

xga_16write	proc near		; XGA 256 colors write-a-dot
	call	xga_super16addr		; calculate address and switch banks
	mov	ah,es:[bx]		; grab the old byte value
	and	al,0fh			; isolate the bits we want
	test	cx,1			; odd pixel address?
	jnz	xga_sk1			;  yup
	and	ah,0f0h			; isolate the low-order
	jmp	short	xga_sk2
xga_sk1:and	ah,0fh			; isolate the high-order
	shl	al,1
	shl	al,1
	shl	al,1
	shl	al,1
xga_sk2:or	al,ah			; combine the two nibbles
	mov	es:[bx],al		; write the dot
	ret				; we done.
xga_16write	endp

xga_16read	proc near		; XGA 256 colors read-a-dot
	call	xga_super16addr		; calculate address and switch banks
	mov	al,es:[bx]		; read the dot
	test	cx,1			; odd number of pixels?
	jz	xga_sk1			;  nope
	shr	ax,1			; adjust for odd pixel count
	shr	ax,1
	shr	ax,1
	shr	ax,1
xga_sk1:and	ax,0fh			; isolate the byte value
	ret				; we done.
xga_16read	endp

xga_clear	proc	uses es si di	; clear the XGA memory
	cmp	xga_clearvideo,0	; should we really do this?
	jne	return			;  nope.  skip it.
	mov	bx,xga_result		; find out how much memory we have
	and	bx,08h			;  in 64K pages
	add	bx,08h
	mov	ax,0a000h		; set up to clear 0a0000-0affff
	push	ax
	pop	es
xloop:	mov	ax,bx			; initialize the bank addr
	call	xga_newbank
	mov	ax,0
	mov	cx,16384		; clear out 32K
	mov	di,0
	rep	stosw
	mov	cx,16384		; clear out 32K
	rep	stosw
	dec	bx			; another page?
	cmp	bx,0
	jge	xloop
return:	ret
xga_clear	endp

xga_setpalette	proc	uses es si di, palette:word	; set the XGA palette
	cmp	xga_isinmode,2		; are we in an XGA graphics mode?
	jl	return			;  nope

	mov	dx,xga_reg_base		; wait for a retrace
	add	dx,5
	mov	al,1			; clear the start-of-blanking
	out	dx,al
bloop:	in	al,dx
	test	al,01h			; blanking started?
	jz	bloop			;  nope - try again

	mov	dx,xga_reg_base		; set up for a palette load
	add	dx,0ah
	mov	ax,0064h		; make invisible
	out	dx,ax
	mov	ax,0055h		; border color
	out	dx,ax
	mov	ax,0066h		; palette mode
	out	dx,ax
	mov	ax,0060h		; start at palette 0
	out	dx,ax
	mov	ax,0061h
	out	dx,ax

	mov	si,palette
	mov	cx,768
	mov	ax,065h			; palette update
	out	dx,al
	inc	dx			; palette data
.186
	rep	outsb			; update all registers at once
.8086
	dec	dx

	mov	ax,0ff64h		; make visible
	out	dx,ax

return:	ret
xga_setpalette	endp

xga_detect	proc	uses es di si

	cmp	xga_reg_base,-2		; has the XGA detector already failed?
	jne	xga_sk1			; ne = not yet
	jmp	xga_notfound		; e = yes, fail again
xga_sk1:cmp	xga_reg_base,-1		; have we already found the XGA?
	je	xga_loc			; e = no
	jmp	xga_found		; yes, process it

xga_loc:mov	ah,35h			; DOS get interrupt vector
	mov	al,15h			; Int 15h
	int	21h			; returns vector in es:bx
	mov	ax,es			; segment part
	or	ax,bx			; undefined vector?
	jnz	xga_sk2			; nz = no, OK so far
	jmp	xga_notfound		; z = yes - not an MCA machine
xga_sk2:mov	dx,-1			; start with an invalid POS address
	mov	ax,0c400h		; look for POS base address
	int	15h			;  (Microchannel machines only)
	jnc	xga_sk3			; nc = success
	jmp	xga_notfound		; error - not an MC machine
xga_sk3:mov	xga_pos_base,dx		; save pos_base_address
	xor	cx,cx			; check all MCA slots & motherboard
	cmp	dx,-1			; do we have a good POS?
	jne	xga_lp1			; ne = yes, proceed with MCA checks
	jmp	xga_notfound		; no, fail

xga_lp1:cli				; no interrupts, please
	cmp	cx,0			; treat the motherboard differently?
	jne	xga_sk4			; ne = yes
	mov	al,0dfh			; enable the motherboard for setup
	mov	dx,94h
	out	dx,al
	jmp	short xga_sk5
xga_sk4:mov	ax,0c401h		; enable an MCA slot for setup
	mov	bx,cx			;  this slot
	int	15h
xga_sk5:mov	dx,xga_pos_base		; get pos record for the slot ID
	in	ax,dx
	mov	xga_cardid,ax
	add	dx,2			; compute IO Res Base
	in	al,dx			;  get POS data byte1
	mov	byte ptr xga_1mb,al	;   save it temporarily
	inc	dx			; switch to byte 2
	in	al,dx			;  get POS data
	mov	byte ptr xga_1mb+1,al	;   save it temporarily
	inc	dx			; switch to byte 3
	in	al,dx			;  get POS data
	mov	byte ptr xga_1mb+2,al	;   save it temporarily
	inc	dx			; switch to byte 4
	in	al,dx			;  get POS data
	mov	byte ptr xga_1mb+3,al	;   save it temporarily
	cmp	cx,0			; treat the motherboard differently
	jne	xga_sk6			; ne = yes
	mov	al,0ffh			; enable the motherboard for normal
	out	094h,al
	jmp	short xga_sk7
xga_sk6:mov	ax,0c402h		; enable the MCA slot for normal
	mov	bx,cx			;  this slot
	int	15h
xga_sk7:sti				; interrupts on again

	mov	ax,xga_cardid		; is an XGA adapter on this slot?
	cmp	ax,08fd8h
	jae	xga_sk8			; ae = yes
	jmp	xga_lp2			; try another slot
xga_sk8:cmp	ax,08fdbh		; still within range?
	jbe	xga_sk9			; be = yes
	jmp	xga_lp2			; no, try another slot

xga_sk9:mov	al,byte ptr xga_1mb	;  restore POS data byte 1
	and	ax,0eh			;  muck about with it to get reg base
	shl	ax,1
	shl	ax,1
	shl	ax,1
	add	ax,2100h
	mov	xga_reg_base,ax
	mov	dx,xga_reg_base		; is there a monitor on this slot?
	add	dx,0ah
	mov	al,052h
	out	dx,al
	mov	dx,xga_reg_base
	add	dx,0bh
	in	al,dx
	and	al,0fh
	cmp	al,00h			; illegal value, returned under Win 3.0
	je	xga_lp2
	cmp	al,0fh
	jne	xga_isthere		; ne = yes

xga_lp2:inc	cx			; try another adapter?
	cmp	cx,9			; done all slots?
	ja	xga_ska			; a = yes
	jmp	xga_lp1			; no, try another slot

xga_ska:jmp	xga_notfound		; forget it - no XGA here

xga_isthere:
	and	ax,06h			; strip off the low & high bit
	xor	ax,05h			; reverse the 3rd & low bits
	mov	xga_result,ax		; save the result flag

	mov	dx,xga_reg_base		; is this XGA in VGA mode?
	in	al,dx
	test	al,1
	jnz	xga_skb			; nz = yes - single-monitor setup
	or	xga_result,10h		;  dual-monitor setup
xga_skb:

	mov	ah,byte ptr xga_1mb+2	; retrieve POS data byte 3
	and	ax,0fe00h		; eliminate the low-order bits
	mov	bl,byte ptr xga_1mb	; retrieve POS data byte 1
	and	bx,0eh			; strip it down to the IODA
	mov	cx,5			; shift it up 5 bits
	shl	bx,cl
	or	ax,bx			; compute the 4MB aperture value
	mov	word ptr xga_4mb+2,ax	; save the result

	mov	al, byte ptr xga_1mb+3	; retrieve POS data byte 4
	and	ax,0fh			; select the 1MB aperture bits
	mov	cx,4			; shift it up 4 bits
	shl	ax,cl
	mov	word ptr xga_1mb+2,ax	; save the result
	mov	ax,0
	mov	word ptr xga_1mb,ax 

	mov	dx,xga_reg_base		; Interrupt Disable
	add	dx,4
	xor	al,al
	out	dx,al

	mov	dx,xga_reg_base		; Switch to Extended Mode
;;	add	dx,00h
	mov	al,4
	out	dx,al

	mov	dx,xga_reg_base		; Aperture Control
	add	dx,01h
	mov	al,1
	out	dx,al

	mov	dx,xga_reg_base		; disable Palette Mask
	add	dx,0ah
	mov	ax,0064h
	out	dx,ax

	mov	xga_isinmode,2		; pretend we're already in graphics
	mov	al,12			; select page 12
	call	xga_newbank

	push	es			; see if this page has any memory
	mov	ax,0a000h
	push	ax
	pop	es
	mov	ah,000a5h
	mov	es:0,al
	mov	es:1,ah
	cmp	es:0,al
	jne	xga_512
	add	xga_result,8		; 1MB RAM found
xga_512:pop	es

	mov	al,0			; select page 0
	call	xga_newbank
	mov	xga_isinmode,0		; replace the "in-graphics" flag

	mov	dx,xga_reg_base		; Palette Mask
	add	dx,0ah
	mov	ax,0ff64h
	out	dx,ax

	test	xga_result,10h		; dual monitor setup?
	jnz	xga_found		;  yup - don't restore as a VGA

	mov	dx,xga_reg_base		; Switch to VGA Mode
;;	add	dx,00h
	mov	al,1
	out	dx,al

	mov	dx,03c3h		; Enable VGA Address Code
	mov	al,1
	out	dx,al

	jmp	short	xga_found

xga_notfound:
	mov	xga_reg_base,-2		; set failure flag
xga_found:
	mov	ax,xga_result		; return the result
	ret

xga_detect	endp

xga_mode	proc	uses es di si, mode:word

	mov	ax, offset xga_nullroutine	; null out the pixel rtns
	mov	xga_dotwrite,ax
	mov	xga_dotread,ax
	mov	ax,offset xga_normalinewrite
	mov	xga_linewrite,ax
	mov	ax,offset xga_normalineread
	mov	xga_lineread,ax
	mov	xga_curbk,-1		; preload impossible bank number

	call	xga_detect		; is an XGA adapter present?
	cmp	ax,0
	jne	whichmode
	jmp	nope			;  nope - fail right now.
whichmode:
	mov	bx,mode
	cmp	bx,xga_twidth		; mode number out of range?
	jb	whichmode0
	jmp	nope			;  yup - fail right now.
whichmode0:
	cmp	mode,0			; 80-col VGA text mode?
	jne	whichmode1
	jmp	mode_0			;  yup
whichmode1:
	cmp	mode,1			; 132-col VGA text mode?
	jne	whichmode2
	jmp	mode_1			;  yup
whichmode2:
	mov	bx,mode			; locate the table entries
	add	bx,mode
	mov	dx,xga_requir[bx]	; does our setup support this mode?
	and	al,dl
	cmp	al,dl
	je	whichmode3
	jmp	nope			;  nope
whichmode3:
	mov	dx,xga_swidth[bx]	; collect and save the scan-line length
	mov	xga_xdots,dx
	mov	dx,xga_colors[bx]	; how many colors do we have?
	mov	xga_iscolors,dx		; save this
	cmp	dx,256			; 256-color mode?
	je	whichmode4
	cmp	dx,0			; 64K-color mode?
	je	whichmode5
					; 16-color modes
	mov	bx, offset xga_16read
	mov	xga_dotread,bx
	mov	bx, offset xga_16write
	mov	xga_dotwrite,bx
	mov	bx, offset xga_16linewrite
	mov	xga_linewrite,bx
	mov	bx,offset xga_normalineread
	mov	xga_lineread,bx
	jmp	mode_3
whichmode4:				; 256-color modes
	mov	bx, offset xga_256read
	mov	xga_dotread,bx
	mov	bx, offset xga_256write
	mov	xga_dotwrite,bx
	mov	bx, offset xga_256linewrite
	mov	xga_linewrite,bx
	mov	bx, offset xga_256lineread
	mov	xga_lineread,bx
	jmp	mode_3
whichmode5:				; 64K-color modes
	mov	bx, offset xga_64kread
	mov	xga_dotread,bx
	mov	bx, offset xga_64kwrite
	mov	xga_dotwrite,bx
	mov	bx, offset xga_256linewrite
	mov	xga_linewrite,bx
	mov	bx, offset xga_256lineread
	mov	xga_lineread,bx
	jmp	mode_3

mode_3:					; common graphics mode routines
	mov	dx,03c3h		; Enable VGA Address Code
	mov	al,1
	out	dx,al

	mov	si,offset xga_val	; point to start of values table
	mov	bx,mode			; use mode as an offset
model1: mov	dx,xga_reg_base		; get the base pointer
	mov	ah,0			; get the increment
	mov	al,cs:0[si]
	cmp	al,0ffh			; end of the table?
	je	model2			;  yup
	add	dx,ax
	cmp	al,0ah			; check for access type
	je	modsk2
	mov	al,cs:0[si+bx]		; get the value and OUT it
	out	dx,al
	jmp	short modsk3
modsk2:	mov	al,cs:1[si]		; get the value and OUT it
	mov	ah,cs:0[si+bx]
	out	dx,ax
modsk3:	add	si,xga_twidth		; try another table entry
	jmp	short model1
model2:

	mov	xga_isinmode,2		; pretend we're already in graphics
	call	xga_clear		; clear out the memory
	mov	xga_curbk,-1		; reset the bank counter

	mov	dx,xga_reg_base		; set up for final loads
	add	dx,0ah
	cmp	xga_iscolors,0		; "true color" mode?
	jne	modsk4			; nope - skip the funny palette load

	mov	ax,0064h		; make invisible
	out	dx,ax
	mov	ax,8055h		; border color
	out	dx,ax
	mov	ax,0066h		; palette mode
	out	dx,ax
	mov	ax,0060h		; start at palette 0
	out	dx,ax
	mov	ax,0061h		; ""
	out	dx,ax

	mov	cx,0			; ready to update the palette
	mov	al,065h			; palette update
	out	dx,al
	inc	dx			; palette data
model3:	mov	al,0			; zero out the...
	out	dx,al			;  red value
	out	dx,al			;  and the green value
	mov	al,cl			; klooge up the blue value
	and	al,1fh			; convert to 1,2,...1f
	shl	al,1			; convert to 2,4,...3e
	shl	al,1			; convert to 4,8,...7c
	shl	al,1			; convert to 8,16,..fd
	out	dx,al			; blue value
	inc	cx			; another palette value to go?
	cmp	cx,128
	jb	model3
	dec	dx			; back to normal

modsk4:	mov	ax,0ff64h		; make the palette visible
	out	dx,ax
	jmp	ok

mode_0:					; Set 80 column mode
	mov	dx,xga_reg_base		; Aperture Control
	add	dx,01h
	xor	al,al			; (disable the XGA 64K aperture)
	out	dx,al

	mov	dx,xga_reg_base		; Interrupt Disable
	add	dx,4
	xor	al,al
	out	dx,al

	mov	dx,xga_reg_base		; Clear Interrupts
	add	dx,5
	mov	al,0ffh
	out	dx,al

	test	xga_result,10h		; dual monitor setup?
	jz	mode_0a
	jmp	nope			;  yup - don't restore as a VGA
mode_0a:

	mov	dx,xga_reg_base		; Palette Mask
	add	dx,0ah
	mov	ax,0ff64h		; (Disable the XGA palette)
	out	dx,ax

	mov	dx,xga_reg_base		; Enable VFB, Prepare for Reset
	add	dx,0ah
	mov	ax,1550h
	out	dx,ax

	mov	dx,xga_reg_base		; Enable VFB, reset CRTC
	add	dx,0ah
	mov	ax,1450h
	out	dx,ax

	mov	dx,xga_reg_base		; Normal Scale Factors
	add	dx,0ah
	mov	ax,0051h
	out	dx,ax

	mov	dx,xga_reg_base		; Select VGA Oscillator
	add	dx,0ah
	mov	ax,0454h
	out	dx,ax

	mov	dx,xga_reg_base		; Ext Oscillator (VGA)
	add	dx,0ah
	mov	ax,7f70h
	out	dx,ax

	mov	dx,xga_reg_base		; Ensure no Vsynch Interrupts
	add	dx,0ah
	mov	ax,202ah
	out	dx,ax

	mov	dx,xga_reg_base		; Switch to VGA Mode
;;	add	dx,00h
	mov	al,1
	out	dx,al

	mov	dx,03c3h		; Enable VGA Address Code
	mov	al,1
	out	dx,al

	mov	ax,1202h		; select 400 scan lines
	mov	bl,30h
	int	10h
	mov	ax,0+3			; set video mode 3
	or	al,xga_clearvideo	; (might supress video-clearing)
	int	10h

	jmp	ok			; we're done

mode_1:					; 132-col VGA text mode
	test	xga_result,10h		; dual monitor setup?
	jz	mode_1a
	jmp	nope			;  yup - don't restore as a VGA
mode_1a:
	mov	dx,xga_reg_base
	add	dx,0ah
	mov	ax,1550h		; prepare CRTC for Reset
	out	dx,ax
	mov	ax,1450h		; Reset CRTC
	out	dx,ax
	mov	ax,0454h		; Select VGA Oscillator
	out	dx,ax
	mov	ax,1202h		; select 400 scan lines
	mov	bl,30h
	int	10h
	mov	ax,0+3			; set video mode 3
	or	al,xga_clearvideo	; (might supress video-clearing)
	int	10h

	mov	dx,xga_reg_base		; Prepare CRTC for Reset
	add	dx,0ah
	mov	al,50h
	out	dx,al
	inc	dx
	in	al,dx
	or	al,1
	out	dx,al

	mov	dx,xga_reg_base		; Prepare CRTC for Reset
	add	dx,0ah
	mov	al,50h
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0fdh
	out	dx,al

	mov	dx,xga_reg_base		; Reset CRTC
	add	dx,0ah
	mov	al,50h
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0fch
	out	dx,al

	mov	dx,xga_reg_base		; 132 column text mode
	mov	al,3
	out	dx,al

	mov	dx,xga_reg_base		; 132 column clock freq select
	add	dx,0ah
	mov	ax,0154h
	out	dx,ax
	mov	ax,8070h		; Select internal 132 col clock
	out	dx,ax

	mov	dx,xga_reg_base		; Disable VFB
	add	dx,0ah
	mov	al,50h
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0efh
	out	dx,al

	mov	dx,03d4h		; Enable VGA CRTC reg update
	mov	ax,11h
	out	dx,al
	inc	dx
	in	al,dx
	and	al,7fh
	out	dx,al

	mov	dx,03d4h		; Variations on VGA CRTC synchs
	mov	ax,0			; (I swear, that's what the manual
	out	dx,al			; says...)
	inc	dx
	mov	ax,0a4h
	out	dx,al

	mov	dx,03d4h		; Variations on VGA CRTC synchs
	mov	ax,1
	out	dx,al
	inc	dx
	mov	ax,83h
	out	dx,al

	mov	dx,03d4h		; Variations on VGA CRTC synchs
	mov	ax,2
	out	dx,al
	inc	dx
	mov	ax,84h
	out	dx,al

	mov	dx,03d4h		; Variations on VGA CRTC synchs
	mov	ax,3
	out	dx,al
	inc	dx
	mov	ax,83h
	out	dx,al

	mov	dx,03d4h		; Variations on VGA CRTC synchs
	mov	ax,4
	out	dx,al
	inc	dx
	mov	ax,90h
	out	dx,al

	mov	dx,03d4h		; Variations on VGA CRTC synchs
	mov	ax,5
	out	dx,al
	inc	dx
	mov	ax,80h
	out	dx,al

	mov	dx,xga_reg_base		; Variations on VGA CRTC synchs
	add	dx,0ah
	mov	ax,0a31ah
	out	dx,ax
	mov	ax,001bh
	out	dx,ax

	mov	dx,03d4h		; Variations on VGA CRTC synchs
	mov	ax,13h
	out	dx,al
	inc	dx
	mov	ax,42h
	out	dx,al

	mov	dx,03d4h		; Disable VGA CRTC reg update
	mov	al,11h
	out	dx,al
	inc	dx
	in	al,dx
	or	al,80h
	out	dx,al

	mov	dx,xga_reg_base		; Remove CTRC Reset
	add	dx,0ah
	mov	al,50h
	out	dx,al
	inc	dx
	in	al,dx
	or	al,3
	out	dx,al

	mov	dx,03c4h		; 8 bit characters
	mov	ax,1
	out	dx,al
	inc	dx
	in	al,dx
	or	al,1
	out	dx,al

	mov	dx,03dah		; Read sets Attr Ctlr flip flop
	in	al,dx

	mov	dx,003c0h		; Sets Attr Ctlr
	mov	al,13h
	out	dx,al
	xor	al,al			; Reg 13 to 00h
	out	dx,al
	mov	al,20h			; Restore Palette
	out	dx,al

	mov	ax,40h			; tell the BIOS we have 132 columns
	mov	es,ax
	mov	byte ptr es:[4ah],132	; set Bios screen width data area
	jmp	ok			; all done!

nope:
	mov	ax, offset xga_nullroutine	; null out the pixel rtns
	mov	xga_dotwrite,ax
	mov	xga_dotread,ax
	mov	xga_linewrite,ax
	mov	xga_lineread,ax
	mov	xga_isinmode,0
	mov	ax,0			; return failure
	ret
ok:
	mov	ax,mode			; remember the mode we're in
	mov	xga_isinmode,ax
	mov	ax,1			; return OK
	ret
xga_mode	endp

; **************** Function xga_getpixel(xdot, ydot) *******************

;	Return the color on the screen at the (xdot,ydot) point

xga_getpixel	proc	uses di si es, xdot:word, ydot:word
	mov	ax,0a000h		; EGA, VGA, MCGA starts here
	mov	es,ax			; save it here during this routine
	mov	cx,xdot 		; load up the registers
	mov	dx,ydot 		;  for the video routine
	call	xga_dotread 		; read the dot via the approved method
	ret				; we done.
xga_getpixel	endp

; ************** Function xga_putpixel(xdot, ydot, color) *******************

;	write the color on the screen at the (xdot,ydot) point

xga_putpixel	proc	uses di si es, xdot:word, ydot:word, xcolor:word
	mov	ax,0a000h		; EGA, VGA, MCGA starts here
	mov	es,ax			; save it here during this routine
	mov	cx,xdot 		; load up the registers
	mov	dx,ydot 		;  for the video routine
	mov	ax,xcolor		;  ...
	call	xga_dotwrite		; write the dot via the approved method
	ret				; we done.
xga_putpixel	endp

xga_getline	proc uses di si es, row:word, startcol:word, stopcol:word, pixels:word
	mov	cx,startcol		; first column
	mov	dx,row			; this row
	mov	ax, stopcol		; last pixel to read
	cmp	ax,cx			; anything to do?
	jle	xga_sk1			;  nope
	mov	di,offset pixels	; get the color for dot 'x'
	call	xga_lineread		; mode-specific lineread routine
xga_sk1:xor	ax,ax			; return 0
	ret
xga_getline	endp

xga_putline	proc uses di si es, row:word, startcol:word, stopcol:word, pixels:word
	mov	cx,startcol		; first column
	mov	dx,row			; this row
	mov	ax,0a000h		; EGA, VGA, MCGA, XGA starts here
	mov	es,ax			; save it here during this routine
	mov	ax, stopcol		; last column
	cmp	ax,cx			; anything to do?
	jle	xga_sk1			;  nope
	mov	si,offset pixels	; put the color for dot 'x'
	call	xga_linewrite		; mode-specific linewrite routine
xga_sk1:xor	ax,ax			; return 0
	ret
xga_putline	endp

	end
