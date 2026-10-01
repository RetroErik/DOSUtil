        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include gsp669.inc
include vect3.inc
include kb.inc
include v.inc

public  _p3

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
align 4
BALLSLEN        = 127000

MUZLOC0         = 0c00h

ballstblptr     dd      ?               ; ptrs to balls addx table
ballsoldptr     dd      ?,?             ; erase areas buffer ptrs
ballsvidptrcur  dd      ?               ; current video page ptr
ballsoldptrcur  dd      ?               ; current erase areas buffer ptr
ballsdestpalptr dd      ?               ; ptr to pal to slide to

fallbgptr       dd      ?               ; ptr to bg for falling pieces
fallpicptr      dd      ?,?,?,?         ; ptrs to falling pics
fallrout        dd      p3m0r4d,p3m0r4c,p3m0r4b,p3m0r4a

p3m0seqrout     dd      p3m0sr0         ; sequence routine for glass balls
p3m0rout        dd      _ret,p3m0r2,p3m0r1
p3m0r1rout      label   dword           ; entry points in ball raster put code
irp temp,<16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0>
                dd      p3m0r1l0f0+&temp*P3M0R1LEN
endm
p3m0r2rout      label   dword           ; entry points in other ball put code
irp temp,<16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0>
                dd      p3m0r2l0f0+&temp*P3M0R2LEN
endm

ballsrot        dw      0,0,0
ballscoords     dw      5, 0,80,0, 76,25,0, 47,-65,0, -47,-65,0, -76,25,0
ballscoordsrot  dw      ?, 5*5 dup(?)
ballsdata       dw      5*2 dup(?)

vrtcntr         db      0
ovrtcntr        db      0

ballspageindex  db      1               ; glass balls page index
ballspagetbl    db      0,40h           ; glass balls page offset table
ballsoldnum     db      0,0             ; number of erase areas in buffer
ballsnumcur     db      ?               ; current number of erase areas
ballscoloradd   db      ?               ; add to color when drawing ball
ballsputrout    db      5 dup(0)        ; routine to put ball
ballscolor      db      5 dup(40h),?    ; table of colors to add for each ball
ballsindex      db      5               ; index of ball being worked on
ballszdelta     db      0               ; current Z offset delta
ballsydelta     db      0               ; current Y offset delta
ballsxdelta     db      0               ; current X offset delta
ballsdeltawait  db      0               ; counter for delta change

fallindex       db      4               ; index of falling piece
fallycntr       db      0               ; Y size of falling piece
fallxcntr       db      ?               ; X size of falling piece

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
p3ir0:                                  ; only increment retrace timer
        inc vrtcntr
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
p3ir1:                                  ; set colors and slide
        cld
        push bx ecx esi edi
        mov edi,_cpalptr
        add edi,60h*3
        mov esi,edi
        mov dx,3c8h
        @outb 60h
        inc edx
        mov ecx,40h*3
        rep outsb
        mov esi,ballsdestpalptr
        mov ecx,40h*3
        mov bl,1
        call _slidebytes
        jnc short p3ir1f0
        mov _vrtrout,offset p3ir0
p3ir1f0:
        inc vrtcntr
        pop edi esi ecx bx
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
_p3:
        mov eax,'p30d'                  ; load and allocate data
        call _loaddata
        mov ballstblptr,eax
        add eax,BALLSLEN
        mov _v0r0sincosptr,eax
;       add eax,1280
;       mov fallbgptr,eax

        mov eax,6*4*2+160*100*4 +64000
        call _gethimem
        mov ballsoldptr[0],eax
        add eax,6*4
        mov ballsoldptr[4],eax
        add eax,6*4
        mov fallpicptr[0],eax
        add eax,160*100
        mov fallpicptr[4],eax
        add eax,160*100
        mov fallpicptr[8],eax
        add eax,160*100
        mov fallpicptr[12],eax
        add eax,160*100         ;
        mov fallbgptr,eax       ;

        mov edi,eax             ;
        mov ecx,16000           ;
        xor eax,eax             ;
        rep stosd               ;

        mov _v0r0perspective,100        ; set up rotation vars
        mov _v0r0tx,60
        mov _v0r0ty,20
        mov _v0r0tz,160

        mov dx,3ceh                     ; get 4 pics for fall into screen
        @outb 4
        inc edx
        mov edi,fallpicptr[0]
        xor esi,esi
        call p3i0r0
        mov edi,fallpicptr[4]
        mov esi,80*100+40
        call p3i0r0
        mov edi,fallpicptr[8]
        mov esi,40
        call p3i0r0
        mov edi,fallpicptr[12]
        mov esi,80*100
        call p3i0r0

        mov edi,_vidptr2                ; copy page 0 to page 2
        mov esi,_vidptr0
        mov dx,3c5h
        @outb 0fh
        mov dl,0ceh
        @outw 4105h
        mov ecx,4000h
        rep movsb

        mov edi,ballstblptr             ; set up ball addresses
        mov ecx,63
        mov ebx,edi
        mov eax,edi
p3i0l0:
        mov eax,[edi]
        add eax,ebx
        stosd
        loop p3i0l0

        mov edx,0a8000h                 ; set up selectors for zoom routine
        mov ax,_sel[0]
        call _setselector
        @php edx,fallpicptr[0]
        mov ax,_sel[2]
        call _setselector

        mov _vrtrout,offset p3ir0       ; set retrace timer routine

        mov edi,_cpalptr                ; set up some colors
        lea esi,[edi+20h*3]
        add edi,0a0h*3
        mov ecx,40h
p3i0l1:
        mov word ptr [edi],3f3fh
        mov byte ptr [edi+2],0
        add edi,3
        loop p3i0l1
        mov ecx,40h
        mov al,60h
        mov ah,vrtcntr
waitl1:
        cmp ah,vrtcntr
        je waitl1
        call _setcpal

        mov dx,3ceh
        @outw 4005h

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Refracting glass balls
p3m0:
        movzx ebx,ballspageindex        ; set up some ptrs
        mov eax,_vidptr0[ebx*4]
        mov ballsvidptrcur,eax
        mov eax,ballsoldptr[ebx*4]
        mov ballsoldptrcur,eax
        mov ballsnumcur,0

        movzx ebp,fallindex             ; put falling pieces
        cmp ebp,3
        ja p3m0f2
        movzx ebx,fallycntr
        dec bl
        mov fallycntr,bl
        imul eax,ebx,160
        mov ecx,100
        cdq
        idiv ecx
        mov fallxcntr,al
        call fallrout[ebp*4]
        movzx ecx,ballspageindex
        movzx edx,ballsoldnum[ecx]
        inc ballsoldnum[ecx]
        lea edx,[edx*4]
        add edx,ballsoldptr[ecx*4]
        mov [edx],ebx
        push eax

        mov dx,3c5h
        push esi
        push edi
        call p3m0r3
        pop edi
        inc edi
        call p3m0r3
        pop esi
        mov edi,esi
        add esi,fallbgptr
        add edi,_vidptr2
        mov al,11h
p3m0l5:
        out dx,al
        mov ecx,40
        rep movsb
        sub edi,40
        add esi,80*200-40
        rol al,1
        jnc p3m0l5

        pop eax
        movzx ecx,fallycntr
        jecxz p3m0f2
        shl ecx,16
        mov cl,fallxcntr
        mov ebx,6400a0h
        movzx esi,fallindex
        imul esi,160*100
        xor edi,edi
        mov es,_sel[0]
        mov ds,_sel[2]
        call _psbm
        mov ax,cs:_seldata
        mov es,ax
        mov ds,ax
p3m0f2:

        mov ebp,ballsvidptrcur          ; erase old balls
        mov dx,3c5h
        @outb 0fh
        mov dl,0ceh
        @outw 4105h
        mov edx,ballsoldptrcur
        movzx ebx,ballspageindex
        mov bl,ballsoldnum[ebx]
        call p3m0r0
p3m0f0:

        movsx eax,ballszdelta           ; move balls on Z, Y, and X
        add _v0r0tz,ax
        movsx ebx,ballsydelta
        add _v0r0ty,bx
        movsx ecx,ballsxdelta
        add _v0r0tx,cx
        mov dl,ballsdeltawait
        inc dl
        and dl,7
        mov ballsdeltawait,dl
        jnz short p3m0f1
        cmp _v0r0tz,190
        setl dl
        shl dl,1
        sub dl,1
        add al,dl
        cmp _v0r0ty,0
        setl dl
        shl dl,1
        sub dl,1
        add bl,dl
        cmp _v0r0tx,0
        setl dl
        shl dl,1
        sub dl,1
        add cl,dl
        mov ballszdelta,al
        mov ballsydelta,bl
        mov ballsxdelta,cl
p3m0f1:

        movzx ebx,ballsrot[0]           ; rotate glass balls
        add ebx,1
        and bx,1ffh
        mov ballsrot[0],bx
        movzx ecx,ballsrot[2]
        add ecx,2
        and cx,1ffh
        mov ballsrot[2],cx
        movzx edx,ballsrot[4]
        add edx,4
        and dx,1ffh
        mov ballsrot[4],dx
        call _v0rot0init
        mov edi,offset ballscoordsrot
        mov esi,offset ballscoords
        call _v0rot0b

        mov edi,ballstblptr             ; set up balls for put
        mov esi,offset ballscoordsrot+2
        mov ebx,4
p3m0l2:
        movzx eax,word ptr [esi+4]
        sub eax,75
        shr eax,2
        cmp eax,63
        jb short p3m0l2f0
        mov byte ptr ballsdata[ebp*4+1],255
        jmp short p3m0l2c
p3m0l2f0:
        mov byte ptr ballsdata[ebx*4+1],al
        mov ebp,[edi+eax*4]
        movzx edx,byte ptr [ebp+1]
        movzx ecx,byte ptr [ebp]
        shr edx,1
        shr ecx,1
        movsx eax,word ptr [esi+8]
        add eax,100
        sub eax,edx
        imul eax,320
        movsx ebp,word ptr [esi+6]
        sub ebp,ecx
        lea eax,[eax+ebp+160]
        mov word ptr ballsdata[ebx*4+2],ax
        mov byte ptr ballsdata[ebx*4],bl
p3m0l2c:
        add esi,10
        sub bl,1
        jnc p3m0l2

        mov ebp,1                       ; sort balls by depth
        mov edx,offset ballsdata+3*4
p3m0l3:
        mov edi,edx
        lea esi,[edi+4]
        mov ecx,ebp
        mov eax,[edi]
p3m0l3l0:
        cmp ah,[edi+ecx*4+1]
        ja short p3m0l3l0d
        dec ecx
        jnz p3m0l3l0
p3m0l3l0d:
        rep movsd
        mov [edi],eax
        sub edx,4
        inc ebp
        cmp ebp,5
        jb p3m0l3

        mov esi,4                       ; put glass balls to screen
        mov dx,3ceh
        @outw 4005h
        @outb 4
p3m0l1:
        movzx ebp,byte ptr ballsdata[esi*4+1]
        cmp ebp,62
        ja p3m0l1c

        push esi
        lea ebp,[ebp*4]
        add ebp,ballstblptr
        mov ebp,[ebp]
        movzx ecx,byte ptr ballsdata[esi*4]
        mov al,ballscolor[ecx]
        mov ballscoloradd,al

        movzx edx,byte ptr [ebp]
        dec edx
        shl edx,16
        movzx ebx,word ptr ballsdata[esi*4+2]
        mov edi,ebx
        shr edi,2
        movzx eax,byte ptr ballsputrout[ecx]
        push edi ebp
        add ebp,2
        call p3m0rout[eax*4]
        pop ebp edi

        mov bx,[ebp]
        shr bh,2
        add bh,2
        movzx ecx,ballsnumcur
        mov eax,ballsoldptrcur
        mov [eax+ecx*4],di
        mov [eax+ecx*4+2],bx
        inc ecx
        mov ballsnumcur,cl

        pop esi
p3m0l1c:
        sub esi,1
        jnc p3m0l1

        mov dx,3d5h                     ; set new page
        movzx ebx,ballspageindex
        mov al,ballsnumcur
        mov ballsoldnum[ebx],al
        @outb ballspagetbl[ebx]
        xor bl,1
        mov ballspageindex,bl

        mov al,vrtcntr                  ; wait for a vertical retrace
waitl0:
        cmp al,vrtcntr
        je waitl0

        jmp p3m0seqrout                 ; jump to appropriate sequence routine

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p3m0sr0:                                ; wait for slide to normal to end
        cmp _vrtrout,offset p3ir0
        jne p3m0
        movzx eax,ballsindex
        mov ballscolor[eax],0
        sub al,1
        jc p3m0sr0f0
        mov byte ptr ballsputrout[eax],1
        mov ballsindex,al
        mov p3m0seqrout,offset p3m0sr1
        jmp p3m0
p3m0sr0f0:
        mov p3m0seqrout,offset p3m0sr4
        jmp p3m0
;-----------------------------------------------------------------------------
p3m0sr1:                                ; set slide to single color
        mov eax,_cpalptr
        add eax,0a0h*3
        mov ballsdestpalptr,eax
        mov _vrtrout,offset p3ir1
        mov p3m0seqrout,offset p3m0sr2
        jmp p3m0
;-----------------------------------------------------------------------------
p3m0sr2:                                ; wait for end slide to single color
        cmp _vrtrout,offset p3ir0
        jne p3m0
        movzx eax,ballsindex
        mov byte ptr ballsputrout[eax],2
        mov p3m0seqrout,offset p3m0sr3
;-----------------------------------------------------------------------------
p3m0sr3:                                ; set slide to normal color
        mov eax,_cpalptr
        add eax,20h*3
        mov ballsdestpalptr,eax
        mov _vrtrout,offset p3ir1
        mov p3m0seqrout,offset p3m0sr0
        jmp p3m0
;-----------------------------------------------------------------------------
p3m0sr4:                                ; wait for muzik meta point
        cmp _muzloc,MUZLOC0
        jb p3m0
	mov p3m0seqrout,offset p3m0sr5
        jmp p3m0
;-----------------------------------------------------------------------------
p3m0sr5:				; wait for fall to end
        mov al,fallycntr
        or al,al
        jnz p3m0
        inc al
        mov fallycntr,al
        mov p3m0seqrout,offset p3m0sr6
        jmp p3m0
;-----------------------------------------------------------------------------
p3m0sr6:				; set next fall (if any)
	mov al,fallindex
        sub al,1
	jc p3m0sr6f0
        mov fallindex,al
        mov fallycntr,100
        mov p3m0seqrout,offset p3m0sr5
	jmp p3m0
p3m0sr6f0:
        mov fallindex,0ffh
        mov p3m0seqrout,offset p3m0sr7
        jmp p3m0
;-----------------------------------------------------------------------------
p3m0sr7:                                ; end of this part
        mov dx,3d5h                     ; set page 2
        @outb 80h

        mov eax,_ohimembase             ; clean up high memory base ptr
        mov _himembase,eax
        mov _vrtrout,offset _ret        ; clear retrace routine

        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p3i0r0:                                 ; get a 160x100 bitmap from screen
        add esi,_vidptr0
        xor al,al
p3i0r0l0:
        out dx,al
        mov ch,100
p3i0r0l0l0:
        mov cl,40
p3i0r0l0l0l0:
        movsb
        add edi,3
        dec cl
        jnz p3i0r0l0l0l0
        add esi,40
        dec ch
        jnz p3i0r0l0l0
        sub edi,160*100-1
        sub esi,80*100
        inc al
        and al,3
        jnz p3i0r0l0
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p3m0r0:                                 ; copy into erase areas
        or bl,bl
        jz _ret
        xor ecx,ecx
        xor eax,eax
p3m0r0l0:
        movzx esi,word ptr [edx]
        lea edi,[ebp+esi]
        add esi,_vidptr2
        mov bh,[edx+3]
        mov al,80
        sub al,bh
        push word ptr [edx+2]
p3m0r0l0l0:
        mov cl,bh
        rep movsb
        add edi,eax
        add esi,eax
        dec byte ptr [esp]
        jnz p3m0r0l0l0
        add esp,2
        add edx,4
        dec bl
        jnz p3m0r0l0
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p3m0r1:                                 ; put glass ball to screen
        add edi,ballsvidptrcur
        mov dx,3c5h
        movzx eax,bl
        and al,3
        mov al,_vidbitloc2[eax]
        mov ah,4
        mov ecx,_vidptr2
        lea esi,[ecx*4+ebx]
p3m0r1l0:
        out dx,al
        push eax edx edi
        mov dx,3cfh
        mov ah,ballscoloradd
p3m0r1l0l0:
        movsx ecx,byte ptr [ebp]
        sub edi,ecx
        movzx ebx,byte ptr [ebp+1]
        jmp p3m0r1rout[ebx*4]
p3m0r1l0f0:
irp temp,<15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0>
temp2=$
        movzx ebx,word ptr [ebp+&temp*2+2]
        add ebx,esi
        mov al,bl
        and al,3
        out dx,al
        shr ebx,2
        mov al,[ebx]
        add al,ah
        db 88h,47h,&temp        ; mov [edi+&temp],al
P3M0R1LEN=$-temp2
endm
        movzx ebx,byte ptr [ebp+1]
        lea ebp,[ebp+ebx*2+2]
        lea edi,[edi+ecx+80]
        sub edx,10000h
        jnc p3m0r1l0l0
        pop edi edx eax
        rol al,1
        adc edi,0
        dec ah
        jnz p3m0r1l0
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p3m0r2:                                 ; put ball with no refraction
        add edi,ballsvidptrcur
        mov dh,3
        and ebx,3
        mov ah,4
p3m0r2l0:
        mov dl,0cfh
        @outb bl
        mov dl,0c5h
        @outb _vidbitloc[ebx]
        push edx edi
p3m0r2l0l0:
        movsx ecx,byte ptr [ebp]
        sub edi,ecx
        movzx esi,byte ptr [ebp+1]
        jmp p3m0r2rout[esi*4]
p3m0r2l0f0:
irp temp,<15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0>
temp2=$
        db 80h,47h,&temp,40h    ; add byte ptr [edi+&temp],40h
P3M0R2LEN=$-temp2
endm
        lea ebp,[ebp+esi*2+2]
        lea edi,[edi+ecx+80]
        sub edx,10000h
        jnc p3m0r2l0l0
        pop edi edx
        inc bl
        and bl,3
        jnz short $+3
        inc edi
        dec ah
        jnz p3m0r2l0
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p3m0r3:                                 ; copy vertical line of BG pic
        mov ebx,edi
        and ebx,3
        @outb _vidbitloc[ebx]
        shr edi,2
        mov esi,edi
        add edi,_vidptr2
        imul ebx,80*200
        add esi,ebx
        add esi,fallbgptr
        mov ah,10
p3m0r3l0:
irp temp,<0,1,2,3,4,5,6,7,8,9>
        mov al,[esi+&temp*80]
        mov [edi+&temp*80],al
endm
        add edi,80*10
        add esi,80*10
        dec ah
        jnz p3m0r3l0
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p3m0r4a:                                ; fall position for lower left part
        mov ebx,28641f40h
        mov eax,6400a0h
        sub al,fallxcntr
        movzx esi,fallycntr
        lea esi,[esi*4+esi]
        lea esi,[esi*4]
        lea esi,[esi*4+80*100]
        movzx edi,al
        add edi,320*100-2
        ret
;-----------------------------------------------------------------------------
p3m0r4b:                                ; fall position for upper right part
        mov ebx,28640028h
        mov eax,100
        sub al,fallycntr
        movzx esi,al
        shl eax,16
        mov al,0a0h
        lea esi,[esi*4+esi-5]
        lea esi,[esi*4]
        lea esi,[esi*4+40]
        movzx edi,fallxcntr
        add edi,160
        ret
;-----------------------------------------------------------------------------
p3m0r4c:                                ; fall position for lower right part
        mov ebx,28641f68h
        mov eax,6400a0h
        movzx esi,fallycntr
        lea esi,[esi*4+esi]
        lea esi,[esi*4]
        lea esi,[esi*4+80*100+40]
        movzx edi,fallxcntr
        add edi,160+320*100
        ret
;-----------------------------------------------------------------------------
p3m0r4d:                                ; fall position for upper left part
        mov ebx,28640000h
        mov eax,100
        sub al,fallycntr
        movzx esi,al
        shl eax,16
        mov al,160
        sub al,fallxcntr
        lea esi,[esi*4+esi-5]
        lea esi,[esi*4]
        lea esi,[esi*4]
        movzx edi,al
        sub edi,2
        ret


code32  ends
        end

