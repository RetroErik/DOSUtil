; Simple 669 playback routine using 'gs' lowlevel GUS routines.

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include gs.inc

public  ord

public  _muzloc, _muzend, _muzrow, _muzord, _muzloop, _muzeord

public  _gsp669_init, _gsp669_uninit, _gsp669_load, _gsp669_play, _gsp669_stop

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
align 4
ordptr          dd      ?               ; ptr to order list
tempoptr        dd      ?               ; ptr to tempo list
breakptr        dd      ?               ; ptr to break list
patbaseptr      dd      ?               ; ptr to base of patterns
instptr         dd      ?               ; ptr to sample data

currowptr       dd      ?               ; ptr to next row to play

_muzloc         label   word            ; ord:row                            |
_muzrow         db      ?               ; current row playing                |
_muzord         db      ?               ; current order playing              |
_muzend         label   word            ; end:loop                          |
_muzloop        db      ?               ; loop point of 669                 |
_muzeord        db      ?               ; last+1 order of 669               |

panloc          db      0               ; base of ping-pong pan
tempo           db      ?               ; tempo
tempoc          db      ?               ; tempo counter                      |
row             db      ?               ; current row                        |
ord             db      ?               ; current order                      |
break           db      ?               ; row of break                       |

pantbl          db      3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
                db      12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
                db      3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
                db      12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
                db      3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
                db      12,12,12,11,11,10,9,8,7,6,5,4,4,3,3,3
                db      3,3,3,4,4,5,6,7,8,9,10,11,11,12,12,12
                db      12,12,12,11,11,10,9,8,7,6,5,4
;               db      0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;               db      15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
;               db      0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;               db      15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
;               db      0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;               db      15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0
;               db      0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;               db      15,14,13,12,11,10,9,8,7,6,5,4

voltbl          db      004h,0a0h,0b0h,0c0h,0c8h,0d0h,0d8h,0e0h
                db      0e4h,0e8h,0ech,0f0h,0f2h,0f4h,0f6h,0f8h

freqtbl         dw      56,59,62,66,70,74,79,83,88,94,99,105
                dw      112,118,125,133,141,149,158,167,177,188,199,211
                dw      224,237,251,266,282,299,317,335,355,377,399,423
                dw      448,475,503,532,564,598,634,671,711,754,798,846
                dw      896,950,1006,1065,1129,1197,1268,1343,1423,1508,1597,1692

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Main playback routine called by GUS IRQ routine
mr:
        mov al,tempoc
        dec al
        jnz mrd

        mov esi,currowptr
        mov ax,word ptr row
        inc al
        cmp al,break
        jbe short mrf0
        xor al,al
        inc ah
        cmp ah,_muzeord
        jbe short mrf1
        mov ah,_muzloop
mrf1:
        movzx ebp,ah
        mov edi,ordptr
        movzx esi,byte ptr ds:[ebp+edi]
        mov edi,tempoptr
        mov bl,[edi+esi]
        mov tempo,bl
        mov edi,breakptr
        mov bl,[edi+esi]
        mov break,bl
        lea esi,[esi*2+esi]
        shl esi,9
        add esi,patbaseptr
mrf0:
        mov word ptr row,ax
        mov _muzloc,ax

        movzx edx,panloc
        inc dl
        and dl,3fh
        mov panloc,dl
        mov edi,instptr
        mov ebp,7
mrl0:
        mov al,[esi+2]
        mov ah,al
        and al,0f0h
        cmp al,50h
        jne short mrl0f0
        and ah,0fh
        mov tempo,ah
mrl0f0:
        mov bl,pantbl[edx+ebp*4]
        mov _vcpan[ebp],bl
        or _vccmnd[ebp],2
        mov ax,[esi]
        cmp al,0feh
        ja mrl0c
        movzx ebx,ah
        and bl,0fh
        mov bl,voltbl[ebx]
        mov _vcvol[ebp],bl
        or _vccmnd[ebp],1
        cmp al,0feh
        je short mrl0c
        xchg al,ah
        shr ax,2
        shr al,2
        movzx ebx,ah
        mov cx,freqtbl[ebx*2]
        mov _vcfreq[ebp*2],cx
        movzx ebx,al
        lea ebx,[ebx*4+ebx]
        lea ebx,[ebx*4+ebx]
        mov al,[edi+ebx+12]
        mov _vccntrl[ebp],al
        mov eax,[edi+ebx+13]
        mov _vcsbeg[ebp*4],eax
        mov eax,[edi+ebx+17]
        mov _vclbeg[ebp*4],eax
        mov eax,[edi+ebx+21]
        mov _vclend[ebp*4],eax
        mov _vccmnd[ebp],8
mrl0c:
        add esi,3
        sub ebp,1
        jnc mrl0

        mov currowptr,esi
        mov al,tempo
mrd:
        mov tempoc,al
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Init 669 player and low level gus crap
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_init:
        mov _gustimerfreq,9ch
        mov _gusnumvoices,0cfh
        call _gs_init
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Reset 669 player and low level gus crap
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_uninit:
        call _gsp669_stop
        call _gs_uninit
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Load a 669, samples go directly into GUS ram
; In:
;   EAX -> stream input routine (In:ECX=len,EDX->buf, Out:EAX=len,CF=1 error)
;   EDX -> buffer large enough for all music data plus largest sample
; Out:
;   EAX - number of bytes of buffer to keep
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_load:
        pushad
        mov ebp,edx
        mov ecx,1f1h
        call eax
        mov al,[edx+70h]
        mov _muzloop,al
        lea eax,[edx+71h]
        mov ordptr,eax
        add eax,80h
        mov tempoptr,eax
        add eax,80h
        mov breakptr,eax
        add edx,ecx
        mov instptr,edx
        lea esi,[edx+13]
        movzx edi,byte ptr [ebp+6eh]
        imul ecx,edi,25
        call dword ptr [esp+28]
        add edx,ecx
        mov patbaseptr,edx
        movzx ecx,byte ptr [ebp+6fh]
        lea ecx,[ecx*2+ecx]
        shl ecx,9
        call dword ptr [esp+28]
        add edx,ecx
        xor ebx,ebx
gsp669loadl0:
        mov ecx,[esi]
        add esi,25
        jecxz gsp669loadl0c
        call dword ptr [esp+28]
        push ecx
gsp669loadl2:
        xor byte ptr [edx],80h
        inc edx
        loop gsp669loadl2
        pop ecx
        sub edx,ecx
        call _gs_putram
        add ebx,ecx
gsp669loadl0c:
        dec edi
        jnz gsp669loadl0
        sub edx,[esp+20]
        mov [esp+28],edx

        mov esi,instptr
        movzx ecx,byte ptr [ebp+6eh]
        xor ebx,ebx
gsp669loadl1:
        mov edx,[esi+13]
        mov [esi+13],ebx
        mov al,8
        cmp edx,[esi+21]
        jae short gsp669loadl1c
        xor al,al
        mov [esi+21],edx
gsp669loadl1c:
        add [esi+17],ebx
        add [esi+21],ebx
        dec dword ptr [esi+21]
        mov [esi+12],al
        add ebx,edx
        add esi,25
        loop gsp669loadl1

        popad
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Play a loaded 669
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_play:
        push ax ecx edi
        call _gsp669_stop
        mov edi,ordptr
        mov ecx,80h
        mov al,0ffh
        repne scasb
        sub cl,7eh
        neg cl
        mov _muzeord,cl
        mov _muzloc,0
        mov panloc,0
        mov dword ptr tempoc,0ff0001h
        mov _gusrout,offset mr
        pop edi ecx ax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Stop playback
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gsp669_stop:
        mov _gusrout,offset _ret
        mov dword ptr _vcvol[0],4040404h
        mov dword ptr _vcvol[4],4040404h
        mov dword ptr _vccmnd[0],1010101h
        mov dword ptr _vccmnd[4],1010101h
        ret

code32  ends
        end

