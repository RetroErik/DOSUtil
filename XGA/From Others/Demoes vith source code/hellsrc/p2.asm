        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include gsp669.inc
include vect3.inc
include kb.inc
include v.inc

public  _p2

;ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
; DATA
;ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
align 4
FACESSPRLEN     = 256*200
FACESLOCLEN     = 148*2*4
FACESPALLEN     = 10h*3
HIGHLIGHTSPRLEN = 12227
MIRRORPICLEN    = 320*200
MIRRORPICPALLEN = 40h*3
MIRRORPICTBLLEN = 112*200*2
MIRRORSPRLEN    = 214*168

MUZLOC0         = 0800h

p2m0sv0         equ byte ptr [esp]
p2m0sv1         equ byte ptr [esp+1]
p2m0sv2         equ byte ptr [esp+2]
p2m0sv3         equ byte ptr [esp+3]
p2m0sv4         equ byte ptr [esp+4]
p2m0sv5         equ byte ptr [esp+5]
p2m0sv6         equ byte ptr [esp+6]
P2M0SVL0        = 8

p2m1sv0         equ dword ptr [esp]
p2m1sv1         equ byte ptr [esp+4]
P2M1SVL0        = 8

dpalptr0        dd      ?               ; 2 pieces of mirror palette
facessprptr     dd      ?               ; moaning faces bitmap ptr
faceslocptr     dd      ?               ; ptr to raster offset and len table
facesoffptrl    dd      ?               ; load ptr to pixel offset table
facesdeltaptrl  dd      ?               ; load ptr to delta table for offsets
facesoffptr     dd      ?               ; ptr to pixel offset table
facesdeltaptr   dd      ?               ; ptr to delta table for offset table
facesdeltaptr2  dd      ?               ; delta table sum/mod 4
facesmisctbl0   dd      ?               ; misc calc optimization table
highlightsprptr dd      ?               ; highlight compiled sprite ptr

mirrorxpalptr   dd      ?               ; faces to mirror pic transition pal
mirrorpicptr    dd      ?               ; ptr to pic in mirror
mirrorpicpalptr dd      ?               ; ptr to pal for mirror pic
mirrorpictblptr dd      ?               ; ptr to table for mirror pic edges
mirrorsprptr    dd      ?               ; ptr to mirror sprite for scaling
mirrorpicctbl   dd      ?               ; running mirror zoom table ptr
mirrorpicptbl   dd      ?,?             ; old mirror zoom table for both pages

p2m0seqrout     dd      p2m0sr0         ; sequence routine for faces in mirror
p2m0rout0       dd      35h dup(?)      ; entry/exit points to raster put code
p2m0rout1       label   dword           ; entry points to offseting routine
irp temp,<26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0>
                dd      p2m0r1+&temp*3
endm

mirrorzoomloc   dw      34h,14h         ; Y and X location of zooming mirror
mirrorzoomlen   dw      0d8h,0aah       ; Y and X size of zooming mirror

facesoffwave    db      0,0             ; starting locations of offset waves
facesdeltawave  db      0,0             ; starting locations of delta waves

vrtcntr         db      0               ;                                    |
ovrtcntr        db      0               ;                                    |
vrttime         db      1               ; vertical retraces per frame

facespageindex  db      1               ; warping faces page index
facespagetbl    db      80h,0c0h        ; warping faces page offset table

faceswaveloc    db      0               ; wave inc table wave location
facesoffwave0   db      1,2,1,2,2,1,2,2
facesoffwave1   db      1,1,1,1,1,2,1,1
facesdeltawave0 db      2,1,2,1,1,1,2,1
facesdeltawave1 db      2,2,2,2,2,3,2,2

;ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
; CODE
;ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p2m0r0:
        mov bl,[ecx]
        mov al,[esi+ebx+2beaddedh]
p2m0r0m0:
        mov [edi+2bh],al
p2m0r0m1:
        add cl,[edx]
        inc edx
P2M0ROUT0LEN=$-p2m0r0

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p2ir1:                                  ; only increment retrace timer
        inc vrtcntr
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p2ir0:                                  ; slide to faces palette
        cld
        push bx ecx esi edi
        mov edi,_cpalptr
        add edi,10h*3
        mov esi,edi
        mov dx,3c8h
        @outb 10h
        inc edx
        mov ecx,8*3
        rep outsb
        add esi,8*3
        dec edx
        @outb 20h
        inc edx
        mov cl,8*3
        rep outsb
        mov esi,dpalptr0
        mov cl,8*3
        mov bl,1
        call _slidebytes
        setc bh
        add edi,10h*3
        add esi,8*3
        call _slidebytes
        adc bh,0
        cmp bh,2
        jb short p2ir0f0
        mov _vrtrout,offset p2ir1
p2ir0f0:
        inc vrtcntr
        pop edi esi ecx bx
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p2ir2:                                  ; slide faces to transition pal
        cld
        push bx ecx esi edi
        mov edi,_cpalptr
        add edi,10h*3
        mov esi,edi
        mov dx,3c8h
        @outb 10h
        inc edx
        mov ecx,8*3
        rep outsb
        add esi,8*3
        dec edx
        @outb 20h
        inc edx
        mov cl,8*3
        rep outsb
        mov esi,mirrorxpalptr
        mov cl,8*3
        mov bl,1
        call _slidebytes
        setc bh
        add edi,10h*3
        call _slidebytes
        adc bh,0
        cmp bh,2
        jb short p2ir2f0
        mov _vrtrout,offset p2ir1
p2ir2f0:
        inc vrtcntr
        pop edi esi ecx bx
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p2ir3:                                  ; slide to mirror pic palette
        cld
        push bx ecx esi edi
        mov edi,_cpalptr
        add edi,20h*3
        mov esi,edi
        mov dx,3c8h
        @outb 20h
        inc edx
        mov ecx,MIRRORPICPALLEN
        rep outsb
        mov esi,mirrorpicpalptr
        mov ecx,MIRRORPICPALLEN
        mov bl,1
        call _slidebytes
        jnc short p2ir3f0
        mov _vrtrout,offset p2ir1
p2ir3f0:
        pop edi esi ecx bx
        ret

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
_p2:
        mov eax,'p20d'                  ; load and allocate data
        call _loaddata
        mov facessprptr,eax
        add eax,FACESSPRLEN
        mov faceslocptr,eax
        add eax,FACESLOCLEN
        mov facesdeltaptrl,eax
        add eax,100h
        mov facesoffptrl,eax
        add eax,100h
        mov mirrorpictblptr,eax
        mov mirrorpicctbl,eax
        mov mirrorpicptbl[0],eax
        mov mirrorpicptbl[4],eax
        add eax,MIRRORPICTBLLEN
        mov mirrorpicptr,eax
        add eax,MIRRORPICLEN
        mov mirrorsprptr,eax
        add eax,MIRRORSPRLEN
        mov highlightsprptr,eax
        add eax,HIGHLIGHTSPRLEN
        mov dpalptr0,eax
        add eax,FACESPALLEN
        mov mirrorpicpalptr,eax

        add _himembase,0ffh             ; align high mem base on 256 bytes
        mov byte ptr _himembase,0

        mov eax,100h*2+128*4+400h+P2M0ROUT0LEN*35h+MIRRORPICPALLEN
        call _gethimem
        mov facesoffptr,eax
        add eax,100h
        mov facesdeltaptr,eax
        add eax,100h
        mov facesdeltaptr2,eax
        add eax,128*4
        mov facesmisctbl0,eax
        add eax,400h
        mov p2m0rout0,eax
        add eax,P2M0ROUT0LEN*35h
        mov mirrorxpalptr,eax

        mov edi,facesoffptr             ; copy tables to 256 aligned buffers
        mov esi,facesoffptrl
        mov ecx,40h
        rep movsd
        mov edi,facesdeltaptr
        mov esi,facesdeltaptrl
        mov ecx,40h
        rep movsd

        mov edi,facesdeltaptr2          ; build sum/mod 4 delta table
        mov edx,facesdeltaptr
        mov bh,4
p2i0l0:
        mov esi,edi
        mov bl,40h
p2i0l0l0:
        mov al,[edx]
        inc dl
        add al,[edx]
        inc dl
        add al,[edx]
        inc dl
        add al,[edx]
        inc dl
        stosb
        dec bl
        jnz p2i0l0l0
        mov ecx,10h
        rep movsd
        inc edx
        dec bh
        jnz p2i0l0

        mov ebp,offset p2m0rout0        ; build put code
        mov edi,[ebp]
        xor ebx,ebx
p2i0l1:
        mov [ebp],edi
        mov esi,offset p2m0r0
        lea eax,[ebx*4]
        mov dword ptr p2m0r0m0[-4],eax
        mov byte ptr p2m0r0m1[-1],bl
        mov ecx,P2M0ROUT0LEN
        rep movsb
        add ebp,4
        inc ebx
        cmp bl,35h
        jb p2i0l1

        mov edi,facesmisctbl0           ; set up misc calc table
        mov dword ptr p2m0l0l0m0[-4],edi
        xor edx,edx
        mov ecx,facesdeltaptr2
p2i0l2:
        mov ebx,edx
        mov eax,edx
        and al,3
        shl eax,7
        shr ebx,2
        add eax,ebx
        add eax,ecx
        stosd
        inc dl
        jnz p2i0l2

        mov edi,mirrorxpalptr           ; set up faces to pic transition pal
        mov ecx,MIRRORPICPALLEN/3
p2i0l3:
        mov word ptr [edi],3f3fh
        mov byte ptr [edi+2],0
        add edi,3
        loop p2i0l3

        mov dx,3ceh                     ; set read plane select index
        @outb 4

waitl0:
        cmp _vrtrout,offset _ret        ; wait for transition to end
        jne waitl0

        mov _vrtrout,offset p2ir1       ; just a timer tick routine

        mov esi,mirrorxpalptr           ; set part of faces/pic transition pal
        mov ecx,MIRRORPICPALLEN/3-8
        mov al,28h
waitl2:
        cmp vrtcntr,0
        je waitl2
        call _setcpal

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Warping moaning faces in mirror
p2m0:
        movzx edx,faceswaveloc          ; move wave starting points
        movzx ecx,vrttime
        mov bx,word ptr facesdeltawave
        mov ax,word ptr facesoffwave
p2m0l1:
        add al,facesoffwave0[edx]
        add ah,facesoffwave1[edx]
        add bl,facesdeltawave0[edx]
        add bh,facesdeltawave1[edx]
        inc edx
        and dl,7
        dec ecx
        jnz p2m0l1
        mov faceswaveloc,dl
        mov word ptr facesdeltawave,bx
        mov word ptr facesoffwave,ax

        sub esp,P2M0SVL0                ; put warping moaning faces to screen
        mov ebp,faceslocptr
        movzx eax,facespageindex
        mov edi,_vidptr2[eax*4]
        add edi,80*37+14
        mov esi,facessprptr
        xor ebx,ebx
        mov al,22h
        mov p2m0sv4,0
        mov p2m0sv5,0
p2m0l0:
        mov dx,3c5h
        out dx,al
        mov p2m0sv3,al

        movzx edx,facesdeltawave[1]
        movzx ecx,facesoffwave[1]

        mov al,facesoffwave[0]
        add al,p2m0sv5
        mov p2m0sv6,al
        mov p2m0sv2,148
p2m0l0l0:
        add edx,facesdeltaptr
        add ecx,facesoffptr
        mov bh,[ecx]
        add cl,[edx]
        inc dl
        mov p2m0sv0,dl
        mov p2m0sv1,cl

        movzx edx,facesdeltawave[0]
        add dl,p2m0sv4
        mov edx,[edx*4+2beaddedh]
p2m0l0l0m0:
        movzx ecx,p2m0sv6
        add ecx,facesoffptr

        movzx eax,byte ptr [ebp+1]
        mov eax,p2m0rout0[eax*4]
        mov byte ptr [eax],0c3h
        movzx eax,byte ptr [ebp]
        call p2m0rout1[eax*4]
        movzx eax,byte ptr [ebp+1]
        mov eax,p2m0rout0[eax*4]
        mov byte ptr [eax],8ah

        add ebp,2
        add edi,80
        add esi,256
        movzx edx,p2m0sv0
        movzx ecx,p2m0sv1
        add p2m0sv6,3
        dec p2m0sv2
        jnz p2m0l0l0

        mov al,p2m0sv3
        rol al,1
        cmc
        sbb edi,80*148-1
        sub esi,256*148-1

        movzx edx,facesdeltawave[0]
        mov ah,p2m0sv4
        add dl,ah
        inc ah
        mov p2m0sv4,ah
        add edx,facesdeltaptr
        mov ah,[edx]
        add p2m0sv5,ah

        cmp al,22h
        jne p2m0l0
        add esp,P2M0SVL0

        mov ebp,80*141                  ; put highlight over faces
        movzx eax,facespageindex
        mov edi,_vidptr2[eax*4]
        add edi,80*37+19h
        mov esi,80
        mov dh,3
        mov cx,11h
        mov bx,3030h
        call highlightsprptr

        mov dx,3d5h                     ; set new page
        movzx ebx,facespageindex
        @outb facespagetbl[ebx]
        xor bl,1
        mov facespageindex,bl

        mov al,vrtcntr                  ; wait for a vertical retrace
waitl1:
        cmp al,vrtcntr
        je waitl1
        mov al,vrtcntr                  ; time retraces per frame
        mov ah,ovrtcntr
        mov ovrtcntr,al
        sub al,ah
        mov vrttime,al

        jmp p2m0seqrout

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p2m0sr0:                                ; set palette slide to faces palette
        mov _vrtrout,offset p2ir0
        mov p2m0seqrout,offset p2m0sr1
        jmp p2m0
;-----------------------------------------------------------------------------
p2m0sr1:                                ; wait for muzik meta point
        cmp _muzloc,MUZLOC0
        jb p2m0
        mov _vrtrout,offset p2ir2
        mov p2m0seqrout,offset p2m0sr2
        jmp p2m0
;-----------------------------------------------------------------------------
p2m0sr2:                                ; wait for palette phade to end
        cmp _vrtrout,offset p2ir2
        je p2m0

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
p2i1:
        mov ebx,80*200                  ; put mirror pic to pages 0 and 1
        mov esi,mirrorpicptr
        mov edi,_vidptr0
        call _pbmodex
        mov edi,_vidptr1
        call _pbmodex

        mov edi,_vidptr2                ; put pic in mirror on pages 2 and 3
        call p2i1r0
        mov edi,_vidptr3
        call p2i1r0

        mov _vrtrout,offset p2ir3       ; set slide to mirror pic pal rout

        mov edx,0a8000h                 ; set up selectors for zoom routine
        mov ax,_sel[0]
        call _setselector
        mov edx,0ac000h
        mov ax,_sel[2]
        call _setselector
        @php edx,mirrorsprptr
        mov ax,_sel[4]
        call _setselector

waitl3:                                 ; wait for palette slide to end
        cmp _vrtrout,offset p2ir3
        je waitl3

        mov word ptr vrtcntr,0          ; set up for mirror zoom
        mov vrttime,1

;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; Zoom mirror out
p2m1:
        sub esp,P2M1SVL0                ; put pieces of pic revealed
        mov dx,3c5h
        @outb 0fh
        mov dl,0ceh
        @outw 4105h
        mov ebp,mirrorpicctbl
        movzx eax,vrttime
        imul eax,400
        add ebp,eax
        mov mirrorpicctbl,ebp
        movzx eax,facespageindex
        mov edx,_vidptr2[eax*4]
        mov esi,_vidptr1
        mov ebx,ebp
        xchg ebx,mirrorpicptbl[eax*4]
        xor ecx,ecx
        mov eax,200
p2m1l0:
        mov p2m1sv1,al
        mov al,[ebp]
        cmp al,-1
        je short p2m1l0c

        mov p2m1sv0,esi
        lea edi,[edx+eax]
        add esi,eax
        mov cl,[ebx]
        cmp cl,-1
        je short p2m1l0f0
        sub cl,al
        add cl,2
        rep movsb
        mov esi,p2m1sv0
        mov al,[ebx+1]
        dec eax
        lea edi,[edx+eax]
        add esi,eax
        mov cl,[ebp+1]
        inc ecx
        sub cl,al
        rep movsb

        jmp short p2m1l0c2
p2m1l0f0:
        mov cl,[ebp+1]
        inc ecx
        sub cl,al
        rep movsb
p2m1l0c2:
        mov esi,p2m1sv0
p2m1l0c:
        mov al,p2m1sv1
        add esi,80
        add edx,80
        add ebp,2
        add ebx,2
        dec al
        jnz p2m1l0
        mov dx,3cfh
        @outb 40h
        add esp,P2M1SVL0

        movzx eax,facespageindex        ; put scaled mirror
        mov es,_sel[eax*2]
        xor edi,edi
        xor esi,esi
        mov ecx,dword ptr mirrorzoomlen
        mov ebx,0a800d6h
        mov eax,dword ptr mirrorzoomloc
        mov ds,_sel[4]
        call _psbm
        mov ax,cs:_seldata
        mov es,ax
        mov ds,ax

        mov dx,3d5h                     ; set new page
        movzx ebx,facespageindex
        @outb facespagetbl[ebx]
        xor bl,1
        mov facespageindex,bl

        mov al,vrtcntr                  ; wait for a vertical retrace
waitl4:
        cmp al,vrtcntr
        je waitl4
        mov al,vrtcntr                  ; time retraces per frame
        mov ah,ovrtcntr
        mov ovrtcntr,al
        sub al,ah
        mov vrttime,al

        movzx eax,al                    ; increase zoom level
        sub mirrorzoomloc[0],ax
        sub mirrorzoomloc[2],ax
        lea eax,[eax*2]
        add mirrorzoomlen[0],ax
        add mirrorzoomlen[2],ax

        cmp mirrorzoomloc[0],-59
        jg p2m1

;-----------------------------------------------------------------------------
        mov dx,3d5h                     ; set page 0
        @outb 0

        mov eax,_ohimembase             ; clean up high memory base ptr
        mov _himembase,eax
        mov _vrtrout,offset _ret        ; clear retrace routine

        ret

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p2m0r1:                                 ; increment to visible table part
        db 26 dup(2,0ah,42h)    ; add cl,[edx], inc edx
        jmp p2m0rout0[eax*4]

;ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
p2i1r0:                                 ; put part of pic in mirror
        mov ebp,faceslocptr
        add edi,80*37+14
        mov esi,mirrorpicptr
        add esi,80*200+80*37+14
        mov dx,3c5h
        xor ecx,ecx
        xor ebx,ebx
        mov al,22h
p2i1r0l0:
        out dx,al
        mov ah,148
        push esi edi
p2i1r0l0l0:
        push esi edi
        mov bl,[ebp]
        mov cl,[ebp+1]
        add edi,ebx
        add esi,ebx
        sub cl,bl
        rep movsb
        pop edi esi
        add ebp,2
        add edi,80
        add esi,80
        dec ah
        jnz p2i1r0l0l0
        pop edi esi
        add esi,80*200
        rol al,1
        jnc short p2i1l0c
        inc edi
        sub esi,80*200*4-1
p2i1l0c:
        cmp al,22h
        jne p2i1r0l0
        ret

code32  ends
        end

