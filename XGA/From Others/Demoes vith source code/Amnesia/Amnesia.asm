  Hi folks, this is Tran typing... This is the virtual reality source from
the Amnesia demo. It is not compilable because we make special provisions for
our code. And because it has been so long since I wrote it, that even I would
not attempt to compile this demo again. Oh well, but if you want to look, feel
free. I had better explain a few things though:

) This is all integer math, no IEEE floating points anywhere...

) The SIN/COS table is merely a table of SIN/COS values for 512 points along
   the curve scaled from -1.0 ... 1.0 floating to -512 ... 512 integer.

) This thing loads external data, none of which is present here (or anywhere
   in existance anymore for that matter)... So if something looks like its
   missing, it probably is.

) Ignore the stars, what you want is the solid temple thingy. If I remember
   right, then here's how the sequence for that goes:

    ) All world coordinates are rotated and translated.
    ) Facets are built from the world coordinates and clipped to a plane
       at Z=5 at the same time.
    ) The facets are sorted by a sortof distance from viewpoint thingy to
       avoid having to take the square root. (Now that I think about it, why
       didn't I just sort by dX^2+dY^2+dZ^2, I didn't have to take the sqrt).
       The sort is in a byte indexed linked list to keep the data moves to a
       minimum.
    ) The thing is then projected.
    ) Finally, all visible facets are drawn. Visibility is determined by
       vektor cross products AFTER projection. (Dave's idea)

) Keep in mind this is flat mem, so don't panic if U C big pointers that
   even Windows would not allow and no seg overrides anywhere.


  Oh well, thats all I remember I think. If you really want to learn, get a
book. (A college textbook is best, you can then learn in a month what you
would normally have to pay a few thousand dollars to get a piece of paper
that says you know it in 4-6 years.)

  Ignore the SQRT routine down at the bottom, or use it, it is not part of
the source, but I remember how hard it was for me to devise one, so here you
go. (Oh yeah, this is integer too.)


;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
P9S=60h         ; number of stars
P9P=194         ; number of total points
P9F=183         ; number of facets
P9R=160         ; perspective multiplier
P9C=5           ; cutoff Z loc

p9index         db      0
p9matrix        dd      ?
p9oldmatrix     dd      ?,?
p9oldmatrixptr  dd      ?
p9oldstarbuf    dd      ?,?
p9oldstarptr    dd      ?
p9page          db      40h
p9pageptr       dd      ?

p9sincosptr     dd      ?               ; ptr to 512 degree sin/cos table
p9starptr       dd      ?               ; misc XYZ star coordinates
p9starcolorz    dd      ?               ; colors for stars
p9vectptr       dd      ?               ; ptr to actual world coordinates
p9facetptr      dd      ?               ; facet data for solid object
p9facetnum      db      ?
p9vbuf0         dd      ?               ; misc work buffer
p9vbuf1         dd      ?               ; misc work buffer
p9vbuf2         dd      ?               ; misc work buffer

p9vectoff       dw      0,0,25000, 0,0,0
p9vectrot       dw      -84,0,0, 0,0,0
p9distance      dw      0, 0
p9moveparms     dd      ?
p9movelen       dw      ?
p9move          dw      ?,?,?, ?,?,?, ?
p9count         dw      ?,?,?, ?,?,?, ?
p9countdec      dw      ?,?,?, ?,?,?, ?
p9movebyte      db      ?,?,?, ?,?,?, ?
p9seqptr        dd      ?
p9seq           dd      part9sequence
p9delay         dw      ?

p9cubeptr       dd      ?
p9cuberot       dw      0,0,0, -3,-4,-5
p9phadein0      dd      part9phadein0
p9phadein1      dd      part9phadein1
p9phadeind      db      ?

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
part9:
        mov _escpressed,0
        call clearscreen
        mov eax,9
        call load

        mov edx,_lomembase
        mov cx,30h
        xor al,al
        call setpalc
        add edx,90h
        mov p9sincosptr,edx
        add edx,500h
        mov p9starptr,edx
        add edx,P9S*6
        mov p9starcolorz,edx
        add edx,P9S
        movzx eax,word ptr [edx]
        add eax,edx
        mov p9seqptr,eax
        add edx,2
        mov p9cubeptr,edx
        add edx,8*3*2
        mov p9vectptr,edx
        add edx,P9P*3*2
        mov p9facetptr,edx

        lea ebp,[edx+8003h]
        and ebp,0fffffffch
        mov p9matrix,ebp
        call _vinitedgebuf
        add ebp,201*4
        mov p9oldmatrix,ebp
        call _vinitedgebuf
        add ebp,201*4
        mov p9oldmatrix[4],ebp
        call _vinitedgebuf
        add ebp,201*4
        mov p9oldstarbuf,ebp
        mov byte ptr [ebp],0
        add ebp,P9S*2*2+1+3
        mov p9oldstarbuf[4],ebp
        mov byte ptr [ebp],0
        add ebp,P9S*2*2+1+3
        mov p9vbuf0,ebp
        add ebp,8000h
        mov p9vbuf1,ebp
        add ebp,8000h
        mov p9vbuf2,ebp

        mov dx,3d4h
        mov al,0ch
        out dx,al

;-----------------------------------------------------------------------------
part9ml:
        call p9seq

        movzx ebx,p9index               ; switch pages, clear old matrix buf
        xor bl,1
        mov p9index,bl
        movzx edi,p9page
        shl edi,8
        add edi,vgaptr
        mov p9pageptr,edi
        mov ebp,p9oldmatrix[ebx*4]
        mov p9oldmatrixptr,ebp
        xor ah,ah
        call _vputedgebuf
        call _vclearedgebuf
        mov esi,p9oldstarbuf[ebx*4]     ; clear old star buffer
        mov p9oldstarptr,esi
        movzx ecx,byte ptr [esi]
        jecxz short part9f0
        inc esi
        mov dx,3c5h
        mov al,0fh
        out dx,al
part9l1:
        movzx eax,word ptr [esi]
        add esi,2
        mov byte ptr [edi+eax],0
        loop part9l1
part9f0:

        mov edx,offset p9cuberot        ; set cube rotation
        call part9rotate

        mov esi,p9cubeptr               ; rotate and put cube to main buffer
        mov edi,p9vectptr
        xor eax,eax
        push eax
        push ax
        mov ax,8
        push ax
        call _rotate0

        mov edx,offset p9vectrot        ; set main rotation and translation
        call part9rotate
        mov eax,dword ptr p9vectoff[6]
        add p9vectoff,ax
        shr eax,16
        add p9vectoff[2],ax
        mov ax,p9vectoff[10]
        add p9vectoff[4],ax
        mov ax,p9distance[2]
        add p9distance,ax
        xor eax,eax
        mov dword ptr p9vectrot[6],eax
        mov word ptr p9vectrot[10],ax
        mov dword ptr p9vectoff[6],eax
        mov word ptr p9vectoff[10],ax
        mov p9distance[2],ax

        mov esi,p9starptr               ; rotate stars
        mov edi,p9vbuf0
        mov ax,512
        push ax
        xor eax,eax
        push eax
        mov ax,P9S
        push ax
        call _rotate0

        mov ax,P9S
        push ax
        mov edi,p9oldstarptr            ; put stars normal
        inc edi
        mov esi,p9vbuf0
        mov ebp,p9starcolorz
        mov ebx,p9pageptr
part9l2:
        movsx ecx,word ptr [esi+4]
        cmp ecx,512
        jle short part9l2c
        movsx eax,word ptr [esi+2]
        imul eax,256
        cdq
        idiv ecx
        cmp eax,-100
        jl short part9l2c
        cmp eax,99
        jg short part9l2c
        add eax,100
        shl eax,4
        lea eax,[eax*4+eax]
        mov [edi],ax
        movsx eax,word ptr [esi]
        imul eax,256
        cdq
        idiv ecx
        cmp eax,-160
        jl short part9l2c
        cmp eax,159
        jg short part9l2c
        add eax,160
        mov cl,al
        shr eax,2
        add [edi],ax
        and cl,3
        mov al,1
        shl al,cl
        mov dx,3c5h
        out dx,al
        movzx eax,word ptr [edi]
        mov cl,[ebp]
        mov byte ptr [ebx+eax],cl
        inc byte ptr [esp+1]
        add edi,2
part9l2c:
        inc ebp
        add esi,6
        dec byte ptr [esp]
        jnz part9l2
        mov al,P9S                      ; put stars reversed (double)
        mov [esp],al
        sub esi,P9S*6
        sub ebp,P9S
part9lc:
        movsx ecx,word ptr [esi+4]
        sub ecx,1024
        neg ecx
        cmp ecx,512
        jle short part9lcc
        movsx eax,word ptr [esi+2]
        neg eax
        imul eax,256
        cdq
        idiv ecx
        cmp eax,-100
        jl short part9lcc
        cmp eax,99
        jg short part9lcc
        add eax,100
        shl eax,4
        lea eax,[eax*4+eax]
        mov [edi],ax
        movsx eax,word ptr [esi]
        neg eax
        imul eax,256
        cdq
        idiv ecx
        cmp eax,-160
        jl short part9lcc
        cmp eax,159
        jg short part9lcc
        add eax,160
        mov cl,al
        shr eax,2
        add [edi],ax
        and cl,3
        mov al,1
        shl al,cl
        mov dx,3c5h
        out dx,al
        movzx eax,word ptr [edi]
        mov cl,[ebp]
        xor cl,7
        mov byte ptr [ebx+eax],cl
        inc byte ptr [esp+1]
        add edi,2
part9lcc:
        inc ebp
        add esi,6
        dec byte ptr [esp]
        jnz part9lc
        mov al,[esp+1]
        mov edi,p9oldstarptr
        stosb
        add esp,2

        mov esi,p9vectptr               ; rotate main points
        mov edi,p9vbuf0
        mov ax,P9P
        push ax
        call part9rotate0

        sub esp,11                      ; clip to Z
        mov byte ptr [esp],P9F
        mov p9facetnum,0
        mov esi,p9vbuf1
        mov ebp,p9facetptr
part9la:
        mov [esp+2],ebp
        mov edi,esi
        mov ah,[ebp]
        xor al,al
        stosw
        movzx ebx,ah
        add ebp,2
        movzx eax,byte ptr [ebp+ebx-1]
        mov [esp+1],al
        lea eax,[eax*2+eax]
        lea eax,[eax*2+4]
        add eax,p9vbuf0
        cmp word ptr [eax],P9C-1
        setg bl
part9lb:
        movzx ecx,byte ptr [ebp]
        lea ecx,[ecx*2+ecx]
        shl ecx,1
        add ecx,p9vbuf0
        mov ax,[ecx+4]
        cmp ax,P9C-1
        setg bh
        xor bl,bh
        jz short part9lbc

        mov [esp+6],bh
        mov [esp+7],esi
        movzx esi,byte ptr [esp+1]
        lea esi,[esi*2+esi]
        shl esi,1
        add esi,p9vbuf0
        mov ebx,P9C
        sub bx,ax
        jns short part9f4
        neg bx
part9f4:
        shl ebx,16
        sub ax,[esi+4]
        jns short part9f3
        neg ax
part9f3:
        shrd ebx,eax,16

        mov ax,[esi]
        sub ax,[ecx]
        imul bx
        rol ebx,16
        idiv bx
        rol ebx,16
        add ax,[ecx]
        stosw
        mov ax,[esi+2]
        sub ax,[ecx+2]
        imul bx
        rol ebx,16
        idiv bx
        add ax,[ecx+2]
        stosw
        mov ax,P9C
        stosw

        mov esi,[esp+7]
        inc byte ptr [esi]
        mov bh,[esp+6]
part9lbc:
        mov bl,bh
        or bl,bl
        jz short part9lbc2
        mov eax,[ecx]
        stosd
        mov ax,[ecx+4]
        stosw
        inc byte ptr [esi]
part9lbc2:
        mov al,[ebp]
        inc ebp
        mov [esp+1],al
        dec byte ptr [esi+1]
        jnz part9lb

        mov ebp,[esp+2]
        cmp byte ptr [esi],0
        je short part9lac

        mov al,[ebp+1]
        mov [esi+1],al
        mov esi,edi
        inc p9facetnum
part9lac:
        movzx eax,byte ptr [ebp]
        lea ebp,[ebp+eax+2]
        dec byte ptr [esp]
        jnz part9la
        add esp,11

        mov ebp,p9vbuf1                 ; sort by distance
        movzx eax,p9facetnum
        or al,al
        jz part9f1
        push eax
        mov ebx,p9vbuf2
        mov word ptr [ebx+6],-1
part9l3:
        lea esi,[ebp+2]
        movzx ecx,byte ptr [ebp]
        xor eax,eax
        mov ebx,eax
        mov edi,eax
part9l4:
        movsx edx,word ptr [esi]
        add eax,edx
        movsx edx,word ptr [esi+2]
        add edi,edx
        movzx edx,word ptr [esi+4]
        add ebx,edx
        add esi,6
        loop part9l4
        movzx ecx,byte ptr [ebp]
        or eax,eax
        jns short part9f5
        neg eax
part9f5:
        xor edx,edx
        div ecx
        xchg eax,edi
        or eax,eax
        jns short part9f6
        neg eax
part9f6:
        xor edx,edx
        div ecx
        add edi,eax
        shr edi,2
        mov eax,ebx
        xor edx,edx
        div ecx
        add eax,edi

        movzx edi,byte ptr [esp+1]      ;  insert into linked list
        mov ebx,edi
        shl edi,3
        mov edx,p9vbuf2
        add edi,edx
        mov [edi+2],ebp
        mov [edi],ax
        lea ecx,[ecx*2+ecx]
        shl ecx,1
        lea ebp,[ebp+ecx+2]
        mov ecx,ebx
        jecxz short part9l3c
        mov bh,[esp+3]
        movzx esi,bh
part9l5:
        shl esi,3
        add esi,edx
        cmp ax,[esi]
        jb short part9l5c
        movzx eax,byte ptr [esi+7]
        mov [esi+7],bl
        cmp al,-1
        jne short part9l5d
        mov [esp+3],bl
        mov [edi+7],al
        jmp short part9f2
part9l5c:
        mov bh,[esi+6]
        movzx esi,bh
        loop part9l5
        movzx eax,byte ptr [esp+2]
        mov [esp+2],bl
        mov bh,-1
part9l5d:
        mov [edi+7],al
        shl eax,3
        add edx,eax
        mov [edx+6],bl
part9f2:
        mov byte ptr [edi+6],bh
part9l3c:
        inc byte ptr [esp+1]
        dec byte ptr [esp]
        jnz part9l3
        movzx eax,byte ptr [esp+3]
        add esp,4

        mov edi,p9vbuf0                 ; project
part9l6:
        lea ebp,[eax*8]
        add ebp,p9vbuf2
        mov esi,[ebp+2]
        lodsw
        movzx ecx,al
        stosw
part9l7:
        movsx ebx,word ptr [esi+4]
        movsx eax,word ptr [esi]
        imul eax,P9R
        cdq
        idiv ebx
        stosw
        movsx eax,word ptr [esi+2]
        imul eax,P9R
        cdq
        idiv ebx
        stosw
        add esi,6
        loop part9l7
        movzx eax,byte ptr [ebp+6]
        cmp al,-1
        jne part9l6

        mov ebp,p9matrix                ; draw visible surfaces
        mov esi,p9vbuf0
        mov al,p9facetnum
        push ax
part9l8:
        movsx ecx,word ptr [esi+2+4]
        movsx edx,word ptr [esi+2+4+2]
        movsx edi,word ptr [esi+2+2]
        sub edi,edx
        neg edi
        movsx eax,word ptr [esi+2+8]
        sub eax,ecx
        imul edi,eax
        movsx ebx,word ptr [esi+2]
        sub ecx,ebx
        movsx eax,word ptr [esi+2+8+2]
        sub eax,edx
        imul eax,ecx
        cmp eax,edi
        jge short part9l8c

        call _vclearedgebuf
        movzx eax,byte ptr [esi]
        mov [esp+1],al
        shl eax,2
        lea edi,[esi+2]
        mov bx,[edi+eax-2]
        mov ax,[edi+eax-4]
part9l9:
        mov cx,[edi]
        mov dx,[edi+2]
        call _vputedge
        mov ax,cx
        mov bx,dx
        add edi,4
        dec byte ptr [esp+1]
        jnz part9l9
        mov edi,p9oldmatrixptr
        call _vaddedgebuf
        mov edi,p9pageptr
        mov ah,[esi+1]
        call _vputedgebuf
part9l8c:
        movzx eax,byte ptr [esi]
        shl eax,2
        lea esi,[esi+eax+2]
        dec byte ptr [esp]
        jnz part9l8
        add esp,2

part9f1:
        call p9phadein0

        mov dx,3dah
        in al,dx
        test al,8
        jnz short $-3

        mov dx,3d5h                     ; set new page
        mov al,p9page
        out dx,al
        xor al,40h
        mov p9page,al
part9l0:
        cmp _dfmcounter,2
        jb short part9l0
        mov _dfmcounter,0
        mov dx,3dah
        in al,dx
        test al,8
        jz short $-3
        cmp _escpressed,0
        jne _ret
        jmp p9phadein1

;-----------------------------------------------------------------------------
part9rotate:
        mov esi,p9sincosptr
        mov edi,offset srx
        mov ecx,3
part9rotateml:
        movzx ebx,word ptr [edx]
        movsx eax,word ptr [edx+6]
        add ebx,eax
        and ebx,1ffh
        mov [edx],bx
        add edx,2
        movsx eax,word ptr [esi+ebx*2+256]
        mov [edi+12],eax
        movsx eax,word ptr [esi+ebx*2]
        stosd
        loop part9rotateml
        ret

;-----------------------------------------------------------------------------
part9phadein0:
        mov edi,_lomembase
        lea esi,[edi+20h*3]
        mov ecx,8*3
        lea edi,[esi+ecx]
        mov bl,4
        call _slidebytes
        setc al
        mov p9phadeind,al
        jnc _ret
        mov p9phadein0,offset _ret
        ret
;-----------------------------------------------------------------------------
part9phadein1:
        mov edx,_lomembase
        add edx,28h*3
        mov ecx,8
        mov al,20h
        call _setpal
        cmp p9phadeind,0
        je part9ml
        mov p9phadein1,offset part9ml
        jmp part9ml

;-----------------------------------------------------------------------------
part9delay:
        dec p9delay
        jnz _ret
        mov p9seq,offset part9sequence
        ret

;-----------------------------------------------------------------------------
part9move:
        dec p9delay
        jnz short part9movef0
        mov esi,p9moveparms
        mov edi,offset p9vectoff
        movsd
        movsw
        mov edi,offset p9vectrot
        movsd
        movsw
        lodsw
        mov p9distance,ax
        mov p9seq,offset part9sequence
        ret
part9movef0:
        xor ebp,ebp
        mov esi,offset p9move
        mov edi,offset p9vectoff+6
        mov al,p9movebyte[ebp]
        mov part9mover0m0[1],al
        call part9mover0
        mov al,p9movebyte[ebp]
        mov part9mover0m0[1],al
        call part9mover0
        mov al,p9movebyte[ebp]
        mov part9mover0m0[1],al
        call part9mover0
        mov edi,offset p9vectrot+6
        mov al,p9movebyte[ebp]
        mov part9mover0m0[1],al
        call part9mover0
        mov al,p9movebyte[ebp]
        mov part9mover0m0[1],al
        call part9mover0
        mov al,p9movebyte[ebp]
        mov part9mover0m0[1],al
        call part9mover0
        mov edi,offset p9distance+2
        mov al,p9movebyte[ebp]
        mov part9mover0m0[1],al
part9mover0:
        lodsw
        mov cx,p9count[ebp*2]
        sub cx,p9countdec[ebp*2]
        ja short part9mover0f0
        add cx,p9movelen
        stc
part9mover0f0:
part9mover0m0   db      66h,?,0,0
        mov p9count[ebp*2],cx
        stosw
        inc ebp
        ret

;-----------------------------------------------------------------------------
part9sequence:
        mov esi,p9seqptr
        lodsw
        cmp ax,0
        jl part9done
        jg part9sequencef0
        lodsw
        mov p9delay,ax
        mov p9seq,offset part9delay
        mov p9seqptr,esi
        ret
part9sequencef0:
        mov p9moveparms,esi
        mov p9delay,ax
        mov p9movelen,ax
        mov ebx,eax
        xor ebp,ebp
        lodsw
        sub ax,p9vectoff
        call part9sequencer0
        lodsw
        sub ax,p9vectoff[2]
        call part9sequencer0
        lodsw
        sub ax,p9vectoff[4]
        call part9sequencer0
        mov edi,offset p9vectrot
        call part9sequencer1
        call part9sequencer1
        call part9sequencer1
        lodsw
        sub ax,p9distance
        call part9sequencer0
        mov p9seq,offset part9move
        mov p9seqptr,esi
        jmp part9move
part9sequencer1:
        lodsw
        sub ax,[edi]
        add edi,2
        and ax,1ffh
        cmp ax,100h
        jb short part9sequencer0
        xor ax,1ffh
        neg ax
part9sequencer0:
        mov p9count[ebp*2],bx
        cwd
        idiv bx
        mov p9move[ebp*2],ax
        mov al,15h
        or dx,dx
        jns short part9sequencer0f0
        neg dx
        mov al,1dh
part9sequencer0f0:
        mov p9countdec[ebp*2],dx
        mov p9movebyte[ebp],al
        inc ebp
        ret

;-----------------------------------------------------------------------------
part9done:
        add esp,4
        jmp phadeout


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Rotate set of X,Y,Z coordinates
; In:
;   w[esp] - number of points in matrix
;   w[esp+2] - delta X
;   w[esp+4] - delta Y
;   w[esp+6] - delta Z
;   ESI -> X,Y,Z matrix (words)
;   EDI -> where to store rotated matrix
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
srx             dd      ?               ; sin of rotation around x
sry             dd      ?               ; sin of rotation around y
srz             dd      ?               ; sin of rotation around z
crx             dd      ?               ; cos of rotation around x
cry             dd      ?               ; cos of rotation around y
crz             dd      ?               ; cos of rotation around z
_rotate0:
        pushad
rotate0ml:
        movsx ecx,word ptr [esi]
        mov eax,ecx
        imul eax,crz
        sar eax,9
        movsx edx,word ptr [esi+2]
        mov ebx,edx
        imul ebx,srz
        sar ebx,9
        sub eax,ebx
        imul ecx,srz
        sar ecx,9
        imul edx,crz
        sar edx,9
        add ecx,edx
        movsx ebp,word ptr [esi+4]
        mov ebx,ecx
        imul ebx,crx
        sar ebx,9
        mov edx,ebp
        imul edx,srx
        sar edx,9
        sub ebx,edx
        imul ecx,srx
        sar ecx,9
        imul ebp,crx
        sar ebp,9
        add ebp,ecx
        mov edx,ebp
        imul edx,cry
        sar edx,9
        mov ecx,eax
        imul ecx,sry
        sar ecx,9
        sub edx,ecx
        imul ebp,sry
        sar ebp,9
        imul eax,cry
        sar eax,9
        add eax,ebp
        add ax,[esp+38]
        add bx,[esp+40]
        add dx,[esp+42]
        stosw
        mov [edi],bx
        mov [edi+2],dx
        add edi,4
        add esi,6
        dec word ptr [esp+36]
        jnz rotate0ml
        popad
        ret 8

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
part9rotate0:
        mov cx,word ptr [esi]
        add cx,p9vectoff
        movsx ecx,cx
        mov eax,ecx
        imul eax,crz
        sar eax,9
        mov dx,word ptr [esi+2]
        add dx,p9vectoff[2]
        movsx edx,dx
        mov ebx,edx
        imul ebx,srz
        sar ebx,9
        sub eax,ebx
        imul ecx,srz
        sar ecx,9
        imul edx,crz
        sar edx,9
        add ecx,edx
        mov bp,word ptr [esi+4]
        add bp,p9vectoff[4]
        movsx ebp,bp
        mov ebx,ecx
        imul ebx,crx
        sar ebx,9
        mov edx,ebp
        imul edx,srx
        sar edx,9
        sub ebx,edx
        imul ecx,srx
        sar ecx,9
        imul ebp,crx
        sar ebp,9
        add ebp,ecx
        mov edx,ebp
        imul edx,cry
        sar edx,9
        mov ecx,eax
        imul ecx,sry
        sar ecx,9
        sub edx,ecx
        imul ebp,sry
        sar ebp,9
        imul eax,cry
        sar eax,9
        add eax,ebp
        add dx,p9distance
        stosw
        mov [edi],bx
        mov [edi+2],dx
        add edi,4
        add esi,6
        dec word ptr [esp+4]
        jnz part9rotate0
        ret 2

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize edge buffer
; In:
;   EBP -> edge buffer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_vinitedgebuf:
        mov dword ptr [ebp],0c70000h
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Clear edge buffer
; In:
;   EBP -> edge buffer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_vclearedgebuf:
        push eax
        push ecx
        push edi
        movzx edi,word ptr [ebp]
        movzx ecx,word ptr [ebp+2]
        sub ecx,edi
        jc short clearedgebufd
        inc ecx
        lea edi,[ebp+edi*4+4]
        mov dword ptr [ebp],0ffffh
        mov eax,080007fffh
        rep stosd
clearedgebufd:
        pop edi
        pop ecx
        pop eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Put edge buffer to screen
; In:
;   AH - color
;   EBP -> edge buffer
;   EDI -> beginning of physical screen memory
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_vputedgebuf:
        pushad
        movzx ebx,word ptr [ebp]
        movzx esi,word ptr [ebp+2]
        sub esi,ebx
        jc putedgebufd
        inc esi
        lea ebp,[ebp+ebx*4+4]
        imul ebx,80
        add edi,ebx
        push edi
putedgebufml:
        movsx ecx,word ptr [ebp]
        cmp ecx,159
        jg putedgebufmlc
        movsx ebx,word ptr [ebp+2]
        cmp ebx,-160
        jl short putedgebufmlc
        cmp ecx,-160
        jge short putedgebuff0
        mov ecx,-160
putedgebuff0:
        cmp ebx,159
        jle short putedgebuff1
        mov ebx,159
putedgebuff1:
        sub ebx,ecx
        inc ebx
        add ecx,160
        mov al,cl
        and al,3
        shr ecx,2
        add edi,ecx

        mov dx,3c5h
        movzx ecx,al
        or cl,cl
        jz short putrasterf0
        mov al,0fh
        shl al,cl
        xor cl,3
        inc cl
        sub bx,cx
        jc short putrasterf2
        out dx,al
        mov al,ah
        stosb
putrasterf0:
        cmp bx,4
        jb short putrasterf1
        mov al,0fh
        out dx,al
        movzx ecx,bx
        and cl,0fch
        sub bx,cx
        shr ecx,2
        mov al,ah
        rep stosb
putrasterf1:
        mov cl,bl
        mov al,0f0h
        rol al,cl
        out dx,al
        mov [edi],ah
        jmp short putedgebufmlc
putrasterf2:
        mov cl,bl
        add cl,4
        mov bl,0fh
        shl bl,cl
        xor al,bl
        out dx,al
        mov [edi],ah

putedgebufmlc:
        mov edi,[esp]
        add edi,80
        mov [esp],edi
        add ebp,4
        dec esi
        jnz putedgebufml
        add esp,4
putedgebufd:
        popad
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Add one edge buffer to another
; In:
;   EBP -> source edge buffer
;   EDI -> destination edge buffer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_vaddedgebuf:
        push eax
        push ecx
        push esi
        push edi
        movzx ecx,word ptr [ebp+2]
        cmp cx,[edi+2]
        jb short addedgebuff1
        mov [edi+2],cx
addedgebuff1:
        movzx eax,word ptr [ebp]
        cmp ax,[edi]
        ja short addedgebuff0
        mov [edi],ax
addedgebuff0:
        sub ecx,eax
        jc short addedgebufd
        inc ecx
        lea esi,[ebp+eax*4+4]
        lea edi,[edi+eax*4+4]
addedgebufml:
        lodsw
        cmp ax,[edi]
        jg short addedgebufmlf0
        mov [edi],ax
addedgebufmlf0:
        add edi,2
        lodsw
        cmp ax,[edi]
        jl short addedgebufmlf1
        mov [edi],ax
addedgebufmlf1:
        add edi,2
        loop addedgebufml
addedgebufd:
        pop edi
        pop esi
        pop ecx
        pop eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Put edge line to edge buffer
; In:
;   AX - starting X
;   BX - starting Y
;   CX - ending X
;   DX - ending Y
;   EBP -> edge buffer
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
;-----------------------------------------------------------------------------
putedgef0:
        cmp bp,-100
        jl putedgedone
        sub cx,ax
        mov ax,-100
        sub ax,bx
        jns short putedgef0f0
        neg ax
putedgef0f0:
        sub bx,bp
        jns short putedgef0f1
        neg bx
putedgef0f1:
        imul cx
        idiv bx
        add si,ax
        mov bx,-100
        jmp putedgef4
;-----------------------------------------------------------------------------
putedgef1:
        cmp bp,99
        jg putedgedone
        sub cx,ax
        mov ax,99
        sub ax,bx
        jns short putedgef1f0
        neg ax
putedgef1f0:
        sub bx,bp
        jns short putedgef1f1
        neg bx
putedgef1f1:
        imul cx
        idiv bx
        add si,ax
        mov bx,99
        jmp short putedgef4
;-----------------------------------------------------------------------------
putedgef2:
        mov cx,si
        sub cx,di
        mov ax,-100
        sub ax,bp
        jns short putedgef2f0
        neg ax
putedgef2f0:
        sub bp,bx
        jns short putedgef2f1
        neg bp
putedgef2f1:
        imul cx
        idiv bp
        add di,ax
        mov bp,-100
        jmp short putedgef5
;-----------------------------------------------------------------------------
putedgef3:
        mov cx,si
        sub cx,di
        mov ax,99
        sub ax,bp
        jns short putedgef3f0
        neg ax
putedgef3f0:
        sub bp,bx
        jns short putedgef3f1
        neg bp
putedgef3f1:
        imul cx
        idiv bp
        add di,ax
        mov bp,99
        jmp short putedgef5

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
_vputedge:
        pushad
        mov si,ax
        mov di,cx
        mov bp,dx
        cmp bx,-100
        jl putedgef0
        cmp bx,99
        jg putedgef1
putedgef4:
        cmp bp,-100
        jl putedgef2
        cmp bp,99
        jg putedgef3
putedgef5:
                ; Out: SI-X, BX-Y, DI-X, BP-Y
        add bx,100
        lea edx,[ebp+100]
        lea eax,[esi+8000h]
        lea ecx,[edi+8000h]
        mov ebp,[esp+8]
        mov si,bx
        mov di,bx
        cmp si,dx
        jb short oputedgebf5
        mov si,dx
oputedgebf5:
        cmp di,dx
        ja short oputedgebf6
        mov di,dx
oputedgebf6:
        cmp si,[ebp]
        ja short oputedgebf0
        mov [ebp],si
oputedgebf0:
        cmp di,[ebp+2]
        jb short oputedgebf1
        mov [ebp+2],di
oputedgebf1:
        movzx esi,bx
        lea ebp,[ebp+esi*4+4]
        sub dx,bx
        mov bl,0c5h
        jnc short oputedgebf2
        neg dx
        mov bl,0edh
oputedgebf2:
        mov oputedgem1[1],bl
        mov edgely,dx
        sub cx,ax
        mov bl,40h
        jnc short oputedgebf3
        neg cx
        mov bl,48h
oputedgebf3:
        mov oputedgem0,bl
        mov edgelx,cx
        cmp cx,dx
        ja short oputedgebf4
        mov cx,dx
oputedgebf4:
        movzx ebx,cx
        lea ecx,[ebx+1]
        mov si,bx
        shr si,1
        adc si,0
        mov di,si
        mov dx,[ebp+2]
        sub ax,8000h
        jmp short oputedgeml
oputedgeml:
        cmp ax,[ebp]
        jg short oputedgef0
        mov [ebp],ax
oputedgef0:
        cmp ax,dx
        jl short oputedgef1
        mov dx,ax
oputedgef1:
        db 66h,81h,0eeh
edgelx          dw      ?
        ja short oputedgef2
        add si,bx
oputedgem0      db      ?
oputedgef2:
        db 66h,81h,0efh
edgely          dw      ?
        ja short oputedgef4
        add di,bx
        mov [ebp+2],dx
oputedgem1      db      83h,?,4
        mov dx,[ebp+2]
oputedgef4:
        loop oputedgeml
        mov [ebp+2],dx
putedgedone:
        popad
        ret

; Hey you... Yeah, you reading this message... Ignore this.
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Square root
; In:
;   EAX - number to take root of
; Out:
;   EAX - root
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
sqrtbasetbl     db      0,1,4,9,16,25,36,49,64,81,100,121,144,169,196,225
_sqrt:
        pushad
        mov ebp,eax
        bsr ebx,eax
        jnz short sqrtf0
        xor ebx,ebx
sqrtf0:
        shr ebx,3
        lea eax,[ebx*8]
        mov cl,32
        sub cl,al
        rol ebp,cl
        mov eax,ebp
        movzx eax,al
        mov edi,offset sqrtbasetbl
        mov ecx,10h
sqrtl0:
        scasb
        je short sqrtl0d
        jb short sqrtl0d2
        loop sqrtl0
        inc edi
sqrtl0d2:
        dec edi
        inc cl
sqrtl0d:
        movzx edx,byte ptr [edi-1]
        dec cl
        xor cl,0fh
        mov edi,ecx
        mov ecx,ebx
        jecxz short sqrtdone
        sub eax,edx
sqrtml:
        shld eax,ebp,8
        rol ebp,8
        mov ebx,edi
        shl ebx,5
        xor edx,edx
        mov esi,eax
        div ebx
        rol edi,4
        add edi,eax
        add ebx,eax
sqrtf2:
        imul eax,ebx
        mov edx,eax
        mov eax,esi
        sub eax,edx
        jc short sqrtf1
        loop sqrtml
sqrtdone:
        mov [esp+28],edi
        popad
        ret
sqrtf1:
        dec ebx
        dec edi
        movzx eax,bl
        and al,1fh
        jmp sqrtf2

