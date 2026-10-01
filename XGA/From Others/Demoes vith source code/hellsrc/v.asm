        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include decode0.inc
include file.inc
include flib.inc
include kb.inc
include gs.inc
include gsp669.inc

extrn   _p0:near, _p1:near, _p2:near, _p3:near

public	_vrtrout, _olomembase, _ohimembase, _vidbitloc, _vidbitloc2, _cpalptr
public  _sel, _vidptr0, _vidptr1, _vidptr2, _vidptr3, _clearpalptr

public  _main, _vrtset, _loaddata, _loadmuzik, _slidebytes, _setcpal

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
align 4
_vrtrout        dd      _ret
_olomembase     dd      ?               ; old low mem base
_ohimembase     dd      ?               ; old high mem base
_vidptr0        dd      ?               ; ptr to 0a0000h
_vidptr1        dd      ?               ; ptr to 0a4000h
_vidptr2        dd      ?               ; ptr to 0a8000h
_vidptr3        dd      ?               ; ptr to 0ac000h
_clearpalptr    dd      ?               ; ptr to 0c0h buffer of 0
_cpalptr        dd      ?               ; ptr to 300h buffer for current pal

_sel            dw      3 dup(?)        ; allocated selectors

_vidbitloc      db      1,2,4,8         ; bitplane masks for bit numbers
_vidbitloc2	db	11h,22h,44h,88h ; double bitplane masks

l8rmsg          db      'Have a nice life...$'
errmsg0         db      'Please rename this file back to HELL.EXE!!!$'
errmsg1         db      'Then you aint gonna see this demo...$'
errmsg2         db      'Could not find a GUS!!!$'
errmsg3         db      'You must have a GUS with at least 512k!!!$'

libfnm          db      'HELL.EXE',0

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

include modex.rt
include mode60.rt
include pbmodex.rt
include pdosmsg.rt
include psbm.rt
include slidebyt.rt

include vrtime.m
include end.m

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; Exit to DOS, In: EDX -> msg to put
exit:
        call _flcloselib                ; close library file
        call _resetvrt                  ; reset system timer
;-----------------------------------------------------------------------------
exit1:
        call _gsp669_uninit             ; reset GUS 669 player
;-----------------------------------------------------------------------------
exit0:
        call _resetkb                   ; reset keyboard handler
        mov v86r_ax,3                   ; text mode
        mov al,10h
        int 33h
        mov edx,ebp
        call _putdosmsg                 ; put message
        jmp _exit

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
_main:
        sti
        mov eax,1000h+300h+0c0h         ; allocate some buffers
        call _getlomem
        mov _filebufloc,eax
        mov _decode0ibufptr,eax
        add eax,1000h
        mov _cpalptr,eax
        add eax,300h
        mov _clearpalptr,eax
        mov edi,eax                     ; clear '_clearpalptr' buffer
        xor eax,eax
        mov ecx,0c0h/4
        rep stosd
        mov edi,offset _sel             ; allocate selectors
        mov ecx,3
mainl0:
        call _getselector
        stosw
        loop mainl0
        call _initkb                    ; init keyboard handler
        call _gs_find                   ; find and initialize a GUS
        jnc short mainf0
        call _gs_ask
        mov ebp,offset errmsg1
        jc exit0
mainf0:
        call _gsp669_init               ; init GUS 669 player
        cmp _gusram,2
        mov ebp,offset errmsg3
        jb exit1
        call _gs_test
        mov ebp,offset errmsg2
        jc exit0
        call _initvrt                   ; init timer for vertical retrace
        mov edx,offset libfnm           ; open library file
        call _flopenlib
        mov ebp,offset errmsg0
        jc exit
        call _mode60                    ; 60Hz tweaked mode
        call _vrtset

        mov eax,_lomembase              ; store memory base ptrs
        mov _olomembase,eax
        mov eax,_himembase
        mov _ohimembase,eax
        @rlp eax,0a0000h                ; set video ptrs
        mov _vidptr0,eax
        add eax,4000h
        mov _vidptr1,eax
        add eax,4000h
        mov _vidptr2,eax
        add eax,4000h
        mov _vidptr3,eax

;-----------------------------------------------------------------------------
        call _p0                        ; starting part, cross bursts into
                                        ;  flames, title screen, skull speaks,
                                        ;  penagram field transitions in
        call _p1                        ; interfering pentagrams on field,
                                        ;  b/w sinewave sum plasma, mirror
                                        ;  transitions in
;       call __crapinit
        call _p2                        ; warping faces in mirror, mirror
                                        ;  zooms out
;       call __crapinit
        call _p3                        ; rotating glass balls, bg falls away

;-----------------------------------------------------------------------------
        call _end                       ; put end piccy

        mov ebp,offset l8rmsg
        jmp exit

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Load compressed data into high memory and allocate it (also realign on 4)
; In:
;   EAX - token name of data
; Out:
;   EAX -> ptr to data
;   EDI - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_loaddata:
        call _flopenfile
        mov eax,offset _flreadfile
        mov edi,_himembase
        call _decode0
        call _gethimem
        movzx ebx,al
        dec bl
        and bl,3
        xor bl,3
        add _himembase,ebx
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Load muzik into low memory and allocate it
; In:
;   EAX - token name of muzik
; Out:
;   EAX -> ptr to data
;   EDX - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_loadmuzik:
        call _gsp669_stop
        call _flopenfile
        mov eax,offset _flreadfile
        mov edx,_olomembase
        mov _lomembase,edx
        call _gsp669_load
        jmp _getlomem

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set current palette and update '_cpalptr' buffer
; In:
;   AL - first color to set
;   ECX - number of colors to set
;   ESI -> RGB color data
; Out:
;   EAX,EBX,ECX,DX,ESI,EDI - ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_setcpal:
        movzx eax,al
        lea edi,[eax*2+eax]
        add edi,_cpalptr
        lea ecx,[ecx*2+ecx]
        mov ebx,ecx
        mov dx,3c8h
        out dx,al
        inc edx
        rep outsb
        sub esi,ebx
        mov ecx,ebx
        rep movsb
        ret



; The crap that follows is just code to enter the demo at different points.
; Used only when I was writing the demo, but might as well leave it in.

CRAP            = 0
extrn   ord:dword

if CRAP eq 1
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
skullsidepalptr dd      ?               ; skull column palette ptr
skullsidesprptr dd      ?               ; skull side column sprite ptr
trnsptr         dd      ?,?             ; transition video ptrs
trnscount       db      48              ; transition routine loop counter

;-----------------------------------------------------------------------------
p0ir1:
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
p0ir1r0:
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
__crapinit:
        mov eax,'p02d'
        call _loaddata
        add eax,24f0h
        mov skullsidesprptr,eax
        add eax,3200h
        mov skullsidepalptr,eax

        mov esi,skullsidepalptr
        mov ecx,20h
        mov al,40h
        call _setcpal
        mov esi,_clearpalptr
        mov ecx,40h
        xor al,al
        call _setcpal

        mov edi,_vidptr0
        mov esi,skullsidesprptr
        mov dx,3c5h
        mov bl,1
l0:
        @outb bl
        mov ecx,200
l1:
        mov eax,[esi]
        mov [edi],eax
        mov [edi+40h],eax
        mov eax,[esi+4]
        mov [edi+4],eax
        mov [edi+44h],eax
        mov eax,[esi+8]
        mov [edi+8],eax
        mov [edi+48h],eax
        mov eax,[esi+12]
        mov [edi+12],eax
        mov [edi+4ch],eax
        add esi,16
        add edi,80
        loop l1
        sub edi,80*200
        shl bl,1
        and bl,0fh
        jnz l0

        @outb 0fh
        mov dl,0ceh
        @outw 4105h

        mov eax,_vidptr0
        add eax,80*100
        mov trnsptr[0],eax
        add eax,79-80*100
        mov trnsptr[4],eax
        mov _vrtrout,offset p0ir1

        mov eax,_ohimembase
        mov _himembase,eax
        ret
endif

if CRAP eq 2
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
mirrorpal       db      0, 0, 0, 3, 1, 0, 7, 4, 1, 12, 7, 2, 16, 9, 3, 20
                db      12, 4, 24, 15, 5, 29, 17, 7, 33, 20, 8, 37, 23, 9, 41, 25
                db      10, 46, 28, 11, 50, 31, 12, 54, 33, 13, 58, 36, 14, 63, 39, 16
                db      6, 0, 12, 6, 0, 12, 6, 0, 12, 6, 0, 12, 6, 0, 12, 6
                db      0, 12, 6, 0, 12, 6, 0, 12, 0, 0, 6, 0, 0, 7, 0, 0
                db      8, 0, 0, 10, 0, 0, 11, 0, 0, 13, 0, 0, 14, 0, 0, 16
                db      17, 0, 26, 17, 0, 26, 17, 0, 26, 17, 0, 26, 17, 0, 26, 17
                db      0, 26, 17, 0, 26, 17, 0, 26

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
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

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
__crapinit:
        mov eax,'muz2'                  ; load up next muzik
        call _loadmuzik
        cli
        call _gsp669_play               ; start muzik playing
        mov ord,4
        sti

        mov edi,_vidptr2                ; clean up pages 2 and 3
        mov dx,3c5h
        @outb 0fh
        mov ecx,2000h
        xor eax,eax
        rep stosd

        mov edi,_cpalptr                ; set up b/w palette
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
        call _setcpal

        mov dx,3d4h                     ; set page 2
        @outw 800ch

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

        mov eax,_ohimembase             ; clean up high memory base ptr
        mov _himembase,eax
        mov _vrtrout,offset p1ir4       ; set transition retrace routine

        ret
endif

if CRAP eq 3
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
__crapinit:
        mov eax,'muz2'                  ; load up next muzik
        call _loadmuzik
        cli
        call _gsp669_play               ; start muzik playing
        mov ord,8
        sti

        mov eax,'p20d'                  ; load and allocate data
        call _loaddata
        mov ebp,eax

        lea esi,[ebp+97696]             ; put mirror pic to pages 0 and 1
        mov ebx,80*200
        mov edi,_vidptr0
        call _pbmodex
        mov edi,_vidptr1
        call _pbmodex

        lea esi,[ebp+209923]
        mov ecx,40h
        mov al,20h
        call _setcpal

        mov dx,3d4h                     ; set page 0
        @outw 0ch

        ret
endif


code32  ends
        end

