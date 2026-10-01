; GUS lowlevel interface.

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc

public  _gusrout, _gusport, _gusirq, _gusram
public  _vccmnd, _vccntrl, _vcsbeg, _vclbeg, _vclend, _vcfreq, _vcpan, _vcvol
public  _gustimerfreq, _gusnumvoices

public  _gs_init, _gs_uninit, _gs_putram, _gs_getram

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
align 4
EXTRACRAP       = 1                     ; 0=no extras, 1=yes extras

aclbeg          dd      32 dup(?)       ; actual channel loop begin          |
aclend          dd      32 dup(?)       ; actual channel loop end            |
acfreq          dw      32 dup(?)       ; actual channel frequency value     |
acpan           db      32 dup(?)       ; actual channel pan position        |
acvol           db      32 dup(?)       ; actual channel volume (high byte)  |
                                        ;                                    |
_vccmnd         db      16 dup(?)       ; virtual channel command bits       |
                                        ;  bit 0: volume change
                                        ;  bit 1: balance change
                                        ;  bit 2: frequency change
                                        ;  bit 3: sample note-on
_vccntrl        db      16 dup(?)       ; virtual channel voice control
                                        ;  bit 3: enable loop
                                        ;  bit 4: bi-directional loop
                                        ;  bit 6: 0=forward, 1=reverse
_vcsbeg         dd      16 dup(?)       ; virtual channel sample begin
_vclbeg         dd      16 dup(?)       ; virtual channel loop begin
_vclend         dd      16 dup(?)       ; virtual channel loop end
_vcfreq         dw      16 dup(?)       ; virtual channel frequency value
_vcpan          db      16 dup(?)       ; virtual channel pan position
_vcvol          db      16 dup(?)       ; virtual channel volume (high byte)

vcacoff         db      16 dup(0)       ; virtual channel offset in actual

ormgusirqvect   dd      ?               ; old real mode GF1 IRQ vector

gusport102      dw      ?               ; GUS port + 102h
gusport103      dw      ?               ; GUS port + 103h
gusport104      dw      ?               ; GUS port + 104h
gusport107      dw      ?               ; GUS port + 107h

_gusrout        dd      _ret            ; routine to call on every timer tick
_gusport        dw      220h
_gusirq         db      11
_gusram         db      0               ; 1=256k, 2=512k, 3=768k, 4=1024k
_gustimerfreq   db      0cch            ; =256-((1000000/Hz)/320)
_gusnumvoices   db      0dfh            ; =((Voices*2)-1)|0xc0

rmgusirqbuf     db      21 dup(?)       ; buffer for rm GF1 IRQ callback code

port103val      db      43h             ; value to set on exit from IRQ
irqm0tbl        dw      0c089h,0a0e6h
gusirqvaltbl    db      0,0,41h,43h,0,42h,0,44h,0,0,0,45h,46h,0,0,47h
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;-----------------------------------------------------------------------------
@gusoutb        macro   index,value
        mov al,&index
        out dx,al
        add dl,2
        mov al,&value
        out dx,al
        sub dl,2
endm

@gusoutw        macro   index,value
        mov al,&index
        out dx,al
        inc edx
        mov ax,&value
        out dx,ax
        dec edx
endm

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; GUS timer IRQ entry
irq:
        push eax
        mov al,20h
        out 20h,al
irqm0           dw      ?       ; out 0a0h,al | mov eax,eax
        sti
        cld
        push ebx ecx edx esi edi ebp ds
        mov ds,cs:_seldata
        mov dx,gusport103               ; reenable GUS timer
        @outb 45h
        add dl,2
        @outb 0
        @outb 8

        call _gusrout

;-----------------------------------------------------------------------------
        mov dx,gusport103
        mov ebp,15
irql0:
        xor cl,cl
        xchg cl,_vccmnd[ebp]
        or cl,cl
        jz irql0c

        movzx edi,vcacoff[ebp]
        lea edi,[ebp*2+edi]

        test cl,8
        jz short irql0f0
        xor vcacoff[ebp],1
        mov eax,edi
        dec edx
        out dx,al
        inc edx
        mov bl,acvol[edi]
        @gusoutb 7,4
        @gusoutb 8,bl
        @gusoutb 9,bl
        @gusoutb 0dh,40h
        xor edi,1
        or cl,7
irql0f0:

        mov eax,edi
        dec edx
        out dx,al
        inc edx

        test cl,4
        jz short irql0f1
        mov bx,_vcfreq[ebp*2]
        cmp bx,acfreq[edi*2]
        je short irql0f1
        mov acfreq[edi*2],bx
        @gusoutw 1,bx
irql0f1:

        test cl,2
        jz short irql0f2
        mov bl,_vcpan[ebp]
        cmp bl,acpan[edi]
        je short irql0f2
        mov acpan[edi],bl
        @gusoutb 0ch,bl
irql0f2:

        test cl,8
        jz irql0f3
        mov esi,_vclbeg[ebp*4]
        cmp esi,aclbeg[edi*4]
        je short irql0f2f0
        mov aclbeg[edi*4],esi
        shrd bx,si,7
        shr esi,7
        @gusoutw 2,si
        @gusoutb 3,bh
irql0f2f0:
        mov esi,_vclend[ebp*4]
        cmp esi,aclend[edi*4]
        je short irql0f2f1
        mov aclend[edi*4],esi
        shrd bx,si,7
        shr esi,7
        @gusoutw 4,si
        @gusoutb 5,bh
irql0f2f1:
        mov esi,_vcsbeg[ebp*4]
        shrd bx,si,7
        shr esi,7
        @gusoutw 0ah,si
        @gusoutb 0bh,bh
        @gusoutb 0,_vccntrl[ebp]
irql0f3:

        test cl,1
        jz short irql0f4
        mov bl,_vcvol[ebp]
        mov bh,acvol[edi]
        mov ah,bh
        cmp bh,bl
        je short irql0f4
        mov ch,40h
        ja short irql0f3f0
        xchg bl,bh
        xor ch,ch
irql0f3f0:
        @gusoutb 7,bl
        @gusoutb 8,bh
        @gusoutb 9,ah
        @gusoutb 0dh,ch
irql0f4:

        mov dx,300h
        db 7 dup(0ech)          ; in al,dx
        mov dx,gusport103

        test cl,1
        jz short irql0f5
        mov al,_vcvol[ebp]
        cmp al,ah
        je short irql0f5
        mov acvol[edi],al
        @gusoutb 9,ah
        @gusoutb 0dh,ch
irql0f5:

        test cl,8
        jz short irql0c
        mov esi,_vcsbeg[ebp*4]
        shrd bx,si,7
        shr esi,7
        @gusoutw 0ah,si
        @gusoutb 0bh,bh
        @gusoutb 0,_vccntrl[ebp]
        xor edi,1
        mov eax,edi
        dec edx
        out dx,al
        inc edx
        mov bl,4
        xchg bl,acvol[edi]
        @gusoutb 9,bl
        @gusoutb 0dh,40h

irql0c:
        sub ebp,1
        jnc irql0

        @outb port103val

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
irqdone:
        pop ds ebp edi esi edx ecx ebx eax
        iretd

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; A small delay, In: ECX - number of times to do delay
gusdelay:
        push ax dx
        mov dx,300h
gusdelayl0:
        in al,dx
        in al,dx
        in al,dx
        in al,dx
        in al,dx
        in al,dx
        in al,dx
        loop gusdelayl0
        pop dx ax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Shove some crap into GUS ram
; In:
;   EBX - addx in GUS ram to shove into
;   ECX - amount of crap to shove
;   EDX -> actual crap to shove
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gs_putram:
        push eax ebx ecx dx esi
        mov esi,edx
        mov dx,gusport104
gsputraml0:
        dec edx
        mov al,44h
        mov port103val,al
        out dx,al
        add dl,2
        shld eax,ebx,16
        out dx,al
        sub dl,2
        mov al,43h
        mov port103val,al
        out dx,al
        inc edx
gsputraml1:
        mov ax,bx
        out dx,ax
        add dl,3
        outsb
        sub dl,3
        inc bx
        loopnz gsputraml1
        jecxz short gsputramd
        add ebx,10000h
        jmp gsputraml0
gsputramd:
        pop esi dx ecx ebx eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Rip some crap outta GUS ram
; In:
;   EBX - addx in GUS ram to rip from
;   ECX - amount of crap to rip
;   EDX -> buffer for ripped crap
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gs_getram:
        push eax ebx ecx dx edi
        mov edi,edx
        mov dx,gusport104
gsgetraml0:
        dec edx
        mov al,44h
        mov port103val,al
        out dx,al
        add dl,2
        shld eax,ebx,16
        out dx,al
        sub dl,2
        mov al,43h
        mov port103val,al
        out dx,al
        inc edx
gsgetraml1:
        mov ax,bx
        out dx,ax
        add dl,3
        insb
        sub dl,3
        inc bx
        loopnz gsgetraml1
        jecxz short gsgetramd
        add ebx,10000h
        jmp gsgetraml0
gsgetramd:
        pop edi dx ecx ebx eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize GUS sound system
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gs_init:
        pushad
        mov ax,900h
        int 31h
        push ax

        mov dx,_gusport                 ; set up all port vars
        @outb 0bh
        add dx,102h
        mov gusport102,dx
        inc edx
        mov gusport103,dx
        inc edx
        mov gusport104,dx
        add dl,3
        mov gusport107,dx

        sub dl,4                        ; initialize GUS
        @outb 4ch
        add dl,2
        @outb 0
        mov ecx,10h
        call gusdelay
        @outb 1
        sub dl,2
        mov ecx,10h
        call gusdelay
        @gusoutb 41h,0
        @gusoutb 45h,0
        @gusoutb 49h,0
        @outb 0eh
        add dl,2
        @outb _gusnumvoices
        sub dl,3

        mov bl,1fh                      ; set up all voices
gsinitl0:
        mov al,bl
        and al,7fh
        out dx,al
        inc edx
        @gusoutw 9,0
        @gusoutb 0,0
        @gusoutb 0dh,3
        @gusoutb 6,16
        @outb 0ch
        add dl,2
        @outb 7
        sub dl,3
        mov ecx,1
        call gusdelay
        xor bl,80h
        js gsinitl0
        sub bl,1
        jnc gsinitl0

        sub dx,0f3h                     ; damn, another undocumented port
        @outb 5
        sub dl,0fh
        @outb 8
        add dl,0bh
        xor al,al
        out dx,al
        add dl,4
        out dx,al
        sub dl,0fh

        movzx ebx,_gusirq               ; set IRQ channels
        @outb 4bh
        add dl,0bh
        mov al,gusirqvaltbl[ebx]
        out dx,al
        sub dl,0bh
        @outb 9
        add dx,103h

        @outb 43h                       ; how much RAM on the card
        inc edx
        @outw 0ffffh
        dec edx
        @outb 44h
        add dl,2
        mov cl,3
gsinitl1:
        @outb cl
        add dl,2
        in al,dx
        inc eax
        mov ah,al
        out dx,al
        in al,dx
        sub dl,2
        cmp al,ah
        jne short gsinitl1d
        inc _gusram
        add cl,4
        test cl,10h
        jz gsinitl1
gsinitl1d:
        sub dl,2

        mov edi,offset aclbeg           ; set some beginning values
        mov ecx,80
        mov eax,0ffffffffh
        rep stosd
        mov eax,7070707h
        mov cl,8
        rep stosd
        xor eax,eax
        mov cl,12
        rep stosd

        @gusoutb 4ch,3                  ; enable GUS normal operation

        @gusoutb 47h,_gustimerfreq      ; start GUS timer
        @outb 45h
        add dl,2
        @outb 8
        sub dx,0fdh
        @outb 4
        inc edx
        @outb 2

        cmp bl,2                        ; set and enable GF1 IRQ (BL=IRQ num)
        jne short $+4
        mov bl,9
        cmp bl,7
        seta al
        movzx eax,al
        mov ax,irqm0tbl[eax*2]
        mov irqm0,ax
        mov edx,offset irq
        call _setirqvect
        xor al,al
        call _setirqmask
        mov edi,offset rmgusirqbuf
        call _rmpmirqset
        mov ormgusirqvect,edx

        pop ax
        int 31h
        popad
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Uninitialize GUS sound system
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gs_uninit:
        push ax bx edx
        mov ax,900h
        int 31h
        push ax

        mov bl,_gusirq                  ; Kill GUS IRQ handler
        cmp bl,2
        jne short $+4
        mov bl,9
        mov edx,ormgusirqvect
        call _rmpmirqfree
        mov al,1
        call _setirqmask

        mov dx,gusport103               ; Shut down GUS
        @outb 4ch
        add dl,2
        @outb 0
        sub dx,105h
        @outb 0bh

        pop ax
        int 31h
        pop edx bx ax
        ret

if EXTRACRAP ne 0
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; EXTRA CRAP
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

include kb.inc

extrn   _putdosmsg:near

public  _gs_find, _gs_ask, _gs_test

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; EXTRA CRAP DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
pspultrastr     db      'ULTRASND'

askmsg0         db      'Where''s the Ultrasound bub...?',0dh,0ah
                db      '    0) I aint got one.',0dh,0ah
                db      '    1) 210h.',0dh,0ah
                db      '    2) 220h.',0dh,0ah
                db      '    3) 230h.',0dh,0ah
                db      '    4) 240h.',0dh,0ah
                db      '    5) 250h.',0dh,0ah
                db      '    6) 260h.',0dh,0ah
                db      'ENTER) 220h and 11 (default).',0dh,0ah,'$'
askmsg1         db      0dh,0ah,'And what''s the magic IRQ number...?',0dh,0ah
                db      '    0) 2',0dh,0ah
                db      '    1) 3',0dh,0ah
                db      '    2) 5',0dh,0ah
                db      '    3) 7',0dh,0ah
                db      '    4) 11',0dh,0ah
                db      '    5) 12',0dh,0ah
                db      '    6) 15',0dh,0ah,'$'

irqtbl          db      2,3,5,7,11,12,15

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; EXTRA CRAP CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Find a GUS (environment variable)
; Out:
;   EAX,ECX,ESI,EDI - ?
;   CF=0 - found GUS
;   CF=1 - no GUS found
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gs_find:
        mov esi,_pspa
        movzx esi,word ptr gs:[esi+2ch]
        shl esi,4
gsfindl3:
        mov edi,offset pspultrastr
        mov ecx,8
        repe cmps byte ptr gs:[esi],byte ptr es:[edi]
        jne short gsfindf0
        mov edi,10h
        call gsfindr0
        mov _gusport,cx
        call gsfindr0
        call gsfindr0
        mov edi,10
        call gsfindr0
        mov _gusirq,cl
        clc
        ret
gsfindf0:
        lea esi,[esi+ecx-8]
gsfindl0:
        inc esi
        cmp byte ptr gs:[esi-1],0
        jne gsfindl0
        cmp byte ptr gs:[esi],0
        jne gsfindl3
        stc
        ret
;-----------------------------------------------------------------------------
gsfindr0:
        movzx eax,byte ptr gs:[esi]
        inc esi
        sub al,'0'
        jc gsfindr0
        cmp al,9
        ja gsfindr0
        mov ecx,eax
gsfindr0l0:
        mov al,gs:[esi]
        inc esi
        sub al,'0'
        jc gsfindr0d
        cmp al,9
        ja gsfindr0d
        imul ecx,edi
        add ecx,eax
        jmp gsfindr0l0
gsfindr0d:
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Ask if GUS present and for port and IRQ
; Out:
;   EAX,EDX - ?
;   CF=0 - no GUS
;   CF=1 - GUS be here
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gs_ask:
        mov byte ptr _gusport,20h
        mov _gusirq,11
        mov edx,offset askmsg0
        call _putdosmsg
gsaskl1:
        call _getch
        cmp al,13
        je short gsaskd
        sub al,'0'
        jc gsaskl1
        je short gsaska
        cmp al,6
        ja gsaskl1
        shl al,4
        mov byte ptr _gusport,al
        mov edx,offset askmsg1
        call _putdosmsg
gsaskl0:
        call _getch
        sub al,'0'
        jc gsaskl0
        cmp al,6
        ja gsaskl0
        movzx eax,al
        mov al,irqtbl[eax]
        mov _gusirq,al
gsaskd:
        clc
        ret
gsaska:
        stc
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Test _gusport
; Out:
;   AX,BL,DX - ?
;   CF=0 - GUS failed
;   CF=1 - GUS passed
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gs_test:                       ; Temporarily out of service
        clc
        ret
;       mov ax,900h
;       int 31h
;       push ax
;       mov dx,_gusport
;       add dx,103h
;       @outb 44h
;       in al,dx
;       cmp al,44h
;       jne short gstesta
;       add dl,2
;       @outb 0
;       sub dl,2
;       @outb 43h
;       inc edx
;       @outw 0
;       add dl,3
;       in al,dx
;       mov bl,al
;       sub dl,3
;       @outw 1
;       add dl,3
;       not bl
;       @outb bl
;       sub dl,3
;       @outw 0
;       add dl,3
;       in al,dx
;       cmp al,bl
;       je short gstesta
;       sub dl,3
;       @outw 1
;       add dl,3
;       in al,dx
;       cmp al,bl
;       jne short gstesta
;       clc
;       pop ax
;       int 31h
;       ret
gstesta:
;       stc
;       pop ax
;       int 31h
;       ret
endif

code32  ends
        end

