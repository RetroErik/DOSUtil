        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include gsp669.inc
include vect3.inc
include kb.inc
include v.inc

public  _p0

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
align 4
CROSSPRLEN      = 40960
TITLESPRLEN     = 48640
FIRENUM         = 2000h                 ; must be perfect 2^x integer
MORPHNUM        = 4167h                 ; coded around this number
MORPHPRECALC    = 16e8h
SKULLMASKLEN    = 912
SKULLJAWSPRLEN  = 7776
SKULLSCRIPTLEN  = 300h
SKULLSIDELEN    = 3200h

MUZLOC4         = 0100h
MUZLOC0         = 0200h
MUZLOC1         = 0300h
MUZLOC2         = 0400h
MUZLOC3         = 0500h
MUZLOC5         = 0600h

dpalptr0        dd      ?               ; cross palette ptr
dpalptr1        dd      ?               ; fire palette ptr
dpalptr2        dd      ?               ; title palette ptr
dpalptr3        dd      ?               ; skull palette ptr
skullsidepalptr dd      ?               ; skull column palette ptr
crosssprptr     dd      ?               ; cross sprite ptr
titlesprptr     dd      ?               ; title sprite ptr
titletxtsprptr  dd      ?               ; initial 'Welcome to...' sprite ptr
skulljawsprptr  dd      ?               ; skull jaw sprite ptr
skullmaskptr    dd      ?               ; skull overlap mask
skullscriptptr  dd      ?               ; skull mouth movements script
skullsidesprptr dd      ?               ; skull side column sprite ptr

fireptr         dd      ?               ; fire data ptr
firerelptr0     dd      ?               ; fire cross release locs ptr
firerelptr1     dd      ?               ; fire pentagram release locs ptr

morphptr        dd      ?               ; morph data ptr
morphobufptr    dd      ?,?             ; morph pixel clear buffer ptrs
morphstblptr    dd      ?               ; morph scale table ptr

skullvidbufptr  dd      ?               ; ptr to skull jaw buffer
skullsideptr    dd      ?               ; ptr to column to put on sides

convdeltaptr    dd      ?               ; ptr to convection 2 wave sum deltas
convsinewaveptr dd      ?               ; ptr to sine wave for convection calc

p0m0fptbl       dd      p0m0fp0,p0m0fp1,p0m0fp2,p0m0fp3
p0m0rout        dd      p0m0r0          ; routine jumped to after every p0m0

trnsptr         dd      ?,?             ; transition video ptrs

firerelindex    dw      0               ; fire release next index
morphloopcntr   dw      ?               ; morph put loop counter

vrtcntr         db      0, 0            ;                                    |
ovrtcntr        db      0, 0            ;                                    |

morphindex      db      0               ; morph index
morphpagetbl    db      80h,0c0h        ; table for morph pages
fireconvindex   db      0               ; fire convection starting index
fireconvwave    db      0,0,0,0         ; fire convection wave locations
firepagetbl     db      0c0h,80h        ; table for fire pages
firepageindex   db      0               ; current page index

trnscount       db      48              ; transition routine loop counter

skullburnpal    db      63,63,0, 63,32,0, 63,0,0, 43,0,0, 23,0,0, 0,0,0
xddtbl          db      -4,-4,-3,-2,-1,0,1,2,3,4,4
yddtbl          db      -8,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,2

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
p0ir1:                                  ; transition to next part IRQ routine
        cld
        push ecx esi edi
        mov esi,trnsptr[0]
        lea edi,[esi+16]
        lea eax,[esi+1]
        mov trnsptr[0],eax
        call p0ir1r0
        mov esi,trnsptr[4]
        lea edi,[esi-16]
        lea eax,[esi-1]
        mov trnsptr[4],eax
        call p0ir1r0
        dec trnscount
        jnz short p0ir1d
        mov _vrtrout,offset _ret
p0ir1d:
        pop edi esi ecx
        ret
;-----------------------------------------------------------------------------
p0ir1r0:                                ; copy a section of vidmem
        mov ecx,25
p0ir1r0l0:
irp temp,<0,1,2,3>
        mov ah,[esi+&temp*80]
        mov [edi+&temp*80],ah
endm
        add edi,80*4
        add esi,80*4
        dec ecx
        jnz p0ir1r0l0
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
p0ir0:                                  ; IRQ routine to set first 64 colors
        cld
        push ecx esi
        mov dx,3c8h
        xor al,al
        out dx,al
        mov esi,_cpalptr
        inc edx
        mov ecx,64*3
        rep outsb
        inc word ptr vrtcntr
        pop esi ecx
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
_p0:
        mov eax,'p00d'                  ; load and allocate data
        call _loaddata
        mov dpalptr0,eax
        add eax,64*3
        mov dpalptr1,eax
        add eax,64*3
        mov dpalptr2,eax
        add eax,64*3
        mov crosssprptr,eax
        add eax,CROSSPRLEN
        mov titlesprptr,eax
        add eax,TITLESPRLEN
        mov firerelptr0,eax
        add eax,FIRENUM*2
        mov firerelptr1,eax
        add eax,FIRENUM*2
        mov convsinewaveptr,eax
        add eax,256
        mov titletxtsprptr,eax

        mov eax,FIRENUM*6+20000h+10000h
        call _gethimem
        mov fireptr,eax
        add eax,FIRENUM*6
        mov dword ptr [p0m0l1m0-4],eax
        add eax,20000h
        mov convdeltaptr,eax

        mov eax,'muz0'                  ; load up first muzik
        call _loadmuzik

        mov edi,_cpalptr                ; set current pal
        xor eax,eax
        mov ecx,16*3
        rep stosd
        mov _vrtrout,offset p0ir0       ; set palette setting IRQ routine

        mov dx,3d4h                     ; set CRTC to high byte of page
        @outb 0ch

        mov edi,dword ptr [p0m0l1m0-4]  ; set up fire dot location xlat tbl
        mov edx,8080h
p0i0l0:
        movzx ebx,dh
        xor bl,80h
        imul ebx,320
p0i0l1:
        movsx eax,dl
        lea eax,[eax+ebx+160]
        shr eax,2
        mov [edi+edx*2],ax
        inc dl
        jno p0i0l1
        inc dh
        jno p0i0l0

        mov ebp,fireptr                 ; set up initial fire data
        lea edi,[ebp+((FIRENUM-1)*6)]
        xor esi,esi
        mov ecx,FIRENUM/63
        mov ebx,0fd000000h
        xor al,al
p0i0l2:
        mov edx,firerelptr0
        mov bx,[edx+esi]
        add si,2
        and si,(FIRENUM-1)*2
        inc eax
        mov edx,edi
p0i0l3:
        mov [edx],ebx
        mov [edx+4],al
        sub edx,(FIRENUM/63)*6
        cmp edx,ebp
        jae p0i0l3
        add al,12
        and al,63
        sub edi,6
        loop p0i0l2

        mov edi,convdeltaptr            ; set up convection delta table
        mov esi,convsinewaveptr
        xor ecx,ecx
        xor ebx,ebx
p0i0l4:
        mov al,[esi+ebx]
        add al,[esi+ecx]
        cmp al,42
        setae al
        shl al,1
        stosb
        inc bl
        jnz p0i0l4
        inc cl
        jnz p0i0l4

waitl0:                                 ; wait for clear pal
        cmp vrtcntr,0
        je waitl0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
        mov ebx,80*56                   ; put initial 'Welcome to...'
        mov esi,titletxtsprptr
        mov edi,_vidptr0
        add edi,80*87
        call _pbmodex

        call _gsp669_play               ; start muzik playing

        mov esi,dpalptr1                ; fade text in
        mov al,1
waitl3:
        call p0slidepal
        jnc waitl3

;-----------------------------------------------------------------------------
muzwaitl2:                              ; wait for muzik meta point
        cmp _muzloc,MUZLOC4
        jb muzwaitl2
;-----------------------------------------------------------------------------

        mov esi,_clearpalptr            ; fade text out
        mov al,1
waitl5:
        call p0slidepal
        jnc waitl5

        mov ebx,80*128                  ; put cross and title pics to vidmem
        mov esi,crosssprptr
        mov edi,_vidptr0
        add edi,80*62
        call _pbmodex
        mov ebx,80*152
        mov esi,titlesprptr
        mov edi,_vidptr1
        add edi,80*35
        call _pbmodex

        mov esi,dpalptr0                ; fade cross in
        mov al,1
waitl1:
        call p0slidepal
        jnc waitl1

;-----------------------------------------------------------------------------
muzwaitl0:
        cmp _muzloc,MUZLOC0
        jb muzwaitl0
;-----------------------------------------------------------------------------

        mov edi,_cpalptr                ; set all white palette
        mov eax,3f3f3f3fh
        mov ecx,16*3
        rep stosd

        mov al,vrtcntr                  ; ready retrace counter for fade
        mov ovrtcntr,al

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Main fire loop
p0m0:
        movzx eax,firepageindex         ; flip page index and get ptrs
        mov ebp,_vidptr2[eax*4]
        xor al,1
        mov firepageindex,al

        lea edi,[ebp+6]                 ; clear old fire dots
        mov dx,3c5h
        @outb 0fh
        xor ecx,ecx
        mov bl,50
        xor eax,eax
p0m0l0:
rept 4
        mov cl,11h
        rep stosd
        add edi,0ch
endm
        dec bl
        jnz p0m0l0

        mov esi,fireptr                 ; put all fire dots
        mov edi,FIRENUM
p0m0l1:
        mov ax,[esi]
        mov bx,[esi+2]
        mov cl,[esi+4]
        dec cl
        jz p0m0l1r0
p0m0l1r0r:
        add al,bl
        jo p0m0l1r0
        add ah,bh
        jo p0m0l1r0
        mov [esi+4],cl
        mov [esi],ax
        movzx ebx,word ptr [eax*2+2beaddedh]
p0m0l1m0:
        add ebx,ebp
        and eax,3
        jmp p0m0fptbl[eax*4]
p0m0fpr:
        add esi,6
        dec edi
        jnz p0m0l1

        add fireconvwave[0],17          ; move convection waves
        add fireconvwave[1],27
        add fireconvwave[2],11
        add fireconvwave[3],19

        movzx eax,fireconvindex         ; apply convection currents
        inc eax
        and al,3
        mov fireconvindex,al
        lea eax,[eax*2+eax]
        lea esi,[esi+eax*2-FIRENUM*6]
        mov edi,convdeltaptr
        mov ebp,FIRENUM/4
p0m0l2:
        mov dx,[esi]
        mov cx,word ptr fireconvwave[0]
        add cl,dl
        add ch,dl
        add ch,dh
        mov al,[edi+ecx]
        movsx ebx,byte ptr [esi+2]
        mov bl,xddtbl[eax+ebx+4]
        mov [esi+2],bl
        mov cx,word ptr fireconvwave[2]
        add cl,dh
        add ch,dh
        add ch,dl
        mov al,[edi+ecx]
        movsx ebx,byte ptr [esi+3]
        mov bl,yddtbl[eax+ebx+8]
        mov [esi+3],bl
        add esi,24
        dec ebp
        jnz p0m0l2

        mov al,ovrtcntr                 ; wait past 2 retraces and calc rate
p0m0l3:
        mov ah,vrtcntr
        cmp al,ah
        je p0m0l3
        mov ovrtcntr,ah
        sub ah,al
        inc ah

        mov dx,3d5h                     ; set next displayed page
        movzx ebx,firepageindex
        @outb firepagetbl[ebx]

        mov al,ah
        jmp p0m0rout                    ; do approptiate routiune

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p0i1:
        mov esi,dpalptr2                ; fade title pic in
        mov al,1
waitl2:
        call p0slidepal
        jnc waitl2

        mov eax,_ohimembase             ; load and allocate next data
        mov _himembase,eax
        mov eax,'p01d'
        call _loaddata
        mov dpalptr3,eax
        add eax,64*3
        mov morphptr,eax

        mov eax,MORPHNUM*2*2+639*2*128
        call _gethimem
        mov morphobufptr[0],eax
        add eax,MORPHNUM*2
        mov morphobufptr[4],eax
        add eax,MORPHNUM*2
        mov morphstblptr,eax

        mov edi,_vidptr0                ; clear pages 0, 2, and 3
        mov dx,3c5h
        @outb 0fh
        mov ecx,1000h
        xor eax,eax
        rep stosd
        add edi,4000h
        mov ecx,2000h
        rep stosd

        mov edi,morphstblptr            ; calculate scale table
        xor ebx,ebx
p0i1l0:
        mov ecx,-319
        inc ebx
p0i1l1:
        mov eax,ebx
        imul eax,ecx
        sar eax,7
        stosw
        inc ecx
        cmp ecx,320
        jl p0i1l1
        cmp bl,80h
        jb p0i1l0

        mov edi,morphobufptr[0]         ; set up title pic fade to palette
        mov esi,edi
        mov dword ptr [edi],0
        add edi,3
        mov al,63
        mov ecx,63*3
        rep stosb
        mov ecx,MORPHNUM-16*3           ; clear rest of morph buffers
        xor eax,eax
        rep stosd

;-----------------------------------------------------------------------------
muzwaitl1:                              ; wait for muzik meta point
        cmp _muzloc,MUZLOC3
        jb muzwaitl1
;-----------------------------------------------------------------------------

        mov al,1                        ; slide to single skull color palette
waitl6:
        call p0slidepal
        jnc waitl6

        mov dword ptr vrtcntr,0         ; set up for proper pal shift

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Title to skull morph main loop
p0m1:
        movzx eax,morphindex            ; inc morph index and get ptrs
        xor al,1
        mov morphindex,al
        mov ebp,_vidptr2[eax*4]

        mov esi,morphobufptr[eax*4]     ; erase old morph pixels
        mov edi,esi
        mov dx,3c5h
        @outb 0fh
        mov ecx,MORPHNUM/18
        xor bl,bl
p0m1l0:
irp temp,<0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17>
        mov ax,[esi+&temp*2]
        mov byte ptr [ebp+eax],bl
endm
        add esi,36
        dec ecx
        jnz p0m1l0
        mov ax,[esi]
        mov byte ptr [ebp+eax],bl
        mov ax,[esi+2]
        mov byte ptr [ebp+eax],bl
        mov ax,[esi+4]
        mov byte ptr [ebp+eax],bl

        mov ax,word ptr vrtcntr         ; put frame of morph pixels
        or ah,ah
        jnz p0i2
        shr al,1
        push ax
        call p0m1r0

        mov dx,3d5h                     ; set next displayed page
        movzx ebx,morphindex
        @outb morphpagetbl[ebx]
        mov al,vrtcntr
        mov ovrtcntr,al

        mov esi,dpalptr3                ; slide to skull palette
        pop ax
        xchg ovrtcntr[1],al
        sub al,ovrtcntr[1]
        neg al
        call p0slidepal

        jmp p0m1

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p0i2:
        mov esi,dpalptr3                ; set destination palette for sure
        mov edi,_cpalptr
        mov ecx,16*3
        rep movsd

        mov ebp,_vidptr0                ; put full skull to page 0
        mov edi,morphobufptr[0]
        mov eax,7fh
        call p0m1r0

        mov dx,3d5h                     ; flip to page 0
        @outb 0

        mov eax,_ohimembase             ; load and allocate next data
        mov _himembase,eax
        mov eax,'p02d'
        call _loaddata
        mov skullmaskptr,eax
        add eax,SKULLMASKLEN
        mov skulljawsprptr,eax
        add eax,SKULLJAWSPRLEN
        mov skullscriptptr,eax
        add eax,SKULLSCRIPTLEN
        mov skullsidesprptr,eax
        add eax,SKULLSIDELEN
        mov skullsidepalptr,eax

        mov esi,skullsidepalptr         ; set side column palette
        mov ecx,20h
        mov al,40h
        mov ah,vrtcntr                  ; change pal on vertical retrace
waitl7:
        cmp ah,vrtcntr
        je waitl7
        call _setcpal

        mov edi,_vidptr1                ; clear pages 1, 2, and 3
        mov dx,3c5h
        @outb 0fh
        mov ecx,3000h
        xor eax,eax
        rep stosd

        mov edi,_vidptr0                ; put skull side column to vidmem
        add edi,0ed28h
        mov skullsideptr,edi
        mov esi,skullsidesprptr
        mov al,1
p0i2l3:
        out dx,al
        mov ecx,0320h
        rep movsd
        sub edi,0c80h
        shl al,1
        and al,0fh
        jnz p0i2l3

        mov edi,_vidptr0                ; put 23 heights of skull jaw
        add edi,3e80h
        mov skullvidbufptr,edi
        mov ebx,58*24
        mov ebp,23
p0i2l0:
        mov esi,skulljawsprptr
        add esi,81*24
        sub esi,ebx
        @outb 1
        mov ecx,ebx
        rep movsb
        add esi,81*24
        sub esi,ebx
        sub edi,ebx
        @outb 2
        mov ecx,ebx
        rep movsb
        add esi,81*24
        sub esi,ebx
        sub edi,ebx
        @outb 4
        mov ecx,ebx
        rep movsb
        add esi,81*24
        sub esi,ebx
        sub edi,ebx
        @outb 8
        mov ecx,ebx
        rep movsb
        sub edi,ebx
        add edi,81*24
        add ebx,24
        dec ebp
        jnz p0i2l0

        mov dl,0ceh                     ; write mode 1, vid->vid copy
        @outw 4105h

        mov edi,skullvidbufptr          ; put skull on top of jaw
        mov dl,0c5h
        mov bh,23
p0i2l1:
        mov ebp,skullmaskptr
        mov esi,_vidptr0
        add esi,245ah
        mov bl,38
p0i2l1l0:
        mov ecx,24
p0i2l1l1:
        mov al,[ebp]
        out dx,al
        movsb
        inc ebp
        loop p0i2l1l1
        add esi,56
        dec bl
        jnz p0i2l1l0
        add edi,43*24
        dec bh
        jnz p0i2l1

        @outb 0fh                       ; full vidmem bitmask

;-----------------------------------------------------------------------------
muzwaitl3:                              ; wait for muzik meta point
        cmp _muzloc,MUZLOC5
        jb muzwaitl3
;-----------------------------------------------------------------------------

        mov eax,'muz1'                  ; load 'Woe to you... ' voice
        call _loadmuzik

        call _gsp669_play               ; start voice

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Skull speech main loop
p0m2:
        mov al,vrtcntr                  ; wait for vertical retrace
p0m2l0:
        cmp al,vrtcntr
        je p0m2l0

        mov esi,skullscriptptr          ; put skull jaw according to muz loc
        movzx eax,_muzloc
        cmp ah,0ch
        jae short p0i3
        shl al,2
        shr eax,2
        movzx esi,byte ptr [esi+eax]
        imul esi,798h
        add esi,skullvidbufptr
        mov edi,_vidptr0
        add edi,245ah
        mov al,81
p0m2l1:
        mov ecx,24
        rep movsb
        add edi,56
        dec al
        jnz p0m2l1

        call p0m2r0

        jmp p0m2

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p0i3:
        mov ebp,69
        mov edx,_cpalptr
        mov bl,12
p0i3l0:
        mov bh,4
p0i3l0l0:
        lea edi,[ebp*2+ebp]             ; slide skull palette towards burn
        lea edi,[edi+edx-6*3]
        mov esi,offset skullburnpal
        mov ecx,18
        call _slidebytes
        mov word ptr [edx],0
        mov byte ptr [edx+2],0

        call p0m2r0

        mov al,vrtcntr                  ; wait for vertical retrace
p0i3l0l1:
        cmp al,vrtcntr
        je p0i3l0l1

        dec bh
        jnz p0i3l0l0
        sub edi,3
        dec ebp
        jnz p0i3l0

        mov eax,_vidptr0                ; set up transition retrace routine
        add eax,80*100
        mov trnsptr[0],eax
        add eax,79-80*100
        mov trnsptr[4],eax
        mov _vrtrout,offset p0ir1

        call _gsp669_stop               ; shut off muzik
        mov eax,_ohimembase             ; clean up high memory base ptr
        mov _himembase,eax

        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p0m0l1r0:                               ; new fire dot
        movzx eax,firerelindex
        add ax,2
        and ax,(FIRENUM-1)*2
        mov firerelindex,ax
        add eax,firerelptr0
        movzx eax,word ptr [eax]
        mov bx,0fd00h
        mov [esi+2],bx
        mov cl,63
        jmp p0m0l1r0r

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p0m0fp0:                                ; put fire dot mod 0
        @outb 1
        mov [ebx],cl
        sub cl,10h
        jc p0m0fpr
        mov [ebx-80],cl
        mov [ebx+80],cl
        @outb 8
        mov [ebx-1],cl
        @outb 2
        mov [ebx],cl
        jmp p0m0fpr
;-----------------------------------------------------------------------------
p0m0fp1:                                ; put fire dot mod 1
        @outb 2
        mov [ebx],cl
        sub cl,10h
        jc p0m0fpr
        mov [ebx-80],cl
        mov [ebx+80],cl
        @outb 5
        mov [ebx],cl
        jmp p0m0fpr
;-----------------------------------------------------------------------------
p0m0fp2:                                ; put fire dot mod 2
        @outb 4
        mov [ebx],cl
        sub cl,10h
        jc p0m0fpr
        mov [ebx-80],cl
        mov [ebx+80],cl
        @outb 10
        mov [ebx],cl
        jmp p0m0fpr
;-----------------------------------------------------------------------------
p0m0fp3:                                ; put fire dot mod 3
        @outb 8
        mov [ebx],cl
        sub cl,10h
        jc p0m0fpr
        mov [ebx-80],cl
        mov [ebx+80],cl
        @outb 1
        mov [ebx+1],cl
        @outb 4
        mov [ebx],cl
        jmp p0m0fpr

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p0m0r0:                                 ; just slide to fire palette
        mov esi,dpalptr1
        call p0slidepal
        jnc p0m0
        mov p0m0rout,offset p0m0r1
        jmp p0m0
;-----------------------------------------------------------------------------
p0m0r1:                                 ; wait for music to reach meta point
        mov bl,vrtcntr
        cmp bl,ovrtcntr
        je p0m0r1
        mov ovrtcntr,bl
        cmp _muzloc,MUZLOC1
        jb p0m0
        mov eax,firerelptr1
        mov firerelptr0,eax
        mov p0m0rout,offset p0m0r2
        jmp p0m0
;-----------------------------------------------------------------------------
p0m0r2:                                 ; wait for music to reach meta point
        mov bl,vrtcntr
        cmp bl,ovrtcntr
        je p0m0r2
        mov ovrtcntr,bl
        cmp _muzloc,MUZLOC2
        jb p0m0

        mov edi,_cpalptr                ; set all white palette
        mov eax,3f3f3f3fh
        mov ecx,16*3
        rep stosd

        @outb 40h                       ; set title page

        jmp p0i1                        ; go to title pic

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p0m1r0:                                 ; draw morph pixels
        imul eax,639*2
        add eax,morphstblptr
        add eax,319*2
        mov dword ptr [p0m1r0l0m0-4],eax
        mov dword ptr [p0m1r0l0m1-4],eax
        mov esi,morphptr
        mov ecx,MORPHNUM
        jmp short $+2
p0m1r0l0:
        movsx edx,word ptr [esi]
        movzx edx,word ptr [edx*2+2beaddedh]
p0m1r0l0m0:
        add dx,[esi+2]
        movsx ebx,word ptr [esi+4]
        movzx ebx,byte ptr [ebx*2+2beaddedh]
p0m1r0l0m1:
        add bl,[esi+6]
        movzx eax,dl
        and al,3
        shr edx,2
        lea ebx,[ebx*4+ebx]
        lea ebx,[ebx*4]
        lea ebx,[ebx*4+edx]
        mov dx,3c5h
        @outb _vidbitloc[eax]
        mov al,[esi+7]
        mov [ebp+ebx],al
        mov [edi],bx
        add edi,2
        add esi,8
        dec ecx
        jnz p0m1r0l0
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
p0m2r0:                                 ; put part of column growing on side
        movzx eax,_muzloc
        shl al,2
        shr eax,4
        sub al,18h
        jc _ret
        cmp al,0c7h
        ja _ret
        xor edi,edi
        call p0m2r0r0
        sub al,0c7h
        neg al
        mov edi,40h
p0m2r0r0:
        lea esi,[eax*4]
        lea esi,[esi*4]
        lea edi,[edi+esi*4]
        lea edi,[edi+esi]
        add edi,_vidptr0
        add esi,skullsideptr
        mov ecx,16
        rep movsb
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Slide current palette towards destination and wait for retrace if necessary
; In:
;   AL - max value to change each color by
;   ESI -> destination palette
; Out:
;   CF=1 - finished sliding
;   CF=0 - not finished, at least one change made
;   BL,ECX,EDI - ?
p0slidepal:
        mov bl,vrtcntr
        cmp bl,ovrtcntr
        je p0slidepal
        mov ovrtcntr,bl
        mov bl,al
        mov ecx,64*3
        mov edi,_cpalptr
        call _slidebytes
        ret

code32  ends
        end

