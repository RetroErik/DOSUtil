        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc

public  _kbtbl0, _kbtbl1, _kbchar, _kbshift, _kbhit

public  _initkb, _resetkb, _getch, _clearkb

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
opmirq1         dd      ?               ; old IRQ1 vektor
ormirq1         dd      ?               ; old real mode IRQ1 vektor

_kbtbl0         db      80h dup(0)      ; non-sticky keyboard table
_kbtbl1         db      80h dup(0)      ; sticky keyboard table
_kbchar         db      ?               ; last key that was hit
_kbshift        db      ?               ; shift states for lask key
_kbhit          db      0               ; 0=no key hit, 1=key hit available

kbrmirqbuf      db      21 dup(?)

kbxtbl          db      0,14,'1234567890-=',16,15,'qwertyuiop[]',13,0
                db      'asdfghjkl;''`',0,'\zxcvbnm,./',0,'*',0,32,0
                db      1,2,3,4,5,6,7,8,9,10,0,0,19,25,21,'-',23,'5'
                db      24,'+',20,26,22,17,18,0,0,0,11,12,27h dup(0)
                db      0,14,'!@#$%^&*()_+',16,15,'QWERTYUIOP{}',13,0
                db      'ASDFGHJKL:"~',0,'|ZXCVBNM<>?',0,'*',0,32,0
                db      1,2,3,4,5,6,7,8,9,10,0,0,19,25,21,'-',23,'5'
                db      24,'+',20,26,22,17,18,0,0,0,11,12,27h dup(0)
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
irq1:
        push ax ebx ds
        mov ds,cs:_seldata
        in al,60h
        movzx ebx,al
        btr ebx,7
        setnc al
        mov _kbtbl0[ebx],al
        or _kbtbl1[ebx],al
        or al,al
        jz short irq1d
        mov ah,_kbtbl0[2ah]
        or ah,_kbtbl0[36h]
        mov bh,ah
        shl bh,7
        add bl,bh
        movzx ebx,bl
        mov al,kbxtbl[ebx]
        or al,al
        jz short irq1d
        mov _kbchar,al
        mov _kbhit,1
        mov al,_kbtbl0[1dh]
        shl al,1
        or al,_kbtbl0[38h]
        shl al,1
        or al,ah
        mov _kbshift,al
irq1d:
        pop ds ebx
        mov al,20h
        out 20h,al
        pop ax
        sti
        iretd

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize keyboard handler
; Out:
;   BX,EDX,EDI - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_initkb:
        mov bl,1
        call _getirqvect
        mov opmirq1,edx
        mov edx,offset irq1
        call _setirqvect
        mov edi,offset kbrmirqbuf
        call _rmpmirqset
        mov ormirq1,edx
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Reset keyboard handler
; Out:
;   BX,EDX - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_resetkb:
        mov bl,1
        mov edx,ormirq1
        call _rmpmirqfree
        mov edx,opmirq1
        jmp _setirqvect
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get the last character pressed
; Out:
;   AL - case adjusted character
;   AH - shift state bits: 0=ALT, 1=CTRL, 2=left SHIFT, 3=right SHIFT
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_getch:
        cmp _kbhit,0
        je _getch
        mov _kbhit,0
        mov ax,word ptr _kbchar
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Clear all kb stuff
; Out:
;   EAX,ECX,EDI - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_clearkb:
        mov edi,offset _kbtbl0
        xor eax,eax
        mov ecx,40h
        rep stosd
        mov _kbshift,0
        mov _kbhit,0
        ret

code32  ends
        end

