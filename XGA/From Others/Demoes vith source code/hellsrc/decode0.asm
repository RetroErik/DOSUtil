        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32

public  _decode0ibufptr, _decode0ibuflen

public  _decode0

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
_decode0ibufptr dd      ?               ; must be in low mem, (can share with
_decode0ibuflen dd      1000h           ;                      _filebufloc)

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Decode from a compressed input stream
; In:
;   EAX -> stream input routine (In:ECX=len,EDX->buf, Out:EAX=len,CF=1 error)
;   EDI -> decode buffer
; Out:
;   CF=1 - error in stream
;   CF=0 - no error
;     EAX - decompressed size
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_decode0:
        pushad
        mov esi,_decode0ibufptr
        lea edx,[esi-128]
        mov eax,_decode0ibuflen
        add esi,eax
        add edx,eax
        xor ecx,ecx
        mov bx,(18*256)+3
        call decoder0
        jc short decoded
decodeml:
        cmp esi,edx
        jae short decodef4
decodef0:
        mov bp,[esi]
        add esi,2
        stc
        rcr bp,1
        jc short decodef3
decodef1:
        movsb
        shr bp,1
        jc short decodef2
        movsb
        shr bp,1
        jc short decodef2
        movsb
        shr bp,1
        jc short decodef2
        movsb
        shr bp,1
        jnc decodef1
decodef2:
        jz decodeml
decodef3:
        movzx eax,word ptr [esi]
        add esi,2
        mov cl,al
        shr eax,4
        neg eax
        add eax,edi
        and cl,01111b
        add cl,bl
        cmp cl,bh
        je short decodef5
        xchg esi,eax
        rep movsb
        mov esi,eax
        shr bp,1
        jc decodef2
        jmp decodef1
decodef4:
        call decoder0
        jnc decodef0
decoded:
        popad
        ret
decodef5:
        add cl,[esi]
        jc short decodef7
decodef6:
        inc esi
        xchg esi,eax
        rep movsb
        mov esi,eax
        shr bp,1
        jc decodef2
        jmp decodef1
decodef7:
        rcl ch,1
        cmp cl,011h
        jne decodef6
        sub edi,[esp]
        mov [esp+28],edi
        clc
        popad
        ret
;-----------------------------------------------------------------------------
decoder0:
        push ecx edx edi
        mov ecx,_decode0ibufptr
        mov edi,ecx
        add ecx,_decode0ibuflen
        push ecx
        sub ecx,esi
        shr ecx,1
        rep movsw
        adc cl,0
        rep movsb
        pop ecx
        sub ecx,edi
        mov edx,edi
        call [esp+44]
        mov esi,_decode0ibufptr
        pop edi edx ecx
        ret


code32  ends
        end

