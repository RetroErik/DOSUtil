        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include gsp669.inc
include vect3.inc
include kb.inc
include v.inc

public  _p1

;ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
; DATA
;ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
align 4
BIGPENTSPRLEN   = 17468
SMALLPENTSPRLEN = 64*43

MUZLOC0         = 0100h
MUZLOC1         = 0120h
MUZLOC2         = 0200h
MUZLOC3         = 0220h
MUZLOC4         = 0300h
MUZLOC5         = 0320h
MUZLOC6         = 0500h

dpalptr0        dd      ?               ; ptr to transparent small pent pal
bigpentsprptr   dd      ?               ; ptr to big pentagram compiled sprite
bigpentlocptr	dd	?		; ptr to current big pent index loc
smallpentsprptr dd      ?,?,?,?,?       ; ptr to small pentagram sprites
pagebaseptr	dd	?		; ptr to current video page base

bwssppalptr     dd      ?               ; ptr to b/w plasma palette
bwsspswtblptr   dd      ?               ; sine wave table ptr
bwssprasterbuf  dd      ?               ; raster sine wave sum buffer

p1m1seqrout     dd      p1m1sr0         ; sequence routine for b/w plasma

p1m0seqrout     dd      p1m0sr0         ; sequence routine for big pentagram
p1m0posrout     dd      p1m0pr3,p1m0pr0 ; big pentagram position routines

bigpentopageptr dd      ?,?             ; big pentagram erase locations
bigpentoloc     dw      4 dup(-1)       ; erase locations of big pentagram

bwsspwaveloc    db      0,0,0,0         ; locs of waves
bwsspwavedelta  dw      104h,0ff05h,102h,0ff02h
bwsspwavebounds dw      5fch,504h,301h,301h

vrtcntr         db      0               ;                                    |
ovrtcntr        db      0               ;                                    |
vrttime         db      ?               ; vertical retraces per frame

posfactor       db      128             ; position routine xfer factor

bigpentcntr	db	?		; loop counter for big pent erase

pfieldpageindex db	0		; pentagram field page index
pfieldpagetbl   db      0,80h           ; page pable for pentagram field
pfieldoff       db      0,0             ; offset of screens for pent field
pfieldframe     db      0,0             ; pentagram field frame index
pfieldframed    db      0               ; pentagram field frame delta
pfieldframetbl  db      0,1,2,3,4,3,2,1

bwssppageindex  db      0               ; b/w sinesum plasma page index
bwssppagetbl    db      0,40h           ; b/w sinesum plasma page table
bwsspyoff       db      98              ; Y offset in b/w plasma
bwsspylen       db      2               ; Y size to do in b/w plasma
bwsspxoff       db      0               ; X offset in b/w plasma

pr2x            db      2ah
pr2y            db      0
pr2xd           db      0
pr2yd           db      -6

pr1x            db      -38h
pr1y            db      0
pr1xd           db      0
pr1yd           db      5

pr0x            db      -2ah
pr0y            db      0
pr0xd           db      0
pr0yd           db      6

mirrorpal       db      0, 0, 0, 3, 1, 0, 7, 4, 1, 12, 7, 2, 16, 9, 3, 20
                db      12, 4, 24, 15, 5, 29, 17, 7, 33, 20, 8, 37, 23, 9, 41, 25
                db      10, 46, 28, 11, 50, 31, 12, 54, 33, 13, 58, 36, 14, 63, 39, 16
                db      6, 0, 12, 6, 0, 12, 6, 0, 12, 6, 0, 12, 6, 0, 12, 6
                db      0, 12, 6, 0, 12, 6, 0, 12, 0, 0, 6, 0, 0, 7, 0, 0
                db      8, 0, 0, 10, 0, 0, 11, 0, 0, 13, 0, 0, 14, 0, 0, 16
                db      17, 0, 26, 17, 0, 26, 17, 0, 26, 17, 0, 26, 17, 0, 26, 17
                db      0, 26, 17, 0, 26, 17, 0, 26

;ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
; CODE
;ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p1ir4:                                  ; transition, slide to mirror palette
        cld
        push bx ecx esi edi
        mov dx,3c8h
        @outb 0
        mov edi,_cpalptr
        mov esi,edi
        mov ecx,28h*3
        inc edx
        rep outsb
        mov esi,offset mirrorpal
        mov cl,28h*3
        mov bl,1
        call _slidebytes
        jnc short p1ir4d
        mov _vrtrout,offset _ret
p1ir4d:
        pop edi esi ecx bx
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p1ir2:                                  ; only increment retrace timer
        inc vrtcntr
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p1ir3:                                  ; set 20h colors of palette at 40h
        cld
        push ecx esi
        mov dx,3c8h
        @outb 40h
        mov esi,_cpalptr
        add esi,40h*3
        inc edx
        mov ecx,20h*3
        rep outsb
        inc vrtcntr
        pop esi ecx
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p1ir1:                                  ; set 20h colors of palette at 60h
        cld
        push ecx esi
        mov dx,3c8h
        @outb 60h
        mov esi,_cpalptr
        add esi,60h*3
        inc edx
        mov ecx,20h*3
        rep outsb
        inc vrtcntr
        pop esi ecx
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p1ir0:                                  ; set double width screen
        mov dx,3d4h
        @outw 5013h
        mov _vrtrout,offset _ret
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
_p1:
        mov eax,'p10d'                  ; load and allocate data
        call _loaddata
        mov bigpentsprptr,eax
        add eax,BIGPENTSPRLEN
        mov smallpentsprptr[0],eax
        add eax,SMALLPENTSPRLEN
        mov smallpentsprptr[4],eax
        add eax,SMALLPENTSPRLEN
        mov smallpentsprptr[8],eax
        add eax,SMALLPENTSPRLEN
        mov smallpentsprptr[12],eax
        add eax,SMALLPENTSPRLEN
        mov smallpentsprptr[16],eax
        add eax,SMALLPENTSPRLEN
        mov dpalptr0,eax
        add eax,20h*3
        mov bwsspswtblptr,eax

        mov eax,320+64*3
        call _gethimem
        mov bwssprasterbuf,eax
        add eax,320
        mov bwssppalptr,eax

waitl0:                                 ; wait for end transition to this part
        cmp _vrtrout,offset _ret
        jne waitl0

        mov eax,'muz2'                  ; load up next muzik
        call _loadmuzik

        call _gsp669_play               ; start muzik playing

        mov esi,_vidptr0                ; transfer page 0 to double width
        mov edi,_vidptr2
        mov bl,200
p1i0l0:
        mov ecx,80
        rep movsb
        add edi,80
        dec bl
        jnz p1i0l0

	mov dx,3ceh			; read plane select index
        @outb 4
	mov dl,0d4h			; set double width screen mode
        mov ax,800ch
        cli
        out dx,ax
        mov _vrtrout,offset p1ir0
        sti

waitl1:                                 ; wait for it to take effect
        cmp _vrtrout,offset _ret
        jne waitl1

        mov esi,_vidptr2                ; fill lower page with pentagrams
        lea edi,[esi+80]
        mov bl,200
p1i0l1:
        mov ecx,80
        rep movsb
        add edi,80
        add esi,80
        dec bl
        jnz p1i0l1

        mov edi,_vidptr0                ; fill upper page with pentagrams
        mov esi,_vidptr2
        mov ecx,160*200
        rep movsb

        mov edi,_cpalptr                ; set single color for big pentagrams
        add edi,60h*3
        mov eax,311f0dh
        mov ecx,20h
p1i0l2:
        stosd
        dec edi
        loop p1i0l2

        mov _vrtrout,offset p1ir1       ; set palette setting routine

waitl2:                                 ; wait for palette to change
        cmp vrtcntr,0
        je waitl2

        mov _vrtrout,offset p1ir2       ; set verical retrace timer
        mov word ptr vrtcntr,1          ; clear vertical retrace count

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Interfering pentagrams on field of smaller ones
p1m0:
        movzx ebx,pfieldpageindex       ; erase old big pentagrams
        lea eax,[ebx*4+bigpentoloc]
	cmp word ptr [eax],-1
        je short p1m0f3
        mov ebx,bigpentopageptr[ebx*4]
        mov pagebaseptr,ebx
        call p1m0r2
p1m0f3:

        movzx eax,pfieldpageindex       ; get base page loc of pentagram field
        mov ebp,_vidptr0[eax*8]
        movzx ebx,pfieldoff[eax]
        sub bl,10h
        jnc short p1m0f0
        mov bl,50h
p1m0f0:
        mov pfieldoff[eax],bl
        add ebp,ebx
        mov pagebaseptr,ebp
        mov bigpentopageptr[eax*4],ebp

        lea edi,[ebp+57*160]            ; copy column of previous pentagrams
        lea esi,[ebp+7*160+10h]
        mov dx,3c5h
        @outb 0fh
        mov dl,0ceh
        @outw 4105h
        call p1m0r0
        cmp bl,30h
        ja short p1m0f1
        sub esi,50*3*160
        sub edi,50*3*160-60h
        call p1m0r0
p1m0f1:
        @outw 4005h
	@outb 4 			; read plane select index

        movzx eax,pfieldpageindex       ; put new pentagram frame
        movzx ecx,pfieldframe[eax]
        add cl,pfieldframed
        and cl,7
        mov pfieldframe[eax],cl
        mov cl,pfieldframetbl[ecx]
        mov esi,smallpentsprptr[ecx*4]
        lea edi,[ebp+7*160]
        mov dl,0c5h
        call p1m0r1
        cmp bl,30h
        ja short p1m0f2
        sub esi,64*43
        add edi,60h
        call p1m0r1
p1m0f2:

        mov ah,vrtcntr                  ; get vertical retrace length of frame
        mov al,ovrtcntr
        mov ovrtcntr,ah
        sub ah,al
        mov vrttime,ah

        mov al,posfactor                ; get position of big pentagrams
        or al,al
        jz short p1m0f4
        sub al,ah
        jbe short p1m0f6
        mov posfactor,al
        movzx ebp,al
        call p1m0posrout[0]
        imul eax,ebp
        sar eax,7
        mov esi,eax
        imul ebx,ebp
        sar ebx,7
        mov edi,ebx
        call p1m0posrout[4]
        dec ebp
        xor bp,7fh
        imul eax,ebp
        sar eax,7
        add eax,esi
        imul ebx,ebp
        sar ebx,7
        add ebx,edi
        jmp short p1m0f5
p1m0f6:
        mov posfactor,0
p1m0f4:
        call p1m0posrout[4]
p1m0f5:
        lea ebx,[ebx*4+ebx]
        shl ebx,7
        add ebx,eax

        mov ecx,ebx                     ; put big pentagrams
        neg ecx
        add bx,4138h
        add cx,4138h
        movzx eax,pfieldpageindex
        lea eax,[eax*4+bigpentoloc]
        mov word ptr [eax],bx
        mov word ptr [eax+2],cx
        call p1m0r2

	mov dx,3d4h			; set new page
	movzx ecx,pfieldpageindex
        mov ah,pfieldpagetbl[ecx]
        mov al,0ch
        mov bh,pfieldoff[ecx]
        mov bl,0dh
        cli
        out dx,ax
        mov eax,ebx
        out dx,ax
        mov ah,vrtcntr
        sti
	xor cl,1			; flip page index
	mov pfieldpageindex,cl

waitl3:                                 ; wait for page flip to take effect
        cmp ah,vrtcntr
        je waitl3

        jmp p1m0seqrout                 ; jump to appropriate routine

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p1m0sr0:                                ; wait then set bg moving
        cmp _muzloc,MUZLOC0
        jb p1m0
        mov pfieldframed,1
        mov p1m0seqrout,offset p1m0sr1
        jmp p1m0
;-----------------------------------------------------------------------------
p1m0sr1:                                ; wait then set new movement pattern
        cmp _muzloc,MUZLOC1
        jb p1m0
        mov posfactor,128
        mov p1m0posrout[0],offset p1m0pr0
        mov p1m0posrout[4],offset p1m0pr1
        mov p1m0seqrout,offset p1m0sr2
        jmp p1m0
;-----------------------------------------------------------------------------
p1m0sr2:                                ; wait then set big pents transparent
        cmp _muzloc,MUZLOC2
        jb p1m0
        mov _vrtrout,offset p1ir1
        mov p1m0seqrout,offset p1m0sr3
        jmp p1m0
;-----------------------------------------------------------------------------
p1m0sr3:                                ; wait for transparency to be done
        mov edi,_cpalptr
        add edi,60h*3
        mov esi,dpalptr0
        mov ecx,32*3
        mov bl,vrttime
        call _slidebytes
        jnc p1m0
        mov _vrtrout,offset p1ir2
        mov p1m0seqrout,offset p1m0sr4
        jmp p1m0
;-----------------------------------------------------------------------------
p1m0sr4:                                ; wait then set new movement pattern
        cmp _muzloc,MUZLOC3
        jb p1m0
        mov posfactor,128
        mov p1m0posrout[0],offset p1m0pr1
        mov p1m0posrout[4],offset p1m0pr2
        mov p1m0seqrout,offset p1m0sr5
        jmp p1m0
;-----------------------------------------------------------------------------
p1m0sr5:                                ; wait then phade out pent field
        cmp _muzloc,MUZLOC4
        jb p1m0
	mov _vrtrout,offset p1ir3
        mov p1m0seqrout,offset p1m0sr6
        jmp p1m0
;-----------------------------------------------------------------------------
p1m0sr6:                                ; wait for phade to end
	mov edi,_cpalptr
	add edi,40h*3
        mov esi,_clearpalptr
        mov ecx,32*3
        mov bl,vrttime
        call _slidebytes
        jnc p1m0
        mov _vrtrout,offset p1ir2
        mov p1m0seqrout,offset p1m0sr7
        jmp p1m0
;-----------------------------------------------------------------------------
p1m0sr7:                                ; wait then set movement to final loc
        cmp _muzloc,MUZLOC5
        jb p1m0
        mov posfactor,128
        mov p1m0posrout[0],offset p1m0pr2
        mov p1m0posrout[4],offset p1m0pr3
        mov p1m0seqrout,offset p1m0sr8
        jmp p1m0
;-----------------------------------------------------------------------------
p1m0sr8:                                ; wait for big pents at final loc
        cmp posfactor,0
        jne p1m0

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p1i1:
        mov vrtcntr,0                   ; reset counter for delay

        mov edi,_vidptr2                ; clear page 2
        mov dx,3c5h
        @outb 0fh
        mov ecx,1000h
        xor eax,eax
        rep stosd

        mov dl,0d4h                     ; normal screen width
        @outw 2813h
        @outw 000dh                     ; set page 2
        @outw 800ch

        mov edi,bwssppalptr             ; set up b/w palette
        mov esi,edi
        mov ecx,20h
        xor edx,edx
        mov ebx,2f2f2f2fh
        xor eax,eax
p1i1l0:
        stosd
        stosd
        stosd
        stosd
        stosd
        stosd
        xchg ebx,eax
        xchg edx,ebx
        loop p1i1l0
        mov ecx,100h
        xor al,al
        mov ah,vrtcntr                  ; change pal on vertical retrace
waitl5:
        cmp ah,vrtcntr
        je waitl5
        call _setcpal

        mov edi,_vidptr0                ; clean up all pages
        mov dx,3c5h
        @outb 0fh
        mov ecx,4000h
        xor eax,eax
        rep stosd

        mov ebp,80*148                  ; put pentagram outline to pg 0 and 1
        mov esi,80
        mov bx,2020h
        mov edi,_vidptr0
        add edi,82eh
        mov cx,11h
        call bigpentsprptr
        mov edi,_vidptr0
        add edi,87eh
        mov cx,11h
        call bigpentsprptr
        mov edi,_vidptr1
        add edi,82eh
        mov cx,11h
        call bigpentsprptr
        mov edi,_vidptr1
        add edi,87eh
        mov cx,11h
        call bigpentsprptr

        mov dl,0d5h                     ; switch to page 1
        @outb 40h
        mov al,vrtcntr                  ; wait for page flip to take effect
waitl7:
        cmp al,vrtcntr
        je waitl7

        mov eax,'p11d'                  ; load and put transition bg pic
        call _loaddata

        mov edi,_vidptr2                ; put mirror bitmap to pages 2 and 3
        add edi,80*21
        mov esi,eax
        mov ebx,80*168
        call _pbmodex
        mov edi,_vidptr3
        add edi,80*21
        call _pbmodex

waitl6:                                 ; delay should be at most 60 retraces
        cmp vrtcntr,80
        jb waitl6

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Black and white sinewave sum plasma
p1m1:
        mov edi,3                       ; move waves and change their deltas
p1m1l2:
        mov ax,bwsspwavedelta[edi*2]
        mov bx,bwsspwavebounds[edi*2]
        add bwsspwaveloc[edi],al
        add al,ah
        cmp al,bl
        je short p1m1l2f0
        cmp al,bh
        jne short p1m1l2f1
p1m1l2f0:
        neg ah
p1m1l2f1:
        mov bwsspwavedelta[edi*2],ax
        sub edi,1
        jnc p1m1l2

        mov ebp,bwsspswtblptr           ; precalculate X sine wave sums
        mov edi,bwssprasterbuf
        mov esi,edi
        movzx ebx,byte ptr bwsspwaveloc[0]
        movzx ecx,byte ptr bwsspwaveloc[1]
        mov dh,4
p1m1l0:
        mov dl,20
p1m1l0l0:
rept 4
        mov al,[ebp+ebx]
        add al,[ebp+ecx]
        stosb
        add bl,4
        add cl,4
endm
        dec dl
        jnz p1m1l0l0
        sub bl,3fh
        sub cl,3fh
        dec dh
        jnz p1m1l0

        movzx eax,bwssppageindex        ; draw b/w thingy to screen
        mov edi,_vidptr0[eax*4]
        movzx eax,bwsspxoff
        add esi,eax
        mov ch,1
p1m1l1:
        mov dx,3c5h
        @outb ch
        movzx edx,bwsspxoff
        mov bh,byte ptr bwsspwaveloc[3]
        mov bl,byte ptr bwsspwaveloc[2]
        mov al,bwsspyoff
        add bh,al
        add bh,al
        add bl,al
        mov cl,bwsspylen
        call p1m1r0
        movzx eax,bwsspyoff
        lea eax,[eax*4+eax]
        lea eax,[eax*4]
        lea edi,[edi+eax*8]
        mov cl,bwsspylen
        call p1m1r0
        sub edi,200*80
        add esi,80
        shl ch,1
        and ch,0fh
        jnz p1m1l1

        or dl,dl                        ; put part of bg to opening screen
        jz short p1m1f0
        mov ebp,edx
        mov dx,3c5h
        @outb 0fh
        mov dl,0ceh
        @outw 4105h
        add edi,40
        sub edi,ebp
        mov esi,_vidptr2
        add esi,40
        sub esi,ebp
        call p1m1r1
        lea edi,[edi-200*80+ebp*2-2]
        lea esi,[esi-200*80+ebp*2-2]
        call p1m1r1
        inc edx
        @outb 40h
p1m1f0:

        mov dx,3d5h                     ; set new page
        movzx ebx,bwssppageindex
        @outb bwssppagetbl[ebx]
        xor bl,1
        mov bwssppageindex,bl

        mov al,vrtcntr                  ; wait for a vertical retrace
waitl4:
        cmp al,vrtcntr
        je waitl4

        jmp p1m1seqrout                 ; jump to appropriate routine

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p1m1sr0:                                ; move b/w plasma onto screen
        add bwsspylen,2
        sub bwsspyoff,2
        jnz p1m1
        mov p1m1seqrout,offset p1m1sr1
        jmp p1m1
;-----------------------------------------------------------------------------
p1m1sr1:                                ; wait for muzik meta point
        cmp _muzloc,MUZLOC6
        jb p1m1
        mov p1m1seqrout,offset p1m1sr2
        jmp p1m1
;-----------------------------------------------------------------------------
p1m1sr2:                                ; move b/w plasma off screen
        add dword ptr p1m1r0m0[-4],4
        add dword ptr p1m1r0m1[-4],4
        mov al,bwsspxoff
        inc al
        mov bwsspxoff,al
        cmp al,40
        jb p1m1

;-----------------------------------------------------------------------------
        mov dx,3d5h                     ; set page 2
        @outb 80h

        mov eax,_ohimembase             ; clean up high memory base ptr
        mov _himembase,eax
        mov _vrtrout,offset p1ir4       ; set transition retrace routine

        ret

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p1m0pr0:                                ; position routine 0
        mov edx,1
        movsx ecx,pr0yd
        movsx eax,pr0y
        call p1m0prr0
        mov pr0yd,cl
        mov pr0y,al
        mov ebx,eax
        movsx ecx,pr0xd
        movsx eax,pr0x
        call p1m0prr0
        mov pr0xd,cl
        mov pr0x,al
        ret
;-----------------------------------------------------------------------------
p1m0pr1:                                ; position routine 1
        mov edx,1
        movsx ecx,pr1yd
        movsx eax,pr1y
        call p1m0prr0
        mov pr1yd,cl
        mov pr1y,al
        mov ebx,eax
        movsx ecx,pr1xd
        movsx eax,pr1x
        call p1m0prr0
        mov pr1xd,cl
        mov pr1x,al
        ret
;-----------------------------------------------------------------------------
p1m0pr2:                                ; position routine 2
        mov edx,1
        movsx ecx,pr2yd
        movsx eax,pr2y
        call p1m0prr0
        mov pr2yd,cl
        mov pr2y,al
        mov ebx,eax
        mov dl,2
        movsx ecx,pr2xd
        movsx eax,pr2x
        call p1m0prr0
        mov pr2xd,cl
        mov pr2x,al
        ret
;-----------------------------------------------------------------------------
p1m0pr3:                                ; position routine 3
        xor eax,eax
        xor ebx,ebx
        ret
;-----------------------------------------------------------------------------
p1m0prr0:                               ; pull a delta in a locs 0 direction
        add eax,ecx
        jz _ret
        or eax,eax
        js short p1m0prr0f0
        sub ecx,edx
        ret
p1m0prr0f0:
        add ecx,edx
        ret

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p1m0r0:                                 ; copy column of 3 small pentagrams
        mov ah,3
p1m0r0l0:
        mov al,43
p1m0r0l0l0:
        mov ecx,10h
        rep movsb
        add edi,90h
        add esi,90h
        dec al
        jnz p1m0r0l0l0
        add edi,7*160
        add esi,7*160
        dec ah
        jnz p1m0r0l0
        ret

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p1m0r1:                                 ; put new small pentagram sprite
        mov al,1
p1m0r1l0:
        out dx,al
        mov ah,43
p1m0r1l0l0:
        mov ecx,10h
        rep movsb
        add edi,90h
        dec ah
        jnz p1m0r1l0l0
        sub edi,43*160
        shl al,1
        and al,0fh
        jnz p1m0r1l0
        ret

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p1m0r2: 				; put 4 big interfering pentagrams
        mov bigpentcntr,2
        mov ebp,160*148
        mov esi,160
        mov dh,3
        mov bx,2020h
p1m0r2l0:
        mov bigpentlocptr,eax
        movzx edi,word ptr [eax]
        mov eax,edi
        and eax,3
        mov cl,_vidbitloc2[eax]
        mov ch,al
        shr edi,2
        add edi,pagebaseptr
        call bigpentsprptr
        mov eax,bigpentlocptr
        add eax,2
        dec bigpentcntr
        jnz p1m0r2l0
        ret

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p1m1r0:                                 ; put a part of b/w plasma
        movzx eax,bh
        movzx ebx,bl
        mov ah,[ebp+eax]
        add ah,[ebp+ebx]
        mov bh,al
        inc bl
        add bh,2
        db 0e9h,0,0,0,0         ; jmp near ptr $+5
p1m1r0m0:
rept 40
        lodsb
        add al,ah
        stosb
endm
        lea edi,[edi+edx*2]
        db 0e9h,0,0,0,0         ; jmp near ptr $+5
p1m1r0m1:
rept 40
        lodsb
        add al,ah
        stosb
endm
        lea esi,[esi+edx*2-80]
        dec cl
        jnz p1m1r0
        ret

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p1m1r1:                                 ; copy part of bg to opening screen
        mov ecx,25
p1m1r1l0:
irp temp,<0,1,2,3,4,5,6,7>
        mov al,[esi+&temp*80]
        mov [edi+&temp*80],al
        mov al,[esi+&temp*80+1]
        mov [edi+&temp*80+1],al
endm
        add edi,8*80
        add esi,8*80
        dec ecx
        jnz p1m1r1l0
        ret

code32	ends
        end

